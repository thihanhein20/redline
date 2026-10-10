// Loaded into the game via DYLD_INSERT_LIBRARIES.
// Counts one frame every time the game asks its CAMetalLayer for a new drawable,
// which Metal games (including Unity) do exactly once per rendered frame.

#import <QuartzCore/CAMetalLayer.h>
#import <objc/runtime.h>
#import <stdlib.h>

#import "FrameCounter.h"

static id (*originalNextDrawable)(id, SEL);

static id countingNextDrawable(id self, SEL _cmd) {
    frame_counter_tick();
    return originalNextDrawable(self, _cmd);
}

__attribute__((constructor))
static void installHook(void) {
    // Keep the hook out of any helper processes the game spawns.
    unsetenv("DYLD_INSERT_LIBRARIES");

    Method method = class_getInstanceMethod([CAMetalLayer class], @selector(nextDrawable));
    originalNextDrawable = (id (*)(id, SEL))method_setImplementation(method, (IMP)countingNextDrawable);
}
