#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "LocketNotifyView.h"

// ============================================================
// MARK: - Các macro cấu hình
// ============================================================
#define CREDIT_NAME         @"younj_icloud"
#define ZALO_PHONE          @"0981309921"
#define TELEGRAM_USER       @"younj_icloud"

// ============================================================
// MARK: - LocketNotifyView Class Extension
// ============================================================
@interface LocketNotifyView ()
@property (nonatomic, strong) UIView *backgroundDimView;
@property (nonatomic, strong) UIVisualEffectView *cardBlurView;
@property (nonatomic, strong) UIView *borderContainerView;
@property (nonatomic, strong) CAGradientLayer *rotatingGradientLayer;
@property (nonatomic, strong) CAShapeLayer *staticBorderMask;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *creditLabel;
@property (nonatomic, strong) UIButton *zaloButton;
@property (nonatomic, strong) UIButton *telegramButton;
@property (nonatomic, strong) UIButton *bottomCloseButton;
@property (nonatomic, strong) UIButton *topXButton;
@property (nonatomic, strong) UIView *iconContainerView;
@property (nonatomic, strong) NSMutableArray<UIView *> *floatingDots;

- (void)setupUltimateViews;
- (void)animateIn;
- (void)animateOut;
- (void)startFloatingDotsAnimation;
- (void)animateSingleDot:(UIView *)dot;
- (void)dismissTapped;
- (void)contactTapped:(UIButton *)sender;
- (void)showCopiedToast:(NSString *)platform;
@end

@implementation LocketNotifyView

static LocketNotifyView *_sharedInstance = nil;

+ (void)show {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_sharedInstance) {
            [_sharedInstance removeFromSuperview];
            _sharedInstance = nil;
        }
        _sharedInstance = [[LocketNotifyView alloc] initWithFrame:UIScreen.mainScreen.bounds];
        
        UIWindow *keyWindow = nil;
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in scene.windows) {
                    if (window.isKeyWindow) {
                        keyWindow = window;
                        break;
                    }
                }
                if (keyWindow) break;
            }
        }
        if (keyWindow) {
            [keyWindow addSubview:_sharedInstance];
            [_sharedInstance animateIn];
        } else {
            NSLog(@"❌ LocketNotify: Không tìm thấy keyWindow!");
        }
    });
}

+ (void)dismiss {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_sharedInstance animateOut];
    });
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.floatingDots = [NSMutableArray array];
        [self setupUltimateViews];
        [self startFloatingDotsAnimation];
    }
    return self;
}

