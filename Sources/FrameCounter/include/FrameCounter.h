#ifndef FRAMECOUNTER_H
#define FRAMECOUNTER_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

/// Game side: call once per rendered frame.
void frame_counter_tick(void);

/// Redline side: total frames counted by the hooked game so far.
/// Returns false when no hooked game is running.
bool frame_counter_read(uint64_t *frames);

/// Redline side: timestamps (nanoseconds, CLOCK_UPTIME_RAW) of frames numbered after `afterFrame`,
/// oldest first. If there are more than `capacity`, only the newest are copied.
/// `newestFrame` receives the number of the last frame copied. Returns how many were copied.
size_t frame_counter_copy_times(uint64_t afterFrame, uint64_t *times, size_t capacity, uint64_t *newestFrame);

#endif
