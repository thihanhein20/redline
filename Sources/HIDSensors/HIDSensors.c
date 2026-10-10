#include "HIDSensors.h"

#include <CoreFoundation/CoreFoundation.h>
#include <math.h>
#include <string.h>

// Private IOKit HID API (no public header). Same approach as the open-source Stats app.
typedef struct __IOHIDEventSystemClient *IOHIDEventSystemClientRef;
typedef struct __IOHIDServiceClient *IOHIDServiceClientRef;
typedef struct __IOHIDEvent *IOHIDEventRef;

IOHIDEventSystemClientRef IOHIDEventSystemClientCreate(CFAllocatorRef allocator);
int IOHIDEventSystemClientSetMatching(IOHIDEventSystemClientRef client, CFDictionaryRef matching);
CFArrayRef IOHIDEventSystemClientCopyServices(IOHIDEventSystemClientRef client);
CFTypeRef IOHIDServiceClientCopyProperty(IOHIDServiceClientRef service, CFStringRef key);
IOHIDEventRef IOHIDServiceClientCopyEvent(IOHIDServiceClientRef service, int64_t type, int32_t options, int64_t timestamp);
double IOHIDEventGetFloatValue(IOHIDEventRef event, int32_t field);

enum {
    kTemperatureUsagePage = 0xff00,
    kTemperatureUsage = 5,
    kEventTypeTemperature = 15,
    kTemperatureField = kEventTypeTemperature << 16,
};

static CFDictionaryRef temperature_matching(void) {
    int page = kTemperatureUsagePage, usage = kTemperatureUsage;
    CFNumberRef pageNumber = CFNumberCreate(NULL, kCFNumberIntType, &page);
    CFNumberRef usageNumber = CFNumberCreate(NULL, kCFNumberIntType, &usage);
    const void *keys[] = { CFSTR("PrimaryUsagePage"), CFSTR("PrimaryUsage") };
    const void *values[] = { pageNumber, usageNumber };
    CFDictionaryRef matching = CFDictionaryCreate(NULL, keys, values, 2,
        &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFRelease(pageNumber);
    CFRelease(usageNumber);
    return matching;
}

static IOHIDEventSystemClientRef shared_client(void) {
    static IOHIDEventSystemClientRef client = NULL;
    if (client == NULL) {
        client = IOHIDEventSystemClientCreate(kCFAllocatorDefault);
        CFDictionaryRef matching = temperature_matching();
        IOHIDEventSystemClientSetMatching(client, matching);
        CFRelease(matching);
    }
    return client;
}

static int name_matches(IOHIDServiceClientRef service, const char *filter) {
    CFStringRef name = IOHIDServiceClientCopyProperty(service, CFSTR("Product"));
    if (name == NULL) return 0;
    char buffer[128] = {0};
    CFStringGetCString(name, buffer, sizeof buffer, kCFStringEncodingUTF8);
    CFRelease(name);
    return strstr(buffer, filter) != NULL;
}

static double read_temperature(IOHIDServiceClientRef service) {
    IOHIDEventRef event = IOHIDServiceClientCopyEvent(service, kEventTypeTemperature, 0, 0);
    if (event == NULL) return NAN;
    double celsius = IOHIDEventGetFloatValue(event, kTemperatureField);
    CFRelease(event);
    return celsius;
}

double hid_max_temperature(const char *nameFilter) {
    CFArrayRef services = IOHIDEventSystemClientCopyServices(shared_client());
    if (services == NULL) return NAN;

    double hottest = NAN;
    for (CFIndex i = 0; i < CFArrayGetCount(services); i++) {
        IOHIDServiceClientRef service = (IOHIDServiceClientRef)CFArrayGetValueAtIndex(services, i);
        if (!name_matches(service, nameFilter)) continue;
        double celsius = read_temperature(service);
        // Idle/unused sensors report <= 0 (e.g. -1.5); skip them.
        if (celsius > 0 && (isnan(hottest) || celsius > hottest)) hottest = celsius;
    }
    CFRelease(services);
    return hottest;
}