- (void)setupUltimateViews {
    // 1. Phông nền tối mờ hậu cảnh
    self.backgroundDimView = [[UIView alloc] initWithFrame:self.bounds];
    self.backgroundDimView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.45];
    self.backgroundDimView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.backgroundDimView];

    UITapGestureRecognizer *tapBg = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissTapped)];
    [self.backgroundDimView addGestureRecognizer:tapBg];

    // Cấu hình Kích thước gọn gàng ôm form máy
    CGFloat cardWidth = MIN(self.bounds.size.width - 50, 330);
    CGFloat cardHeight = 415;
    
    // 2. Thẻ Kính mờ (Main Glassmorphism Card)
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    self.cardBlurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    self.cardBlurView.frame = CGRectMake(0, 0, cardWidth, cardHeight);
    self.cardBlurView.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    self.cardBlurView.layer.cornerRadius = 28;
    self.cardBlurView.layer.cornerCurve = kCACornerCurveContinuous;
    self.cardBlurView.clipsToBounds = YES;
    
    // Đổ bóng mềm mại tạo chiều sâu
    self.cardBlurView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.cardBlurView.layer.shadowOffset = CGSizeMake(0, 15);
    self.cardBlurView.layer.shadowRadius = 30;
    self.cardBlurView.layer.shadowOpacity = 0.55;
    self.cardBlurView.layer.masksToBounds = NO; 
    [self addSubview:self.cardBlurView];

    // 3. Khung Viền Xoay Định Vị Tĩnh
    self.borderContainerView = [[UIView alloc] initWithFrame:self.cardBlurView.bounds];
    self.borderContainerView.userInteractionEnabled = NO;
    
    self.staticBorderMask = [CAShapeLayer layer];
    self.staticBorderMask.path = [UIBezierPath bezierPathWithRoundedRect:self.borderContainerView.bounds cornerRadius:28].CGPath;
    self.staticBorderMask.fillColor = [UIColor clearColor].CGColor;
    self.staticBorderMask.strokeColor = [UIColor whiteColor].CGColor;
    self.staticBorderMask.lineWidth = 1.8;
    self.borderContainerView.layer.mask = self.staticBorderMask;

    self.rotatingGradientLayer = [CAGradientLayer layer];
    CGFloat maxDimension = MAX(cardWidth, cardHeight) * 1.5;
    self.rotatingGradientLayer.frame = CGRectMake(0, 0, maxDimension, maxDimension);
    self.rotatingGradientLayer.position = CGPointMake(cardWidth / 2, cardHeight / 2);
    self.rotatingGradientLayer.colors = @[
        (id)[UIColor colorWithRed:1.0 green:0.35 blue:0.6 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.5 green:0.30 blue:1.0 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.2 green:0.75 blue:1.0 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:1.0 green:0.35 blue:0.6 alpha:1.0].CGColor
    ];
    self.rotatingGradientLayer.startPoint = CGPointMake(0, 0);
    self.rotatingGradientLayer.endPoint = CGPointMake(1, 1);
    [self.borderContainerView.layer addSublayer:self.rotatingGradientLayer];
    [self.cardBlurView.contentView.layer addSublayer:self.borderContainerView.layer];

    // 4. Hạt bụi bay lơ lửng ngầm
    for (int i = 0; i < 8; i++) {
        UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 3, 3)];
        dot.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.15 + (arc4random_uniform(30) / 100.0)];
        dot.layer.cornerRadius = 1.5;
        dot.center = CGPointMake(arc4random_uniform((int)cardWidth), arc4random_uniform((int)cardHeight));
        dot.alpha = 0;
        [self.cardBlurView.contentView addSubview:dot];
        [self.floatingDots addObject:dot];
    }

    // 5. Khung chứa Icon chính giữa
    self.iconContainerView = [[UIView alloc] initWithFrame:CGRectMake((cardWidth - 70)/2, 25, 70, 70)];
    self.iconContainerView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.08];
    self.iconContainerView.layer.cornerRadius = 35;
    self.iconContainerView.layer.borderWidth = 1.0;
    self.iconContainerView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.12].CGColor;
    
    UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(13, 13, 44, 44)];
    if (@available(iOS 13.0, *)) {
        UIImage *cameraIcon = [UIImage systemImageNamed:@"camera.macro.circle.fill"];
        if (!cameraIcon) cameraIcon = [UIImage systemImageNamed:@"camera.circle.fill"];
        iconView.image = [cameraIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        iconView.tintColor = [UIColor whiteColor];
    } else {
        UILabel *emojiIcon = [[UILabel alloc] initWithFrame:iconView.bounds];
        emojiIcon.text = @"📸";
        emojiIcon.font = [UIFont systemFontOfSize:36];
        emojiIcon.textAlignment = NSTextAlignmentCenter;
        [iconView addSubview:emojiIcon];
    }
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    [self.iconContainerView addSubview:iconView];
    [self.cardBlurView.contentView addSubview:self.iconContainerView];

    // 6. Tiêu đề
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 110, cardWidth - 40, 26)];
    self.titleLabel.text = @"Chào mừng đến Locket";
    self.titleLabel.font = [UIFont systemFontOfSize:21 weight:UIFontWeightBold];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.cardBlurView.contentView addSubview:self.titleLabel];

    self.subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 140, cardWidth - 40, 18)];
    self.subtitleLabel.text = @"Khoảnh khắc hôm nay thật đẹp!";
    self.subtitleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    self.subtitleLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
    [self.cardBlurView.contentView addSubview:self.subtitleLabel];

    // 7. Nhãn Credit bản quyền
    self.creditLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 175, cardWidth - 40, 18)];
    NSString *creditText = [NSString stringWithFormat:@"Made by %@", CREDIT_NAME];
    NSMutableAttributedString *attrCredit = [[NSMutableAttributedString alloc] initWithString:creditText];
    [attrCredit addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithWhite:0.55 alpha:1.0] range:NSMakeRange(0, 8)];
    [attrCredit addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12 weight:UIFontWeightRegular] range:NSMakeRange(0, 8)];
    [attrCredit addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:1.0 green:0.55 blue:0.65 alpha:1.0] range:NSMakeRange(8, creditText.length - 8)];
    [attrCredit addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12 weight:UIFontWeightSemibold] range:NSMakeRange(8, creditText.length - 8)];
    self.creditLabel.attributedText = attrCredit;
    self.creditLabel.textAlignment = NSTextAlignmentCenter;
    [self.cardBlurView.contentView addSubview:self.creditLabel];

    // Block khởi tạo nút liên lạc nhanh
    UIButton *(^createContactButton)(NSString *, NSString *, UIColor *, CGFloat, NSInteger) = ^UIButton *(NSString *title, NSString *iconName, UIColor *bgColor, CGFloat yPos, NSInteger tag) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(25, yPos, cardWidth - 50, 46);
        btn.backgroundColor = bgColor;
        btn.layer.cornerRadius = 14;
        btn.layer.cornerCurve = kCACornerCurveContinuous;
        btn.tag = tag;
        
        if (@available(iOS 13.0, *)) {
            UIImage *icon = [[UIImage systemImageNamed:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [btn setImage:icon forState:UIControlStateNormal];
            btn.tintColor = [UIColor whiteColor];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            btn.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 8);
#pragma clang diagnostic pop
        }
        
        [btn setTitle:title forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(contactTapped:) forControlEvents:UIControlEventTouchUpInside];
        return btn;
    };

    // 8. Các nút Liên lạc Mạng xã hội bố trí cực gọn
    self.zaloButton = createContactButton([NSString stringWithFormat:@"Zalo: %@", ZALO_PHONE], @"message.fill", [UIColor colorWithRed:0.0 green:0.48 blue:0.9 alpha:0.95], 215, 1);
    [self.cardBlurView.contentView addSubview:self.zaloButton];

    self.telegramButton = createContactButton([NSString stringWithFormat:@"Telegram: @%@", TELEGRAM_USER], @"paperplane.fill", [UIColor colorWithRed:0.12 green:0.58 blue:0.87 alpha:0.95], 273, 2);
    [self.cardBlurView.contentView addSubview:self.telegramButton];

    // 9. Nút ĐÓNG bên dưới mỏng nhẹ sang trọng
    self.bottomCloseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.bottomCloseButton.frame = CGRectMake(25, 345, cardWidth - 50, 44);
    self.bottomCloseButton.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.06];
    self.bottomCloseButton.layer.cornerRadius = 12;
    self.bottomCloseButton.layer.cornerCurve = kCACornerCurveContinuous;
    self.bottomCloseButton.layer.borderWidth = 0.8;
    self.bottomCloseButton.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.08].CGColor;
    [self.bottomCloseButton setTitle:@"Đóng" forState:UIControlStateNormal];
    self.bottomCloseButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [self.bottomCloseButton setTitleColor:[UIColor colorWithWhite:0.8 alpha:1.0] forState:UIControlStateNormal];
    [self.bottomCloseButton addTarget:self action:@selector(dismissTapped) forControlEvents:UIControlEventTouchUpInside];
    
    [self.bottomCloseButton addTarget:self action:@selector(contactTapped:) forControlEvents:UIControlEventTouchDown]; 
    [self.cardBlurView.contentView addSubview:self.bottomCloseButton];

    // 10. Nút chữ X nhỏ góc trên (ĐÃ SỬA LỖI ĐÓNG NGOẶC ] TẠI ĐÂY)
    self.topXButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.topXButton.frame = CGRectMake(cardWidth - 38, 12, 26, 26);
    self.topXButton.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    self.topXButton.layer.cornerRadius = 13;
    
    if (@available(iOS 13.0, *)) {
        UIImage *xIcon = [[UIImage systemImageNamed:@"xmark"] imageWithConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:10 weight:UIImageSymbolWeightBold]];
        [self.topXButton setImage:xIcon forState:UIControlStateNormal];
        self.topXButton.tintColor = [UIColor colorWithWhite:0.75 alpha:1.0];
    } else {
        [self.topXButton setTitle:@"✕" forState:UIControlStateNormal];
        self.topXButton.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
    }
    [self.topXButton addTarget:self action:@selector(dismissTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.cardBlurView.contentView addSubview:self.topXButton];
}

