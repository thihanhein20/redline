#include "Sensors.h"

#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <math.h>
#include <string.h>
#include <time.h>

// Private IOReport API (libIOReport.dylib), as used by Stats, macmon and powermetrics.
typedef struct IOReportSubscription *IOReportSubscriptionRef;
CFDictionaryRef IOReportCopyChannelsInGroup(CFStringRef, CFStringRef, uint64_t, uint64_t, uint64_t);
void IOReportMergeChannels(CFDictionaryRef, CFDictionaryRef, CFTypeRef);
IOReportSubscriptionRef IOReportCreateSubscription(void *, CFMutableDictionaryRef, CFMutableDictionaryRef *, uint64_t, CFTypeRef);
CFDictionaryRef IOReportCreateSamples(IOReportSubscriptionRef, CFMutableDictionaryRef, CFTypeRef);
CFDictionaryRef IOReportCreateSamplesDelta(CFDictionaryRef, CFDictionaryRef, CFTypeRef);
int64_t IOReportSimpleGetIntegerValue(CFDictionaryRef, int32_t);
CFStringRef IOReportChannelGetChannelName(CFDictionaryRef);
CFStringRef IOReportChannelGetUnitLabel(CFDictionaryRef);
int32_t IOReportStateGetCount(CFDictionaryRef);
CFStringRef IOReportStateGetNameForIndex(CFDictionaryRef, int32_t);
int64_t IOReportStateGetResidency(CFDictionaryRef, int32_t);

enum { kMaxStates = 32 };
typedef struct { double mhz[kMaxStates]; int count; } FrequencyTable;

static IOReportSubscriptionRef subscription;
static CFMutableDictionaryRef channels;
static CFDictionaryRef previous;
static double previousTime;
static FrequencyTable eCores, pCores, gpu;

static double now(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + t.tv_nsec / 1e9;
}

/// DVFS table from the power manager: little-endian (Hz, voltage) pairs.
static FrequencyTable frequency_table(const char *property) {
    FrequencyTable table = {0};
    io_service_t pmgr = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceNameMatching("pmgr"));
    CFStringRef key = CFStringCreateWithCString(NULL, property, kCFStringEncodingUTF8);
    CFDataRef data = IORegistryEntryCreateCFProperty(pmgr, key, NULL, 0);
    if (data) {
        const uint8_t *bytes = CFDataGetBytePtr(data);
        for (CFIndex i = 0; i + 8 <= CFDataGetLength(data) && table.count < kMaxStates; i += 8) {
            uint32_t hz = bytes[i] | bytes[i + 1] << 8 | bytes[i + 2] << 16 | (uint32_t)bytes[i + 3] << 24;
            table.mhz[table.count++] = hz / 1e6;
        }
        CFRelease(data);
    }
    CFRelease(key);
    IOObjectRelease(pmgr);
    return table;
}

static void start(void) {
    CFDictionaryRef energy = IOReportCopyChannelsInGroup(CFSTR("Energy Model"), NULL, 0, 0, 0);
    CFDictionaryRef cpu = IOReportCopyChannelsInGroup(CFSTR("CPU Stats"), CFSTR("CPU Complex Performance States"), 0, 0, 0);
    CFDictionaryRef gpuStates = IOReportCopyChannelsInGroup(CFSTR("GPU Stats"), CFSTR("GPU Performance States"), 0, 0, 0);
    if (!energy) return;
    if (cpu) { IOReportMergeChannels(energy, cpu, NULL); CFRelease(cpu); }
    if (gpuStates) { IOReportMergeChannels(energy, gpuStates, NULL); CFRelease(gpuStates); }
    CFMutableDictionaryRef wanted = CFDictionaryCreateMutableCopy(NULL, 0, energy);
    CFRelease(energy);
    subscription = IOReportCreateSubscription(NULL, wanted, &channels, 0, NULL);
    CFRelease(wanted);
    // ponytail: table names match M1/M2 (as in macmon); other chips just report NAN clocks.
    eCores = frequency_table("voltage-states1-sram");
    pCores = frequency_table("voltage-states5-sram");
    gpu = frequency_table("voltage-states9");
}

