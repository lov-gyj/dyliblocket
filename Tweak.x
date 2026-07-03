#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "LocketNotifyView.h"

// ============================================================
// MARK: - Các macro màu sắc & style
// ============================================================
#define CREDIT_NAME         @"younj_icloud"
#define ZALO_PHONE          @"0981309921"
#define TELEGRAM_USER       @"younj_icloud"

// ============================================================
// MARK: - LocketNotifyView Implementation
// ============================================================
@interface LocketNotifyView ()
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) CAGradientLayer *borderGradient;
@property (nonatomic, strong) CAShapeLayer *borderShape;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *creditLabel;
@property (nonatomic, strong) UIButton *zaloButton;
@property (nonatomic, strong) UIButton *telegramButton;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) CAEmitterLayer *particleEmitter;
@property (nonatomic, strong) NSMutableArray<UIView *> *floatingDots;
@end

@implementation LocketNotifyView

static LocketNotifyView *_sharedInstance = nil;

// MARK: - Singleton Show
+ (void)show {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_sharedInstance) {
            [_sharedInstance removeFromSuperview];
            _sharedInstance = nil;
        }
        _sharedInstance = [[LocketNotifyView alloc] initWithFrame:UIScreen.mainScreen.bounds];
        UIWindow *keyWindow = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    for (UIWindow *window in scene.windows) {
                        if (window.isKeyWindow) {
                            keyWindow = window;
                            break;
                        }
                    }
                }
            }
        }
        if (!keyWindow) {
            keyWindow = [UIApplication sharedApplication].keyWindow;
        }
        [keyWindow addSubview:_sharedInstance];
        [_sharedInstance animateIn];
    });
}

+ (void)dismiss {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_sharedInstance animateOut];
    });
}

// MARK: - Init
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.floatingDots = [NSMutableArray array];
        [self setupViews];
        [self startFloatingDotsAnimation];
    }
    return self;
}