// ============================================================
// MARK: - Hệ thống Hoạt họa
// ============================================================
- (void)animateIn {
    self.backgroundDimView.alpha = 0;
    self.cardBlurView.alpha = 0;
    self.cardBlurView.transform = CGAffineTransformMakeScale(0.85, 0.85);
    
    CABasicAnimation *rotateAnim = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotateAnim.fromValue = @0;
    rotateAnim.toValue = @(2 * M_PI);
    rotateAnim.duration = 6.0;
    rotateAnim.repeatCount = HUGE_VALF;
    [self.rotatingGradientLayer addAnimation:rotateAnim forKey:@"smoothBorderRotation"];

    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.78 initialSpringVelocity:0.4 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.backgroundDimView.alpha = 1.0;
        self.cardBlurView.alpha = 1.0;
        self.cardBlurView.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)startFloatingDotsAnimation {
    for (UIView *dot in self.floatingDots) {
        dot.alpha = 1.0;
        [self animateSingleDot:dot];
    }
}

- (void)animateSingleDot:(UIView *)dot {
    CGFloat duration = 3.5 + (arc4random_uniform(25) / 10.0);
    CGFloat delay = arc4random_uniform(20) / 10.0;
    [UIView animateWithDuration:duration delay:delay options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse animations:^{
        CGFloat dx = (CGFloat)(arc4random_uniform(30) - 15);
        CGFloat dy = (CGFloat)(arc4random_uniform(30) - 15);
        dot.center = CGPointMake(dot.center.x + dx, dot.center.y + dy);
        dot.alpha = 0.05 + (arc4random_uniform(30) / 100.0);
    } completion:nil];
}

