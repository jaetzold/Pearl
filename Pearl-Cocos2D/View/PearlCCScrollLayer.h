/*
 *   Copyright 2009, Maarten Billemont
 *
 *   Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *   You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 *   Unless required by applicable law or agreed to in writing, software
 *   distributed under the License is distributed on an "AS IS" BASIS,
 *   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *   See the License for the specific language governing permissions and
 *   limitations under the License.
 */

//
//  PearlCCScrollLayer.h
//  Pearl
//
//  Created by Maarten Billemont on 23/09/09.
//  Copyright 2009 lhunath (Maarten Billemont). All rights reserved.
//

#import "cocos2d.h"


typedef enum {
    PearlCCScrollContentDirectionLeftToRight = 2 << 0,
    PearlCCScrollContentDirectionRightToLeft = 2 << 1,
    PearlCCScrollContentDirectionTopToBottom = 2 << 2,
    PearlCCScrollContentDirectionBottomToTop = 2 << 3,
} PearlCCScrollContentDirection;

@protocol PearlCCScrollLayerDelegate

-(void)didUpdateScrollWithOrigin:(CGPoint)origin to:(CGPoint)newScroll;

@end


@interface PearlCCScrollLayer : CCLayer {

    @private
    CGPoint                                                                 _dragFromPoint;
    CGPoint                                                                 _dragFromPosition;

    CGFloat                                                                 _scrollPerSecond;
    CGPoint                                                                 _scrollRatio;
    CGPoint                                                                 _scrollStep;
    PearlCCScrollContentDirection _scrollContentDirection;
    CGSize                                                                  _scrollContentSize;

    CGPoint                                                                 _origin;
    CGPoint                                                                 _scroll;

    BOOL                                                                    _isTouching;
    id<NSObject, PearlCCScrollLayerDelegate>                                       _delegate;
}

@property (nonatomic, readwrite) CGFloat                                    scrollPerSecond;
@property (nonatomic, readwrite) CGPoint                                    scrollRatio;
@property (nonatomic, readwrite) CGPoint                                    scrollStep;
@property (nonatomic, readwrite) PearlCCScrollContentDirection scrollContentDirection;
@property (nonatomic, readwrite) CGSize                                     scrollContentSize;
@property (nonatomic, readwrite, retain) id<NSObject, PearlCCScrollLayerDelegate>  delegate;

+ (PearlCCScrollLayer *)scrollWithContentSize:(CGSize)contentSize direction:(PearlCCScrollContentDirection)direction;
+ (PearlCCScrollLayer *)scrollNode:(CCNode *)node direction:(PearlCCScrollContentDirection)direction;
- (id)initWithContentSize:(CGSize)contentSize direction:(PearlCCScrollContentDirection)direction;

- (void)scrollBy:(CGPoint)scrollOffset;
- (BOOL)isScrollValid:(CGPoint)scrollOffset;

- (void)didUpdateScroll;
- (CGRect)visibleRect;

@end
