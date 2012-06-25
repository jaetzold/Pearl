/**
 * Copyright Maarten Billemont (http://www.lhunath.com, lhunath@lyndir.com)
 *
 * See the enclosed file LICENSE for license information (LGPLv3). If you did
 * not receive this file, see http://www.gnu.org/licenses/lgpl-3.0.txt
 *
 * @author   Maarten Billemont <lhunath@lyndir.com>
 * @license  http://www.gnu.org/licenses/lgpl-3.0.txt
 */

//
//  PearlSheet.m
//  Pearl
//
//  Created by Maarten Billemont on 08/08/09.
//  Copyright, lhunath (Maarten Billemont) 2009. All rights reserved.
//


@interface PearlSheet (Private)

- (id)initWithTitle:(NSString *)title message:(NSString *)message viewStyle:(UIActionSheetStyle)viewStyle
  tappedButtonBlock:(void (^)(UIActionSheet *sheet, NSInteger buttonIndex))aTappedButtonBlock
        cancelTitle:(NSString *)cancelTitle destructiveTitle:(NSString *)destructiveTitle
         otherTitle:(NSString *)otherTitle :(va_list)otherTitlesList;
+ (PearlSheet *)showSheetWithTitle:(NSString *)title message:(NSString *)message viewStyle:(UIActionSheetStyle)viewStyle
                 tappedButtonBlock:(void (^)(UIActionSheet *sheet, NSInteger buttonIndex))aTappedButtonBlock
                       cancelTitle:(NSString *)cancelTitle destructiveTitle:(NSString *)destructiveTitle
                        otherTitle:(NSString *)firstOtherTitle :(va_list)otherTitlesList;

@end


@implementation PearlSheet
@synthesize sheetView;

+ (NSMutableArray *)activeSheets {

    static NSMutableArray *activeSheets = nil;
    if (!activeSheets)
        activeSheets = [[NSMutableArray alloc] initWithCapacity:3];

    return activeSheets;
}


#pragma mark ###############################
#pragma mark Lifecycle

