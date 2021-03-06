//
//  GCoverView.m
//  GenShelf
//
//  Created by Gen on 16/3/11.
//  Copyright © 2016年 AirRaidClub. All rights reserved.
//

#import "GCoverView.h"
#import "GTween.h"
#import <objc/runtime.h>

@implementation GCoverView {
    UIView  *_coverView;
    UIViewController *_controller;
    BOOL    _showing;
}

- (id)initWithSubview:(UIView *)subview {
    self = [super init];
    if (self) {
        _coverView = [[UIView alloc] initWithFrame:self.bounds];
        _coverView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                              action:@selector(onTap)];
        [_coverView addGestureRecognizer:tap];
        [self addSubview:_coverView];
        self.contentSubview = subview;
        
        _showing = NO;
    }
    return self;
}

- (id)initWithController:(UIViewController *)controller {
    self = [self initWithSubview:controller.view];
    if (self) {
        _controller = controller;
    }
    return self;
}

- (void)setContentSubview:(UIView *)contentSubview {
    if (_contentSubview != contentSubview) {
        if (!_contentView) {
            _contentView = [[UIView alloc] init];
            _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            _contentView.backgroundColor = [UIColor redColor];
            _contentView.layer.cornerRadius = 10;
            _contentView.clipsToBounds = YES;
            
            [self addSubview:_contentView];
        }
        _contentSubview = contentSubview;
        CGRect bounds = self.bounds;
        CGFloat width = bounds.size.width * 0.8, height = bounds.size.height * 0.8;
        
        _contentView.frame = CGRectMake((bounds.size.width - width)/2,
                                        (bounds.size.height - height)/2,
                                        width, height);
        [_contentView addSubview:_contentSubview];
        _contentSubview.frame = _contentView.bounds;
        _contentSubview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
}

#define kTIME_DURING 0.4

- (void)showInView:(UIView *)view {
    if (_showing) {
        return;
    }
    _showing = YES;
    [view addSubview:self];
    _coverView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    
    self.frame = view.bounds;
    [self updateSize];
    [_coverView stopAllTweens];
    _coverView.alpha = 0;
    GTween *tween = [GTween tween:_coverView
                         duration:kTIME_DURING
                             ease:[GEaseCubicOut class]];
    [tween floatPro:@"alpha" to:1];
    [tween start];
    
    [_contentView stopAllTweens];
    tween = [GTween tween:_contentView
                 duration:kTIME_DURING
                     ease:[GEaseBackOut class]];
    CGRect bounds = self.bounds;
    CGFloat width = bounds.size.width * 0.8, height = bounds.size.height * 0.8;
    [tween rectPro:@"frame"
              from:CGRectMake((bounds.size.width - width)/2,
                              0,
                              width, height)
                to:CGRectMake((bounds.size.width - width)/2,
                              (bounds.size.height - height)/2,
                              width, height)];
    [tween floatPro:@"alpha"
               from:0 to:1];
    [tween start];
}

- (void)miss {
    if (!_showing) {
        return;
    }
    _showing = NO;
    [_coverView stopAllTweens];
    GTween *tween = [GTween tween:_coverView
                         duration:kTIME_DURING
                             ease:[GEaseCubicOut class]];
    [tween floatPro:@"alpha" to:0];
    [tween start];
    
    [_contentView stopAllTweens];
    tween = [GTween tween:_contentView
                 duration:kTIME_DURING
                     ease:[GEaseBackOut class]];
    CGRect bounds = self.bounds;
    CGFloat width = bounds.size.width * 0.8, height = bounds.size.height * 0.8;
    [tween rectPro:@"frame"
                to:CGRectMake((bounds.size.width - width)/2,
                              (bounds.size.height - height)/2 - 100,
                              width, height)];
    [tween floatPro:@"alpha"
                 to:0];
    [tween.onComplete addBlock:^{
        [self removeFromSuperview];
    }];
    [tween start];
}

- (void)updateSize {
    CGRect bounds = self.bounds;
    CGFloat width = bounds.size.width * 0.8, height = bounds.size.height * 0.8;
    _contentView.frame = CGRectMake((bounds.size.width - width)/2,
                                    (bounds.size.height - height)/2,
                                    width, height);
}

- (void)onTap {
    [self miss];
}

@end
