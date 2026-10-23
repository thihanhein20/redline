// Loaded into the game via DYLD_INSERT_LIBRARIES.
// Counts one frame each time the game gets a new drawable from a CAMetalLayer, which Metal games
// (including Unity) do once per frame they render. Requests that come back empty (timeouts) aren't counted.
// Limit: a game drawing to several Metal layers counts frames from all of them.

#import <QuartzCore/CAMetalLayer.h>
#import <objc/runtime.h>
#import <stdlib.h>

#import "FrameCounter.h"

static id (*originalNextDrawable)(id, SEL);

static id countingNextDrawable(id self, SEL _cmd) {
    id drawable = originalNextDrawable(self, _cmd);
    if (drawable) frame_counter_tick();
    return drawable;
}

__attribute__((constructor))
static void installHook(void) {
    // Keep the hook out of any helper processes the game spawns.
    unsetenv("DYLD_INSERT_LIBRARIES");

    Method method = class_getInstanceMethod([CAMetalLayer class], @selector(nextDrawable));
    originalNextDrawable = (id (*)(id, SEL))method_setImplementation(method, (IMP)countingNextDrawable);
}
