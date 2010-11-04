//
//  UIUtils.m
//  iLibs
//
//  Created by Maarten Billemont on 29/10/10.
//  Copyright 2010, lhunath (Maarten Billemont). All rights reserved.
//

#import "UIUtils.h"
#import "Logger.h"
#import "AbstractAppDelegate.h"
#import "BoxView.h"


@interface UIUtils ()

+ (void)keyboardWillHide:(NSNotification *)n;
+ (void)keyboardWillShow:(NSNotification *)n;

@end


@implementation UIUtils

static UIScrollView *keyboardScrollView, *keyboardActiveScrollView;
static CGPoint      keyboardScrollOriginalOffset;
static CGRect       keyboardScrollOriginalFrame;

+ (void)autoSizeContent:(UIScrollView *)scrollView {
    
    [self autoSizeContent:scrollView ignoreSubviews:nil];
}

+ (void)autoSizeContent:(UIScrollView *)scrollView ignoreSubviews:(NSArray *)ignoredSubviews {

    // === Step 1: Calculate the UIScrollView's contentSize.
    // Determine content frame.
    CGRect contentRect = CGRectNull;
    for (UIView *subview in scrollView.subviews)
        if (subview.alpha && ![ignoredSubviews containsObject:subview]) {
            if (CGRectIsNull(contentRect))
                contentRect = subview.frame;
            else
                contentRect = CGRectUnion(contentRect, subview.frame);
        }
    
    // Add right/bottom padding by adding left/top offset to the size.
    CGRect paddedRect = (CGRect){CGPointZero,
        CGSizeMake(contentRect.size.width   + fmaxf(0, contentRect.origin.x) * 2,
                   contentRect.size.height  + fmaxf(0, contentRect.origin.y) * 2)};
    
    // Apply rect to scrollView's content definition.
    scrollView.contentOffset = CGPointZero;
    scrollView.contentSize = paddedRect.size;

    // === Step 2: Manage the scroll view on keyboard notifications.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:scrollView.window];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:scrollView.window];
    keyboardScrollView = scrollView;
}

+ (void)showBoundingBoxForView:(UIView *)view {
    
    dbg(@"Showing bounding box for view: %@", view);
    [view addSubview:[BoxView boxWithFrame:(CGRect){CGPointZero, view.bounds.size} color:[UIColor redColor]]];
}

+ (CGRect)frameInWindow:(UIView *)view {
    
    return [view.window convertRect:view.bounds fromView:view];
}

+ (UIView *)findFirstResonder {
    
    return [self findFirstResonderIn:[UIApplication sharedApplication].keyWindow];
}

+ (UIView *)findFirstResonderIn:(UIView *)view {
    
    if (view.isFirstResponder)
        return view;

    for (UIView *subView in view.subviews) {
        UIView *firstResponder = [self findFirstResonderIn:subView];
        if (firstResponder != nil)
            return firstResponder;
    }
    
    return nil;
}

