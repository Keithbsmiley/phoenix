#import <QuartzCore/QuartzCore.h>
#import "Alerts.h"

@protocol PHAlertHoraMortisNostraeDelegate <NSObject>

- (void)oraPro:(id)nobis;

@end

@interface PHAlertWindowController : NSWindowController

- (void)show:(NSString *)oneLineMsg duration:(CGFloat)duration pushDownBy:(CGFloat)adjustment;

@property (weak) id<PHAlertHoraMortisNostraeDelegate> delegate;

@end

@interface Alerts () <PHAlertHoraMortisNostraeDelegate>

@property NSMutableArray *visibleAlerts;

@end

@implementation Alerts

+ (Alerts *)sharedAlerts {
    static Alerts *sharedAlerts;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedAlerts = [[Alerts alloc] init];
    });
    return sharedAlerts;
}

- (id)init
{
    self = [super init];
    if (!self) {
        return nil;
    }

    self.alertDisappearDelay = 1.0;
    self.visibleAlerts = [NSMutableArray array];

    return self;
}

- (void)show:(NSString *)oneLineMsg {
    [self show:oneLineMsg duration:self.alertDisappearDelay];
}

- (void)show:(NSString *)oneLineMsg duration:(CGFloat)duration {
    CGFloat absoluteTop;

    NSScreen *currentScreen = [NSScreen mainScreen];

    if ([self.visibleAlerts count] == 0) {
        CGRect screenRect = [currentScreen frame];
        absoluteTop = screenRect.size.height / 1.55;
    } else {
        PHAlertWindowController *ctrl = [self.visibleAlerts lastObject];
        absoluteTop = NSMinY([[ctrl window] frame]) - 3.0;
    }

    if (absoluteTop <= 0) {
        absoluteTop = NSMaxY([currentScreen visibleFrame]);
    }

    PHAlertWindowController *alert = [[PHAlertWindowController alloc] init];
    alert.delegate = self;
    [alert show:oneLineMsg duration:duration pushDownBy:absoluteTop];
    [self.visibleAlerts addObject:alert];
}

- (void)oraPro:(id)nobis {
    [self.visibleAlerts removeObject:nobis];
}

@end

@interface PHAlertWindowController ()

@property (nonatomic) IBOutlet NSTextField *textField;
@property (nonatomic) IBOutlet NSBox *box;

@end

@implementation PHAlertWindowController

- (NSString *)windowNibName {
    return @"AlertWindow";
}

- (void)windowDidLoad {
    self.window.styleMask = NSBorderlessWindowMask;
    self.window.backgroundColor = [NSColor clearColor];
    self.window.opaque = NO;
    self.window.level = NSFloatingWindowLevel;
    self.window.ignoresMouseEvents = YES;
    if ([[Alerts sharedAlerts] alertAnimates]) {
        self.window.animationBehavior = NSWindowAnimationBehaviorAlertPanel;
    } else {
        self.window.animationBehavior = NSWindowAnimationBehaviorNone;
    }
//    self.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorStationary;
}

- (void)show:(NSString *)oneLineMsg duration:(CGFloat)duration pushDownBy:(CGFloat)adjustment {
    NSDisableScreenUpdates();

    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.01];
    [[[self window] animator] setAlphaValue:1.0];
    [NSAnimationContext endGrouping];

    [self useTitleAndResize:[oneLineMsg description]];
    [self setFrameWithAdjustment:adjustment];
    [self showWindow:self];
    [self performSelector:@selector(fadeWindowOut) withObject:nil afterDelay:duration];

    NSEnableScreenUpdates();
}

- (void)setFrameWithAdjustment:(CGFloat)pushDownBy {
    NSScreen *currentScreen = [NSScreen mainScreen];
    CGRect screenRect = [currentScreen frame];
    CGRect winRect = [[self window] frame];

    winRect.origin.x = (screenRect.size.width / 2.0) - (winRect.size.width / 2.0);
    winRect.origin.y = pushDownBy - winRect.size.height;

    [self.window setFrame:winRect display:NO];
}

- (void)fadeWindowOut {
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.15];
    [[[self window] animator] setAlphaValue:0.0];
    [NSAnimationContext endGrouping];

    [self performSelector:@selector(closeAndResetWindow) withObject:nil afterDelay:0.15];
}

- (void)closeAndResetWindow {
    [[self window] orderOut:nil];
    [[self window] setAlphaValue:1.0];

    [self.delegate oraPro:self];
}

- (void)useTitleAndResize:(NSString *)title {
    [self window]; // sigh; required in case nib hasnt loaded yet

    self.textField.stringValue = title;
    [self.textField sizeToFit];

	NSRect windowFrame = [[self window] frame];
	windowFrame.size.width = [self.textField frame].size.width + 32.0;
	windowFrame.size.height = [self.textField frame].size.height + 24.0;
	[[self window] setFrame:windowFrame display:YES];
}

@end
