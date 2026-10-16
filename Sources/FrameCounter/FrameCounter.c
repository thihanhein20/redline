#include "FrameCounter.h"

#include <fcntl.h>
#include <signal.h>
#include <stdatomic.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

// ponytail: one shared slot, so only one hooked game at a time; key by pid for more.
// Versioned name: macOS can't resize an existing shared memory object, so a new layout needs a new name.
static const char *kSharedName = "/redline.frames.v2";

enum { kTimeSlots = 1024 };  // ~17 s of frame times at 60 FPS
// Frames the reader leaves alone at the old end of the ring, in case the game is overwriting them.
enum { kSafetyMargin = 64 };

typedef struct {
    _Atomic uint64_t frames;
    _Atomic int32_t pid;
    uint64_t times[kTimeSlots];  // times[n % kTimeSlots] = when frame n was drawn
} SharedFrames;

static SharedFrames *map_shared(int openFlags, int protection) {
    int fd = shm_open(kSharedName, openFlags, 0600);
    if (fd < 0) return NULL;

    struct stat info;
    if (fstat(fd, &info) != 0) goto fail;
    // macOS allows sizing a shared memory object only once, so size it only when new.
    if (info.st_size == 0 && (openFlags & O_CREAT)) {
        if (ftruncate(fd, sizeof(SharedFrames)) != 0) goto fail;
        info.st_size = sizeof(SharedFrames);
    }
    if (info.st_size < (off_t)sizeof(SharedFrames)) goto fail;

    void *memory = mmap(NULL, sizeof(SharedFrames), protection, MAP_SHARED, fd, 0);
    close(fd);
    return memory == MAP_FAILED ? NULL : memory;

fail:
    close(fd);
    return NULL;
}

void frame_counter_tick(void) {
    static SharedFrames *shared = NULL;
    if (shared == NULL) {
        // Mapped lazily on the first frame, so only processes that render claim the slot.
        shared = map_shared(O_CREAT | O_RDWR, PROT_READ | PROT_WRITE);
        if (shared == NULL) return;
        atomic_store(&shared->frames, 0);
        atomic_store(&shared->pid, getpid());
    }
    uint64_t frame = atomic_load_explicit(&shared->frames, memory_order_relaxed);
    shared->times[frame % kTimeSlots] = clock_gettime_nsec_np(CLOCK_UPTIME_RAW);
    atomic_store_explicit(&shared->frames, frame + 1, memory_order_release);
}

/// Read-only mapping, or NULL when no hooked game is running.
static SharedFrames *live_reader(void) {
    static SharedFrames *shared = NULL;
    if (shared == NULL) shared = map_shared(O_RDONLY, PROT_READ);
    if (shared == NULL) return NULL;
    int32_t pid = atomic_load(&shared->pid);
    return (pid > 0 && kill(pid, 0) == 0) ? shared : NULL;  // NULL once the game has exited
}

bool frame_counter_read(uint64_t *frames) {
    SharedFrames *shared = live_reader();
    if (shared == NULL) return false;
    *frames = atomic_load_explicit(&shared->frames, memory_order_acquire);
    return true;
}

size_t frame_counter_copy_times(uint64_t afterFrame, uint64_t *times, size_t capacity, uint64_t *newestFrame) {
    SharedFrames *shared = live_reader();
    if (shared == NULL || capacity == 0) return 0;

    // Frame n is the n-th frame (1-based); its time sits at times[(n - 1) % kTimeSlots].
    uint64_t newest = atomic_load_explicit(&shared->frames, memory_order_acquire);
    uint64_t oldestKept = newest > kTimeSlots - kSafetyMargin ? newest - (kTimeSlots - kSafetyMargin) : 0;
    uint64_t first = afterFrame > oldestKept ? afterFrame : oldestKept;
    if (newest > first + capacity) first = newest - capacity;

    size_t count = 0;
    for (uint64_t frame = first + 1; frame <= newest; frame++) times[count++] = shared->times[(frame - 1) % kTimeSlots];
    *newestFrame = newest;
    return count;
}