static bool named(CFDictionaryRef channel, CFStringRef name) {
    CFStringRef channelName = IOReportChannelGetChannelName(channel);
    return channelName && CFStringCompare(channelName, name, 0) == kCFCompareEqualTo;
}

static double joules(CFDictionaryRef channel) {
    double value = (double)IOReportSimpleGetIntegerValue(channel, 0);
    CFStringRef unit = IOReportChannelGetUnitLabel(channel);
    if (unit && CFStringCompare(unit, CFSTR("nJ"), 0) == kCFCompareEqualTo) return value / 1e9;
    if (unit && CFStringCompare(unit, CFSTR("uJ"), 0) == kCFCompareEqualTo) return value / 1e6;
    return value / 1e3;  // mJ
}

/// Residency-weighted average clock over active states (skips IDLE/OFF/DOWN).
static double average_mhz(CFDictionaryRef channel, const FrequencyTable *table) {
    double weighted = 0, total = 0;
    int active = 0;
    for (int32_t i = 0; i < IOReportStateGetCount(channel); i++) {
        char name[32] = {0};
        CFStringGetCString(IOReportStateGetNameForIndex(channel, i), name, sizeof name, kCFStringEncodingUTF8);
        if (!strcmp(name, "IDLE") || !strcmp(name, "OFF") || !strcmp(name, "DOWN")) continue;
        double residency = (double)IOReportStateGetResidency(channel, i);
        // GPU tables start with a 0 MHz "off" entry that the state list skips.
        int index = active + (table == &gpu ? 1 : 0);
        active++;
        // Some chips list more states than their table has; those are never used.
        if (index >= table->count) {
            if (residency > 0) return NAN;
            continue;
        }
        weighted += residency * table->mhz[index];
        total += residency;
    }
    return total > 0 ? weighted / total : NAN;
}

SoCSample soc_sample(void) {
    SoCSample result = { .valid = false, .cpuWatts = NAN, .gpuWatts = NAN, .totalWatts = NAN,
                         .eCoreMHz = NAN, .pCoreMHz = NAN, .gpuMHz = NAN };
    if (!subscription) start();
    if (!subscription) return result;

    CFDictionaryRef current = IOReportCreateSamples(subscription, channels, NULL);
    double time = now(), seconds = time - previousTime;
    if (previous && current && seconds > 0) {
        CFDictionaryRef delta = IOReportCreateSamplesDelta(previous, current, NULL);
        CFArrayRef items = delta ? CFDictionaryGetValue(delta, CFSTR("IOReportChannels")) : NULL;
        // NAN until the channel is actually seen: a chip without it shows "unavailable", never 0 W.
        double cpu = NAN, gpuEnergy = NAN, other = 0;
        for (CFIndex i = 0; items && i < CFArrayGetCount(items); i++) {
            CFDictionaryRef channel = CFArrayGetValueAtIndex(items, i);
            if (named(channel, CFSTR("CPU Energy"))) cpu = joules(channel);
            else if (named(channel, CFSTR("GPU Energy"))) gpuEnergy = joules(channel);
            else if (named(channel, CFSTR("DRAM")) || named(channel, CFSTR("ANE"))) other += joules(channel);
            else if (named(channel, CFSTR("ECPU")) && IOReportStateGetCount(channel) > 0) result.eCoreMHz = average_mhz(channel, &eCores);
            else if (named(channel, CFSTR("PCPU")) && IOReportStateGetCount(channel) > 0) result.pCoreMHz = average_mhz(channel, &pCores);
            else if (named(channel, CFSTR("GPUPH"))) result.gpuMHz = average_mhz(channel, &gpu);
        }
        result.valid = items != NULL;
        result.cpuWatts = cpu / seconds;
        result.gpuWatts = gpuEnergy / seconds;
        result.totalWatts = (cpu + gpuEnergy + other) / seconds;  // NAN if CPU or GPU is missing
        if (delta) CFRelease(delta);
    }
    if (previous) CFRelease(previous);
    previous = current;
    previousTime = time;
    return result;
}