- (void)setupViews {
    // --- Background blur + dim ---
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurView.frame = self.bounds;
    blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:blurView];

    UIView *dimView = [[UIView alloc] initWithFrame:self.bounds];
    dimView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.35];
    dimView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:dimView];
    self.backgroundView = dimView;

    // Tap background to dismiss
    UITapGestureRecognizer *tapBg = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissTapped)];
    [self.backgroundView addGestureRecognizer:tapBg];

    // --- Card Container ---
    CGFloat cardWidth = MIN(self.bounds.size.width - 60, 320);
    CGFloat cardHeight = 420;
    self.cardView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cardWidth, cardHeight)];
    self.cardView.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    self.cardView.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.12 alpha:1.0];
    self.cardView.layer.cornerRadius = 28;
    self.cardView.layer.cornerCurve = kCACornerCurveContinuous;
    self.cardView.clipsToBounds = YES;
    [self addSubview:self.cardView];

    // Gradient Border
    self.borderGradient = [CAGradientLayer layer];
    self.borderGradient.frame = CGRectMake(-4, -4, cardWidth + 8, cardHeight + 8);
    self.borderGradient.colors = @[
        (id)[UIColor colorWithRed:1.0 green:0.3 blue:0.5 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.4 green:0.2 blue:1.0 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.0 green:0.7 blue:1.0 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:1.0 green:0.3 blue:0.5 alpha:1.0].CGColor
    ];
    self.borderGradient.locations = @[@0.0, @0.33, @0.66, @1.0];
    self.borderGradient.startPoint = CGPointMake(0, 0);
    self.borderGradient.endPoint = CGPointMake(1, 1);
    self.borderGradient.cornerRadius = 32;
    self.borderGradient.masksToBounds = YES;

    self.borderShape = [CAShapeLayer layer];
    UIBezierPath *borderPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(4, 4, cardWidth, cardHeight) cornerRadius:28];
    self.borderShape.path = borderPath.CGPath;
    self.borderShape.fillColor = [UIColor clearColor].CGColor;
    self.borderShape.strokeColor = [UIColor whiteColor].CGColor;
    self.borderShape.lineWidth = 3;
    self.borderGradient.mask = self.borderShape;

    [self.cardView.superview.layer insertSublayer:self.borderGradient below:self.cardView];

    // Inner gradient background on card
    CAGradientLayer *innerGradient = [CAGradientLayer layer];
    innerGradient.frame = CGRectMake(0, 0, cardWidth, cardHeight);
    innerGradient.colors = @[
        (id)[UIColor colorWithRed:0.12 green:0.10 blue:0.18 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.06 green:0.06 blue:0.10 alpha:1.0].CGColor
    ];
    innerGradient.locations = @[@0.0, @1.0];
    innerGradient.cornerRadius = 28;
    [self.cardView.layer insertSublayer:innerGradient atIndex:0];

    // --- Glow effect (shadow) ---
    self.cardView.layer.shadowColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.6 alpha:1.0].CGColor;
    self.cardView.layer.shadowOffset = CGSizeMake(0, 0);
    self.cardView.layer.shadowRadius = 30;
    self.cardView.layer.shadowOpacity = 0.7;
    self.cardView.layer.masksToBounds = NO;
    self.cardView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.cardView.bounds cornerRadius:28].CGPath;

    // --- Floating particles on card surface (decorative) ---
    for (int i = 0; i < 15; i++) {
        UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 4 + arc4random_uniform(6), 4 + arc4random_uniform(6))];
        dot.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.4 + (arc4random_uniform(40) / 100.0)];
        dot.layer.cornerRadius = dot.frame.size.width / 2;
        dot.center = CGPointMake(arc4random_uniform((int)cardWidth), arc4random_uniform((int)cardHeight));
        dot.alpha = 0;
        [self.cardView addSubview:dot];
        [self.floatingDots addObject:dot];
    }

    // --- Icon ---
    self.iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 70, 70)];
    self.iconImageView.center = CGPointMake(cardWidth / 2, 55);
    self.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    // Sử dụng SF Symbol hoặc emoji render
    UILabel *emojiLabel = [[UILabel alloc] initWithFrame:self.iconImageView.bounds];
    emojiLabel.text = @"📸";
    emojiLabel.font = [UIFont systemFontOfSize:50];
    emojiLabel.textAlignment = NSTextAlignmentCenter;
    [self.iconImageView addSubview:emojiLabel];
    [self.cardView addSubview:self.iconImageView];

    // --- Title ---
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 100, cardWidth - 40, 36)];
    self.titleLabel.text = @"✨ Chào mừng đến Locket ✨";
    self.titleLabel.font = [UIFont boldSystemFontOfSize:22];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.cardView addSubview:self.titleLabel];

    // --- Subtitle ---
    self.subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 140, cardWidth - 40, 20)];
    self.subtitleLabel.text = @"Khoảnh khắc hôm nay thật đẹp!";
    self.subtitleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.subtitleLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
    [self.cardView addSubview:self.subtitleLabel];

    // --- Divider line ---
    UIView *divider = [[UIView alloc] initWithFrame:CGRectMake(30, 175, cardWidth - 60, 1)];
    divider.backgroundColor = [UIColor colorWithWhite:0.25 alpha:1.0];
    divider.layer.cornerRadius = 0.5;
    [self.cardView addSubview:divider];

    // --- Credit Label ---
    self.creditLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 190, cardWidth - 40, 50)];
    NSString *creditText = [NSString stringWithFormat:@"Made by %@", CREDIT_NAME];
    NSMutableAttributedString *attrCredit = [[NSMutableAttributedString alloc] initWithString:creditText];
    [attrCredit addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:0.6 alpha:1.0] range:NSMakeRange(0, 8)];
    [attrCredit addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:13 weight:UIFontWeightRegular] range:NSMakeRange(0, 8)];
    [attrCredit addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:1.0 green:0.45 blue:0.6 alpha:1.0] range:NSMakeRange(8, creditText.length - 8)];
    [attrCredit addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:15] range:NSMakeRange(8, creditText.length - 8)];
    self.creditLabel.attributedText = attrCredit;
    self.creditLabel.textAlignment = NSTextAlignmentCenter;
    self.creditLabel.numberOfLines = 2;
    [self.cardView addSubview:self.creditLabel];

    // --- Zalo Button ---
    self.zaloButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.zaloButton.frame = CGRectMake(30, 255, cardWidth - 60, 50);
    [self.zaloButton setTitle:[NSString stringWithFormat:@"💬 Zalo: %@", ZALO_PHONE] forState:UIControlStateNormal];
    self.zaloButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    [self.zaloButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.zaloButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.55 blue:0.95 alpha:1.0];
    self.zaloButton.layer.cornerRadius = 25;
    self.zaloButton.layer.cornerCurve = kCACornerCurveContinuous;
    self.zaloButton.layer.shadowColor = [UIColor colorWithRed:0.0 green:0.55 blue:0.95 alpha:0.6].CGColor;
    self.zaloButton.layer.shadowOffset = CGSizeMake(0, 4);
    self.zaloButton.layer.shadowRadius = 12;
    self.zaloButton.layer.shadowOpacity = 0.8;
    self.zaloButton.tag = 1;
    [self.zaloButton addTarget:self action:@selector(contactTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.cardView addSubview:self.zaloButton];

    // --- Telegram Button ---
    self.telegramButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.telegramButton.frame = CGRectMake(30, 320, cardWidth - 60, 50);
    [self.telegramButton setTitle:[NSString stringWithFormat:@"✈️ Telegram: @%@", TELEGRAM_USER] forState:UIControlStateNormal];
    self.telegramButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    [self.telegramButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.telegramButton.backgroundColor = [UIColor colorWithRed:0.15 green:0.65 blue:0.95 alpha:1.0];
    self.telegramButton.layer.cornerRadius = 25;
    self.telegramButton.layer.cornerCurve = kCACornerCurveContinuous;
    self.telegramButton.layer.shadowColor = [UIColor colorWithRed:0.15 green:0.65 blue:0.95 alpha:0.6].CGColor;
    self.telegramButton.layer.shadowOffset = CGSizeMake(0, 4);
    self.telegramButton.layer.shadowRadius = 12;
    self.telegramButton.layer.shadowOpacity = 0.8;
    self.telegramButton.tag = 2;
    [self.telegramButton addTarget:self action:@selector(contactTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.cardView addSubview:self.telegramButton];

    // --- Close Button ---
    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.closeButton.frame = CGRectMake(cardWidth - 45, 10, 35, 35);
    self.closeButton.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.8];
    self.closeButton.layer.cornerRadius = 17.5;
    [self.closeButton setTitle:@"✕" forState:UIControlStateNormal];
    self.closeButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    [self.closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(dismissTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.cardView addSubview:self.closeButton];
}

// MARK: - Animation In
- (void)animateIn {
    self.alpha = 0;
    self.cardView.transform = CGAffineTransformMakeScale(0.5, 0.5);
    self.cardView.alpha = 0;

    // Rotate border gradient continuously
    CABasicAnimation *rotate = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotate.fromValue = @0;
    rotate.toValue = @(2 * M_PI);
    rotate.duration = 8;
    rotate.repeatCount = HUGE_VALF;
    [self.borderGradient addAnimation:rotate forKey:@"rotateBorder"];

    // Pulsate glow
    CABasicAnimation *pulseGlow = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
    pulseGlow.fromValue = @0.4;
    pulseGlow.toValue = @1.0;
    pulseGlow.duration = 1.5;
    pulseGlow.autoreverses = YES;
    pulseGlow.repeatCount = HUGE_VALF;
    [self.cardView.layer addAnimation:pulseGlow forKey:@"pulseGlow"];

    [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.55 initialSpringVelocity:0.8 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.alpha = 1.0;
        self.cardView.transform = CGAffineTransformIdentity;
        self.cardView.alpha = 1.0;
    } completion:^(BOOL finished) {
        // Animate title
        [self animateTitleIn];

        // Animate buttons sequentially
        [self animateButtonIn:self.zaloButton delay:0.25];
        [self animateButtonIn:self.telegramButton delay:0.4];

        // Animate dots
        [self animateFloatingDots];
    }];
}

- (void)animateTitleIn {
    self.titleLabel.transform = CGAffineTransformMakeTranslation(0, -20);
    self.titleLabel.alpha = 0;
    [UIView animateWithDuration:0.5 delay:0.1 usingSpringWithDamping:0.6 initialSpringVelocity:0.5 options:0 animations:^{
        self.titleLabel.transform = CGAffineTransformIdentity;
        self.titleLabel.alpha = 1.0;
    } completion:nil];

    // Icon bounce
    self.iconImageView.transform = CGAffineTransformMakeScale(0.3, 0.3);
    [UIView animateWithDuration:0.7 delay:0.0 usingSpringWithDamping:0.4 initialSpringVelocity:0.9 options:0 animations:^{
        self.iconImageView.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)animateButtonIn:(UIButton *)button delay:(NSTimeInterval)delay {
    button.transform = CGAffineTransformMakeScale(0.7, 0.7);
    button.alpha = 0;
    [UIView animateWithDuration:0.5 delay:delay usingSpringWithDamping:0.55 initialSpringVelocity:0.7 options:0 animations:^{
        button.transform = CGAffineTransformIdentity;
        button.alpha = 1.0;
    } completion:nil];
}

// MARK: - Floating Dots Animation
- (void)startFloatingDotsAnimation {
    for (UIView *dot in self.floatingDots) {
        [self animateSingleDot:dot];
    }
}

- (void)animateFloatingDots {
    for (UIView *dot in self.floatingDots) {
        dot.alpha = 1.0;
        [self animateSingleDot:dot];
    }
}

- (void)animateSingleDot:(UIView *)dot {
    CGFloat duration = 2.0 + (arc4random_uniform(30) / 10.0);
    CGFloat delay = arc4random_uniform(20) / 10.0;

    [UIView animateWithDuration:duration delay:delay options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse animations:^{
        CGFloat dx = (CGFloat)(arc4random_uniform(30) - 15);
        CGFloat dy = (CGFloat)(arc4random_uniform(30) - 15);
        dot.center = CGPointMake(dot.center.x + dx, dot.center.y + dy);
        dot.alpha = 0.2 + (arc4random_uniform(60) / 100.0);
    } completion:nil];
}

// MARK: - Animation Out
- (void)animateOut {
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:0.3 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.cardView.transform = CGAffineTransformMakeScale(0.6, 0.6);
        self.cardView.alpha = 0;
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        _sharedInstance = nil;
    }];
}

// MARK: - Actions
- (void)dismissTapped {
    [LocketNotifyView dismiss];
}

- (void)contactTapped:(UIButton *)sender {
    // Haptic feedback
    UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [feedback impactOccurred];

    // Flash animation
    [UIView animateWithDuration:0.1 animations:^{
        sender.transform = CGAffineTransformMakeScale(0.92, 0.92);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 delay:0 usingSpringWithDamping:0.3 initialSpringVelocity:0.8 options:0 animations:^{
            sender.transform = CGAffineTransformIdentity;
        } completion:nil];
    }];

    // Sao chép thông tin vào clipboard
    NSString *copyText = (sender.tag == 1) ? ZALO_PHONE : [NSString stringWithFormat:@"@%@", TELEGRAM_USER];
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    pb.string = copyText;

    // Hiển thị thông báo nhỏ trên card
    [self showCopiedToast:sender.tag == 1 ? @"Zalo" : @"Telegram"];
}

