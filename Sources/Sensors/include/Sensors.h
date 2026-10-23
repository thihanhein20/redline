#ifndef SENSORS_H
#define SENSORS_H

#include <stdbool.h>

// Small, safe wrappers around Apple Silicon's private sensor APIs. Unavailable readings are NAN.

/// Highest reading (°C) among HID temperature sensors whose name contains `nameFilter` (e.g. "tdie").
double hid_max_temperature(const char *nameFilter);

/// Highest reading (°C) among SMC temperature keys starting with `prefix` ("Tp" = CPU cores, "Tg" = GPU).
double smc_max_temperature(const char *prefix);

/// Chip power and average clock speeds over one sampling interval (IOReport).
typedef struct {
    bool valid;          ///< false on the first call, which only starts measuring
    double cpuWatts;
    double gpuWatts;
    double totalWatts;   ///< CPU + GPU + DRAM + Neural Engine
    double eCoreMHz;     ///< average clock of active efficiency cores
    double pCoreMHz;     ///< average clock of active performance cores
    double gpuMHz;       ///< average clock while the GPU is active
} SoCSample;

/// Power and clocks since the previous call.
SoCSample soc_sample(void);

#endif
