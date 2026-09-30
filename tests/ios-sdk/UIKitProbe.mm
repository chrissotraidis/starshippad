#import <UIKit/UIKit.h>

// UIKit -> UIColor -> CoreImage -> CoreVideo reproduces the player failure
// when a macOS framework search path leaks into an iOS compile.
UIColor* StarshipPadSDKProbe(void) { return UIColor.blackColor; }
