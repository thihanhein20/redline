#include "Sensors.h"

#include <IOKit/IOKitLib.h>
#include <math.h>
#include <string.h>

// AppleSMC user-client protocol (same layout used by iStat Menus, Stats, smcFanControl).
typedef struct { char major, minor, build, reserved; unsigned short release; } SMCVersion;
typedef struct { unsigned short version, length; unsigned int cpuPLimit, gpuPLimit, memPLimit; } SMCPowerLimit;
typedef struct { unsigned int dataSize, dataType; char dataAttributes; } SMCKeyInfo;
typedef struct {
    unsigned int key;
    SMCVersion version;
    SMCPowerLimit powerLimit;
    SMCKeyInfo keyInfo;
    char result, status, command;
    unsigned int index;
    unsigned char bytes[32];
} SMCParam;

enum { kSMCReadBytes = 5, kSMCKeyAtIndex = 8, kSMCKeyInfo = 9, kMaxKeysPerPrefix = 64 };

static io_connect_t connection(void) {
    static io_connect_t smc = 0;
    if (smc == 0) {
        io_service_t service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"));
        IOServiceOpen(service, mach_task_self(), 0, &smc);
        IOObjectRelease(service);
    }
    return smc;
}

static bool call(SMCParam *input, SMCParam *output) {
    size_t size = sizeof(SMCParam);
    return IOConnectCallStructMethod(connection(), 2, input, sizeof(SMCParam), output, &size) == kIOReturnSuccess;
}

static unsigned int fourCC(const char *s) { return (s[0] << 24) | (s[1] << 16) | (s[2] << 8) | s[3]; }

static bool key_info(unsigned int key, SMCKeyInfo *info) {
    SMCParam in = { .key = key, .command = kSMCKeyInfo }, out = {0};
    if (!call(&in, &out)) return false;
    *info = out.keyInfo;
    return true;
}

static double read_float(unsigned int key, SMCKeyInfo info) {
    SMCParam in = { .key = key, .keyInfo = info, .command = kSMCReadBytes }, out = {0};
    if (!call(&in, &out)) return NAN;
    float value;
    memcpy(&value, out.bytes, sizeof value);
    return value;
}

/// Float temperature keys starting with `prefix`. Scanning all ~1600 keys is slow, so it runs once per prefix.
static int keys_for(const char *prefix, unsigned int *keys) {
    unsigned int count = 0;
    SMCKeyInfo info;
    if (key_info(fourCC("#KEY"), &info)) {
        SMCParam in = { .key = fourCC("#KEY"), .keyInfo = info, .command = kSMCReadBytes }, out = {0};
        if (call(&in, &out)) count = (out.bytes[0] << 24) | (out.bytes[1] << 16) | (out.bytes[2] << 8) | out.bytes[3];
    }
    int found = 0;
    for (unsigned int i = 0; i < count && found < kMaxKeysPerPrefix; i++) {
        SMCParam in = { .index = i, .command = kSMCKeyAtIndex }, out = {0};
        if (!call(&in, &out)) continue;
        char name[4] = { out.key >> 24, out.key >> 16, out.key >> 8, out.key };
        if (strncmp(name, prefix, strlen(prefix)) != 0) continue;
        if (key_info(out.key, &info) && info.dataType == fourCC("flt ")) keys[found++] = out.key;
    }
    return found;
}

double smc_max_temperature(const char *prefix) {
    // ponytail: cache sized for the two prefixes Redline uses (CPU, GPU).
    static struct { char prefix[4]; unsigned int keys[kMaxKeysPerPrefix]; int count; } cache[4];
    static int cached = 0;

    int slot = -1;
    for (int i = 0; i < cached; i++) if (strcmp(cache[i].prefix, prefix) == 0) slot = i;
    if (slot < 0) {
        if (cached == 4 || strlen(prefix) > 3) return NAN;
        slot = cached++;
        strcpy(cache[slot].prefix, prefix);
        cache[slot].count = keys_for(prefix, cache[slot].keys);
    }

    double hottest = NAN;
    for (int i = 0; i < cache[slot].count; i++) {
        SMCKeyInfo info;
        if (!key_info(cache[slot].keys[i], &info)) continue;
        double celsius = read_float(cache[slot].keys[i], info);
        // Unused sensors report 0 or garbage; keep plausible chip temperatures only.
        if (celsius > 5 && celsius < 130 && (isnan(hottest) || celsius > hottest)) hottest = celsius;
    }
    return hottest;
}