- (id)initWithTitle:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle {

    return [self initWithTitle:title message:message viewStyle:UIActionSheetStyleAutomatic tappedButtonBlock:nil cancelTitle:cancelTitle
              destructiveTitle:nil otherTitles:nil];
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message viewStyle:(UIActionSheetStyle)viewStyle
  tappedButtonBlock:(void (^)(UIActionSheet *sheet, NSInteger buttonIndex))aTappedButtonBlock
        cancelTitle:(NSString *)cancelTitle destructiveTitle:(NSString *)destructiveTitle
        otherTitles:(NSString *)otherTitles, ... {

    va_list(otherTitlesList);
    va_start(otherTitlesList, otherTitles);

    return [self initWithTitle:title message:message viewStyle:viewStyle tappedButtonBlock:aTappedButtonBlock
                   cancelTitle:cancelTitle destructiveTitle:destructiveTitle
                    otherTitle:otherTitles :otherTitlesList];
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message viewStyle:(UIActionSheetStyle)viewStyle
  tappedButtonBlock:(void (^)(UIActionSheet *sheet, NSInteger buttonIndex))aTappedButtonBlock
        cancelTitle:(NSString *)cancelTitle destructiveTitle:(NSString *)destructiveTitle
         otherTitle:(NSString *)firstOtherTitle :(va_list)otherTitlesList {

    if (!(self = [super init]))
        return self;

    tappedButtonBlock = [aTappedButtonBlock copy];
    sheetView         = [[UIActionSheet alloc] initWithTitle:title delegate:self
                                           cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    sheetView.actionSheetStyle = viewStyle;

    if (destructiveTitle)
        sheetView.destructiveButtonIndex = [sheetView addButtonWithTitle:destructiveTitle];
    if (firstOtherTitle)
        [sheetView addButtonWithTitle:firstOtherTitle];
    if (otherTitlesList) {
        for (NSString *otherTitle; (otherTitle = va_arg(otherTitlesList, id));)
            [sheetView addButtonWithTitle:otherTitle];
        va_end(otherTitlesList);
    }
    if (cancelTitle)
        sheetView.cancelButtonIndex      = [sheetView addButtonWithTitle:cancelTitle];

    return self;
}

+ (PearlSheet *)showError:(NSString *)message {

    return [self showSheetWithTitle:[PearlStrings get].commonTitleError message:message viewStyle:UIActionSheetStyleAutomatic
                                                              tappedButtonBlock:nil cancelTitle:[PearlStrings get].commonButtonOkay
                                                              destructiveTitle:nil otherTitles:nil];
}

+ (PearlSheet *)showError:(NSString *)message
        tappedButtonBlock:(void (^)(UIActionSheet *sheet, NSInteger buttonIndex))aTappedButtonBlock
         destructiveTitle:(NSString *)destructiveTitle otherTitles:(NSString *)otherTitles, ... {

    va_list(otherTitlesList);
    va_start(otherTitlesList, otherTitles);

    return [self showSheetWithTitle:[PearlStrings get].commonTitleError message:message viewStyle:UIActionSheetStyleAutomatic
                                                              tappedButtonBlock:aTappedButtonBlock
                                                                    cancelTitle:[PearlStrings get].commonButtonOkay
                                                                    destructiveTitle:destructiveTitle
                                                                          otherTitle:otherTitles :otherTitlesList];
}

+ (PearlSheet *)showNotice:(NSString *)message {

    return [self showSheetWithTitle:[PearlStrings get].commonTitleNotice message:message viewStyle:UIActionSheetStyleAutomatic
                                                               tappedButtonBlock:nil cancelTitle:[PearlStrings get].commonButtonThanks
                                                               destructiveTitle:nil otherTitles:nil];
}

+ (PearlSheet *)showNotice:(NSString *)message
         tappedButtonBlock:(void (^)(UIActionSheet *sheet, NSInteger buttonIndex))aTappedButtonBlock
          destructiveTitle:(NSString *)destructiveTitle otherTitles:(NSString *)otherTitles, ... {

    va_list(otherTitlesList);
    va_start(otherTitlesList, otherTitles);

    return [self showSheetWithTitle:[PearlStrings get].commonTitleNotice message:message viewStyle:UIActionSheetStyleAutomatic
                                                               tappedButtonBlock:aTappedButtonBlock
                                                                     cancelTitle:[PearlStrings get].commonButtonThanks
                                                                     destructiveTitle:destructiveTitle
                                                                           otherTitle:otherTitles :otherTitlesList];
}

+ (PearlSheet *)showSheetWithTitle:(NSString *)title message:(NSString *)message viewStyle:(UIActionSheetStyle)viewStyle
                 tappedButtonBlock:(void (^)(UIActionSheet *sheet, NSInteger buttonIndex))aTappedButtonBlock
                       cancelTitle:(NSString *)cancelTitle destructiveTitle:(NSString *)destructiveTitle
                        otherTitle:(NSString *)firstOtherTitle :(va_list)otherTitlesList {

    return [[[PearlSheet alloc] initWithTitle:title message:message viewStyle:viewStyle
                            tappedButtonBlock:aTappedButtonBlock cancelTitle:cancelTitle destructiveTitle:destructiveTitle
                                   otherTitle:firstOtherTitle :otherTitlesList] showSheet];
}

+ (PearlSheet *)showSheetWithTitle:(NSString *)title message:(NSString *)message viewStyle:(UIActionSheetStyle)viewStyle
                 tappedButtonBlock:(void (^)(UIActionSheet *sheet, NSInteger buttonIndex))aTappedButtonBlock
                       cancelTitle:(NSString *)cancelTitle destructiveTitle:(NSString *)destructiveTitle
                       otherTitles:(NSString *)otherTitles, ... {

    va_list(otherTitlesList);
    va_start(otherTitlesList, otherTitles);

    return [self showSheetWithTitle:title message:message viewStyle:viewStyle tappedButtonBlock:aTappedButtonBlock
                        cancelTitle:cancelTitle destructiveTitle:destructiveTitle
                         otherTitle:otherTitles :otherTitlesList];
}

#pragma mark ###############################
#pragma mark Behaviors

- (PearlSheet *)showSheet {

    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (!window)
        window = [[UIApplication sharedApplication].windows objectAtIndex:0];
    [sheetView showInView:window.rootViewController.view];
    [((NSMutableArray *)[PearlSheet activeSheets]) addObject:self];

    return self;
}


- (PearlSheet *)dismissSheet {

    [sheetView dismissWithClickedButtonIndex:0 animated:YES];

    return self;
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {

    if (tappedButtonBlock)
        tappedButtonBlock(self.sheetView, buttonIndex);
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {

    [((NSMutableArray *)[PearlSheet activeSheets]) removeObject:self];
}


@end
