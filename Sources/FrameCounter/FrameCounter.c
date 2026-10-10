#include "FrameCounter.h"

#include <fcntl.h>
#include <signal.h>
#include <stdatomic.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

// ponytail: one shared slot, so only one hooked game at a time; key by pid for more.
static const char *kSharedName = "/redline.frames";

typedef struct {
    _Atomic uint64_t frames;
    _Atomic int32_t pid;
} SharedFrames;

static SharedFrames *map_shared(int openFlags, int protection) {
    int fd = shm_open(kSharedName, openFlags, 0600);
    if (fd < 0) return NULL;

    struct stat info;
    if ((openFlags & O_CREAT) && ftruncate(fd, sizeof(SharedFrames)) != 0) goto fail;
    if (fstat(fd, &info) != 0 || info.st_size < (off_t)sizeof(SharedFrames)) goto fail;

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
    atomic_fetch_add_explicit(&shared->frames, 1, memory_order_relaxed);
}

bool frame_counter_read(uint64_t *frames) {
    static SharedFrames *shared = NULL;
    if (shared == NULL) shared = map_shared(O_RDONLY, PROT_READ);
    if (shared == NULL) return false;

    int32_t pid = atomic_load(&shared->pid);
    if (pid <= 0 || kill(pid, 0) != 0) return false;  // game has exited

    *frames = atomic_load_explicit(&shared->frames, memory_order_relaxed);
    return true;
}
