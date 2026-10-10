#ifndef FRAMECOUNTER_H
#define FRAMECOUNTER_H

#include <stdbool.h>
#include <stdint.h>

/// Game side: call once per rendered frame.
void frame_counter_tick(void);

/// Redline side: total frames counted by the hooked game so far.
/// Returns false when no hooked game is running.
bool frame_counter_read(uint64_t *frames);

#endif