+ (void)keyboardWillShow:(NSNotification *)n {
    
    if (keyboardActiveScrollView || !keyboardScrollView) {
        // Don't do any scrollview animation when one is already active (not yet deactivated) or when no scrollview is set.
        
        if (keyboardActiveScrollView && keyboardActiveScrollView != keyboardScrollView)
            err(@"Keyboard was activated for a scroll view while already active for another scroll view.  This shouldn't happen!");
        
        return;
    }
    
    // Activate scrollview so we know which one to restore when the keyboard is hidden.
    keyboardActiveScrollView = keyboardScrollView;
    
    NSDictionary* userInfo = [n userInfo];
    CGRect keyboardRect = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect scrollRect   = [self frameInWindow:keyboardActiveScrollView];
    CGRect hiddenRect   = CGRectIntersection(scrollRect, keyboardRect);
    
    keyboardScrollOriginalOffset            = keyboardActiveScrollView.contentOffset;
    keyboardScrollOriginalFrame             = keyboardActiveScrollView.frame;
    CGPoint keyboardScrollNewOffset         = keyboardScrollOriginalOffset;
    keyboardScrollNewOffset.y               += keyboardRect.size.height / 2;
    CGRect keyboardScrollNewFrame           = keyboardActiveScrollView.frame;
    keyboardScrollNewFrame.size.height      -= hiddenRect.size.height;

    UIView *responder = [self findFirstResonder];
    if (responder) {
        CGRect responderRect = [keyboardActiveScrollView convertRect:responder.bounds fromView:responder];
        
        if (responderRect.origin.y < keyboardScrollNewOffset.y)
            keyboardScrollNewOffset.y = 0;
        else if (responderRect.origin.y > keyboardScrollNewOffset.y + keyboardScrollNewFrame.size.height)
            keyboardScrollNewOffset.y = responderRect.origin.y;
    }

    UIScrollView *animatingScrollView = keyboardActiveScrollView;
    [UIView animateWithDuration:[[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]
                          delay:0 options:[[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] unsignedIntValue]
                     animations:^(void) {
                         dbg(@"showing keyboard for scrollView: %x", keyboardActiveScrollView);
                         dbg(@"    keyboardScrollNewOffset: %@", NSStringFromCGPoint(keyboardScrollNewOffset));
                         dbg(@"    keyboardScrollNewFrame: %@", NSStringFromCGRect(keyboardScrollNewFrame));
                         animatingScrollView.contentOffset    = keyboardScrollNewOffset;
                         animatingScrollView.frame            = keyboardScrollNewFrame;
                     } completion:nil];
}

+ (void)keyboardWillHide:(NSNotification *)n {
    
    if (!keyboardActiveScrollView)
        // Don't do any scrollview animation when no scrollview is active.
        return;
    
    NSDictionary* userInfo = [n userInfo];
    CGPoint keyboardScrollNewOffset         = keyboardScrollOriginalOffset;
    CGRect keyboardScrollNewFrame           = keyboardScrollOriginalFrame;
    
    UIScrollView *animatingScrollView = keyboardActiveScrollView;
    [UIView animateWithDuration:[[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]
                          delay:0 options:[[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] unsignedIntValue]
                     animations:^(void) {
                         dbg(@"hiding keyboard for scrollView: %x", keyboardActiveScrollView);
                         dbg(@"    keyboardScrollOriginalOffset: %@", NSStringFromCGPoint(keyboardScrollNewOffset));
                         dbg(@"    keyboardScrollOriginalFrame: %@", NSStringFromCGRect(keyboardScrollNewFrame));
                         
                         animatingScrollView.contentOffset    = keyboardScrollNewOffset;
                         animatingScrollView.frame            = keyboardScrollNewFrame;
                     } completion:nil];
    
    // Active scrollview is restoring state.  Deactivate it so it can be reactivated.
    keyboardActiveScrollView = nil;
}

+ (id)copyOf:(id)view {
    
    id copy = [[[view class] alloc] initWithFrame:[view frame]];
    
    NSMutableArray *properties = [NSMutableArray array];
    
    // UIView
    if ([view isKindOfClass:[UIView class]]) {
        [properties addObject:@"userInteractionEnabled"];
        [properties addObject:@"tag"];
        [properties addObject:@"bounds"];
        [properties addObject:@"center"];
        [properties addObject:@"transform"];
        [properties addObject:@"contentScaleFactor"];
        [properties addObject:@"multipleTouchEnabled"];
        [properties addObject:@"exclusiveTouch"];
        [properties addObject:@"autoresizesSubviews"];
        [properties addObject:@"autoresizingMask"];
        [properties addObject:@"clipsToBounds"];
        [properties addObject:@"backgroundColor"];
        [properties addObject:@"alpha"];
        [properties addObject:@"opaque"];
        [properties addObject:@"clearsContextBeforeDrawing"];
        [properties addObject:@"hidden"];
        [properties addObject:@"contentMode"];
        [properties addObject:@"contentStretch"];
    }
    
    // UILabel
    if ([view isKindOfClass:[UILabel class]]) {
        [properties addObject:@"text"];
        [properties addObject:@"font"];
        [properties addObject:@"textColor"];
        [properties addObject:@"shadowColor"];
        [properties addObject:@"shadowOffset"];
        [properties addObject:@"textAlignment"];
        [properties addObject:@"lineBreakMode"];
        [properties addObject:@"highlightedTextColor"];
        [properties addObject:@"highlighted"];
        [properties addObject:@"enabled"];
        [properties addObject:@"numberOfLines"];
        [properties addObject:@"adjustsFontSizeToFitWidth"];
        [properties addObject:@"minimumFontSize"];
        [properties addObject:@"baselineAdjustment"];
    }

    // UIControl
    if ([view isKindOfClass:[UIControl class]]) {
        [properties addObject:@"enabled"];
        [properties addObject:@"selected"];
        [properties addObject:@"highlighted"];
        [properties addObject:@"contentVerticalAlignment"];
        [properties addObject:@"contentHorizontalAlignment"];
    }
    
    // UITextField
    if ([view isKindOfClass:[UITextField class]]) {
        [properties addObject:@"text"];
        [properties addObject:@"textColor"];
        [properties addObject:@"font"];
        [properties addObject:@"textAlignment"];
        [properties addObject:@"borderStyle"];
        [properties addObject:@"placeholder"];
        [properties addObject:@"clearsOnBeginEditing"];
        [properties addObject:@"adjustsFontSizeToFitWidth"];
        [properties addObject:@"minimumFontSize"];
        [properties addObject:@"delegate"];
        [properties addObject:@"background"];
        [properties addObject:@"disabledBackground"];
        [properties addObject:@"clearButtonMode"];
        [view setLeftView:[[self copyOf:[view leftView]] autorelease]];
        [properties addObject:@"leftViewMode"];
        [view setRightView:[[self copyOf:[view rightView]] autorelease]];
        [properties addObject:@"rightViewMode"];
        [view setInputView:[[self copyOf:[view inputView]] autorelease]];
        [view setInputAccessoryView:[[self copyOf:[view inputAccessoryView]] autorelease]];
    }
    
    // Copy properties.
    [copy setValuesForKeysWithDictionary:[view dictionaryWithValuesForKeys:properties]];
    
    // Add copy to view's hierarchy and copy on recursively.
    [[view superview] addSubview:copy];
    for (UIView *subView in [view subviews])
        [copy addSubview:[[self copyOf:subView] autorelease]];
    
    return copy;
}

@end