- (void)showCopiedToast:(NSString *)platform {
    UILabel *toast = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 180, 40)];
    toast.center = CGPointMake(self.cardView.bounds.size.width / 2, self.cardView.bounds.size.height - 30);
    toast.text = [NSString stringWithFormat:@"✅ Đã sao chép %@!", platform];
    toast.textAlignment = NSTextAlignmentCenter;
    toast.font = [UIFont boldSystemFontOfSize:13];
    toast.textColor = [UIColor whiteColor];
    toast.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];
    toast.layer.cornerRadius = 20;
    toast.clipsToBounds = YES;
    toast.alpha = 0;
    toast.transform = CGAffineTransformMakeTranslation(0, 20);
    [self.cardView addSubview:toast];

    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.5 options:0 animations:^{
        toast.alpha = 1.0;
        toast.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 delay:1.2 options:0 animations:^{
            toast.alpha = 0;
            toast.transform = CGAffineTransformMakeTranslation(0, -20);
        } completion:^(BOOL finished) {
            [toast removeFromSuperview];
        }];
    }];
}

@end

// ============================================================
// MARK: - Hook vào App Delegate của Locket
// ============================================================
%hook AppDelegate

- (void)applicationDidBecomeActive:(UIApplication *)application {
    %orig;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Chỉ hiển thị 1 lần sau khi app khởi động
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [LocketNotifyView show];
        });
    });
}

%end

// ============================================================
// MARK: - Constructor / Destructor
// ============================================================
%ctor {
    NSLog(@"🧩 LocketNotify dylib loaded successfully!");
}

%dtor {
    NSLog(@"🧩 LocketNotify dylib unloaded.");
}
