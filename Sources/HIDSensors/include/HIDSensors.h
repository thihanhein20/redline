#ifndef HIDSENSORS_H
#define HIDSENSORS_H

/// Highest reading (°C) among temperature sensors whose name contains `nameFilter`.
/// Returns NAN when no matching sensor reports a valid value.
double hid_max_temperature(const char *nameFilter);

#endif