- (void)animateOut {
    [UIView animateWithDuration:0.22 animations:^{
        self.backgroundDimView.alpha = 0;
        self.cardBlurView.alpha = 0;
        self.cardBlurView.transform = CGAffineTransformMakeScale(0.94, 0.94);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        _sharedInstance = nil;
    }];
}

- (void)dismissTapped {
    [LocketNotifyView dismiss];
}

- (void)contactTapped:(UIButton *)sender {
    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *haptic = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [haptic impactOccurred];
    }

    [UIView animateWithDuration:0.08 animations:^{
        sender.transform = CGAffineTransformMakeScale(0.96, 0.96);
        sender.alpha = 0.85;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.4 options:0 animations:^{
            sender.transform = CGAffineTransformIdentity;
            sender.alpha = 1.0;
        } completion:nil];
    }];

    if (sender == self.bottomCloseButton) return;

    NSString *copyText = (sender.tag == 1) ? ZALO_PHONE : [NSString stringWithFormat:@"@%@", TELEGRAM_USER];
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    pb.string = copyText;

    [self showCopiedToast:sender.tag == 1 ? @"Zalo" : @"Telegram"];
}

- (void)showCopiedToast:(NSString *)platform {
    UIView *toast = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 210, 44)];
    toast.center = CGPointMake(self.cardBlurView.bounds.size.width / 2, self.cardBlurView.bounds.size.height / 2);
    toast.layer.cornerRadius = 22;
    toast.clipsToBounds = NO; 
    
    CAGradientLayer *toastGrad = [CAGradientLayer layer];
    toastGrad.frame = toast.bounds;
    toastGrad.colors = @[
        (id)[UIColor colorWithRed:0.00 green:0.75 blue:0.45 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.05 green:0.55 blue:0.90 alpha:1.0].CGColor
    ];
    toastGrad.startPoint = CGPointMake(0, 0);
    toastGrad.endPoint = CGPointMake(1, 1);
    toastGrad.cornerRadius = 22;
    [toast.layer addSublayer:toastGrad];
    
    toast.layer.shadowColor = [UIColor colorWithRed:0.00 green:0.75 blue:0.45 alpha:1.0].CGColor;
    toast.layer.shadowOffset = CGSizeZero;
    toast.layer.shadowRadius = 12;
    toast.layer.shadowOpacity = 0.65;

    UILabel *toastLabel = [[UILabel alloc] initWithFrame:toast.bounds];
    toastLabel.text = [NSString stringWithFormat:@"✨ Đã chép %@ ✨", platform];
    toastLabel.textAlignment = NSTextAlignmentCenter;
    toastLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    toastLabel.textColor = [UIColor whiteColor];
    [toast addSubview:toastLabel];

    [self.cardBlurView.contentView addSubview:toast];

    toast.alpha = 0;
    toast.transform = CGAffineTransformMakeScale(0.5, 0.5);

    [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.65 initialSpringVelocity:0.5 options:0 animations:^{
        toast.alpha = 1.0;
        toast.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.25 delay:1.1 options:0 animations:^{
            toast.alpha = 0;
            toast.transform = CGAffineTransformMakeScale(0.8, 0.8);
        } completion:^(BOOL finished) {
            [toast removeFromSuperview];
        }];
    }];
}

@end

// ============================================================
// MARK: - Constructor
// ============================================================
%ctor {
    NSLog(@"🧩 LocketNotify Ultimate Compact Edition Loaded!");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [LocketNotifyView show];
    });
}
