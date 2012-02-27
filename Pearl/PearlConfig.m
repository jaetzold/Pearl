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
//  PearlConfig.m
//  Pearl
//
//  Created by Maarten Billemont on 25/10/08.
//  Copyright 2008-2009, lhunath (Maarten Billemont). All rights reserved.
//

#import "PearlConfig.h"
#import "PearlLogger.h"
#import "PearlAppDelegate.h"
#import "PearlResettable.h"
#import "NSString_PearlSEL.h"
#import "PearlStringUtils.h"
#import "PearlStrings.h"
#ifdef PEARL_MEDIA
#import "PearlAudioController.h"
#endif


@interface PearlConfig ()

@property (nonatomic, readwrite, retain) NSUserDefaults         *defaults;

@property (nonatomic, readwrite, retain) NSMutableDictionary    *resetTriggers;

@end


@implementation PearlConfig

@synthesize defaults = _defaults;
@synthesize resetTriggers = _resetTriggers;
@synthesize notificationsChecked = _notificationsChecked, notificationsSupported = _notificationsSupported;

@dynamic build, version, copyright, firstRun, supportedNotifications, deviceToken;
@dynamic fontSize, largeFontSize, smallFontSize, fontName, fixedFontName, symbolicFontName;
@dynamic shadeColor, transitionDuration;
@dynamic soundFx, voice, vibration, visualFx;
@dynamic tracks, trackNames, currentTrack, playingTrack;

#pragma mark Internal

- (id)init {

    if(!(self = [super init]))
        return self;

    _gameRandomSeeds = 0;
    _gameRandomCounters = 0;
    [self setGameRandomSeed:arc4random()];

    self.defaults = [NSUserDefaults standardUserDefaults];
    [self.defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                     @"",                                                           NSStringFromSelector(@selector(build)),
                                     @"",                                                           NSStringFromSelector(@selector(version)),
                                     @"",                                                           NSStringFromSelector(@selector(copyright)),
                                     [NSNumber numberWithBool:YES],                                 NSStringFromSelector(@selector(firstRun)),

                                     [NSNumber numberWithInt:
                                      [[PearlStrings get].fontSizeNormal intValue]],                NSStringFromSelector(@selector(fontSize)),
                                     [NSNumber numberWithInt:
                                      [[PearlStrings get].fontSizeLarge intValue]],                 NSStringFromSelector(@selector(largeFontSize)),
                                     [NSNumber numberWithInt:
                                      [[PearlStrings get].fontSizeSmall intValue]],                 NSStringFromSelector(@selector(smallFontSize)),
                                     [PearlStrings get].fontFamilyDefault,                          NSStringFromSelector(@selector(fontName)),
                                     [PearlStrings get].fontFamilyFixed,                            NSStringFromSelector(@selector(fixedFontName)),
                                     [PearlStrings get].fontFamilySymbolic,                         NSStringFromSelector(@selector(symbolicFontName)),

                                     [NSNumber numberWithLong:       0x332222cc],                   NSStringFromSelector(@selector(shadeColor)),
                                     [NSNumber numberWithFloat:      0.4f],                         NSStringFromSelector(@selector(transitionDuration)),

                                     [NSNumber numberWithBool:       YES],                          NSStringFromSelector(@selector(soundFx)),
                                     [NSNumber numberWithBool:       NO],                           NSStringFromSelector(@selector(voice)),
                                     [NSNumber numberWithBool:       YES],                          NSStringFromSelector(@selector(vibration)),
                                     [NSNumber numberWithBool:       YES],                          NSStringFromSelector(@selector(visualFx)),

                                     [NSArray arrayWithObjects:
                                      @"sequential",
                                      @"random",
                                      @"",
                                      nil],                                                         NSStringFromSelector(@selector(tracks)),
                                     [NSArray arrayWithObjects:
                                      [PearlStrings get].songSequential,
                                      [PearlStrings get].songRandom,
                                      [PearlStrings get].songOff,
                                      nil],                                                         NSStringFromSelector(@selector(trackNames)),
                                     @"sequential",                                                 NSStringFromSelector(@selector(currentTrack)),

                                     nil]];

    self.resetTriggers = [NSMutableDictionary dictionary];
    
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    self.build = [info objectForKey:@"CFBundleVersion"];
    self.version = [info objectForKey:@"CFBundleShortVersionString"];
    self.copyright = [info objectForKey:@"NSHumanReadableCopyright"];

    return self;
}


- (void)dealloc {

    self.defaults = nil;

    self.firstRun = nil;
    self.fontSize = nil;
    self.largeFontSize = nil;
    self.smallFontSize = nil;
    self.fontName = nil;
    self.fixedFontName = nil;
    self.symbolicFontName = nil;
    self.shadeColor = nil;
    self.transitionDuration = nil;
    self.tracks = nil;
    self.trackNames = nil;
    self.currentTrack = nil;
    self.soundFx = nil;
    self.music = nil;
    self.voice = nil;
    self.vibration = nil;
    self.visualFx = nil;
    self.resetTriggers = nil;

    [super dealloc];
}


+ (PearlConfig *)get {

    static PearlConfig *instance = nil;
    if(!instance)
        instance = [self new];

    return instance;
}

+ (void)flush {
    
    [[self get].defaults synchronize];
}


- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {

    if ([NSStringFromSelector(aSelector) isSetter])
        return [NSMethodSignature signatureWithObjCTypes:"v@:@"];

    return [NSMethodSignature signatureWithObjCTypes:"@@:"];
}


- (void)forwardInvocation:(NSInvocation *)anInvocation {

    NSString *selector = NSStringFromSelector(anInvocation.selector);
    BOOL isSetter = [selector isSetter];
    selector = [selector setterToGetter];

    id currentValue = [self.defaults valueForKey:selector];
    if ([currentValue isKindOfClass:[NSData class]]) {
        trc(@"Unarchiving %@.%@", [self class], selector);
        currentValue = [NSKeyedUnarchiver unarchiveObjectWithData:currentValue];
    }

    if (isSetter) {
        id newValue = nil;
        [anInvocation getArgument:&newValue atIndex:2];
        newValue = NSNullToNil(newValue);
        dbg(@"%@.%@ = [%@ ->] %@", [self class], selector, currentValue, newValue);

        if (newValue && ![newValue isKindOfClass:[NSString class]] && ![newValue isKindOfClass:[NSNumber class]] && ![newValue isKindOfClass:[NSDate class]] && ![newValue isKindOfClass:[NSArray class]] && ![newValue isKindOfClass:[NSDictionary class]]) {
            // TODO: This doesn't yet check arrays and dictionaries recursively to see if they need coding.
            if ([newValue conformsToProtocol:@protocol(NSCoding)]) {
                trc(@"Archiving %@.%@", [self class], selector);
                newValue = [NSKeyedArchiver archivedDataWithRootObject:newValue];
            } else
                err(@"Cannot update %@: Value type is not supported by plists and is not codable: %@", selector, newValue);
        }
        [self.defaults setValue:newValue forKey:selector];

        [[PearlAppDelegate get] didUpdateConfigForKey:NSSelectorFromString(selector) fromValue:currentValue];
        NSString *resetTriggerKey = [self.resetTriggers objectForKey:selector];
        if (resetTriggerKey)
            [(id<PearlResettable>) [[PearlAppDelegate get] valueForKeyPath:resetTriggerKey] reset];
    }

    else
        [anInvocation setReturnValue:&currentValue];
}


#pragma mark Audio

- (NSString *)firstTrack {

    if ([self.tracks count] <= 3)
        return @"";

    return [self.tracks objectAtIndex:0];
}
- (NSString *)randomTrack {

    if ([self.tracks count] <= 3)
        return @"";

    NSUInteger realTracks = ([self.tracks count] - 3);
    return [self.tracks objectAtIndex:arc4random() % realTracks];
}
- (NSString *)nextTrack {

    if ([self.tracks count] <= 3)
        return @"";

    id playingTrack = self.playingTrack;
    if(!playingTrack)
        playingTrack = @"";

    NSUInteger currentTrackIndex = [[self tracks] indexOfObject:playingTrack];
    if (currentTrackIndex == NSNotFound)
        currentTrackIndex = -1;

    NSUInteger realTracks = [self.tracks count] - 3;
    return [self.tracks objectAtIndex:MIN(currentTrackIndex + 1, realTracks) % realTracks];
}
- (NSNumber *)music {

    return [NSNumber numberWithBool:[self.currentTrack length] > 0];
}
- (void)setMusic:(NSNumber *)aMusic {

#ifdef PEARL_MEDIA
    if ([aMusic boolValue] && ![self.music boolValue])
        [[PearlAudioController get] playTrack:@"random"];
    if (![aMusic boolValue] && [self.music boolValue])
        [[PearlAudioController get] playTrack:nil];
#endif
}
- (void)setCurrentTrack: (NSString *)currentTrack {

    if(currentTrack == nil)
        currentTrack = @"";

    NSString *oldTrack = [self.defaults objectForKey:NSStringFromSelector(@selector(currentTrack))];
    [self.defaults setObject:currentTrack forKey:NSStringFromSelector(@selector(currentTrack))];

    [[PearlAppDelegate get] didUpdateConfigForKey:@selector(currentTrack) fromValue:oldTrack];
}
-(NSString *) currentTrackName {

    id currentTrack = self.currentTrack;
    if(!currentTrack)
        currentTrack = @"";

    NSUInteger currentTrackIndex = [[self tracks] indexOfObject:currentTrack];
    return [[self trackNames] objectAtIndex:currentTrackIndex];
}
-(NSString *) playingTrackName {

    id playingTrack = self.playingTrack;
    if(!playingTrack)
        playingTrack = @"";

    NSUInteger playingTrackIndex = [[self tracks] indexOfObject:playingTrack];
    if (playingTrackIndex == NSNotFound || ![[[self tracks] objectAtIndex:playingTrackIndex] length])
        return nil;

    return [[self trackNames] objectAtIndex:playingTrackIndex];
}


#pragma mark Game Configuration

- (void)setGameRandomSeed:(NSUInteger)aSeed {

    @synchronized(self) {
        srandom(aSeed);
        free(_gameRandomSeeds);
        free(_gameRandomCounters);
        _gameRandomSeeds            = malloc(sizeof(NSUInteger) * PearlMaxGameRandom);
        _gameRandomCounters         = malloc(sizeof(NSUInteger) * PearlMaxGameRandom);
        for (NSUInteger s = 0; s < PearlMaxGameRandom; ++s){
            _gameRandomSeeds[s]     = (NSUInteger) random();
            _gameRandomCounters[s]  = 0;
        }
    }
}

- (NSUInteger)gameRandom {

    return [self gameRandom:PearlMaxGameRandom - 1];
}

- (NSUInteger)gameRandom:(NSUInteger)scope {

    NSAssert2(scope < PearlMaxGameRandom, @"Scope (%d) must be < %d", scope, PearlMaxGameRandom);

    @synchronized(self) {
        srandom(_gameRandomSeeds[scope]++);
        return random();
    }
}

- (NSUInteger)gameRandom:(NSUInteger)scope from:(char*)file :(NSUInteger)line {

    NSUInteger gr = [self gameRandom:scope];
//    if (scope == cMaxGameScope - 1 && _gameRandomSeeds[scope] % 5 == 0)
//        [[Logger get] dbg:@"%30s:%-5d\t" @"gameRandom(scope=%d, #%d)=%d", file, line, scope, ++_gameRandomCounters[scope], gr];

    return gr;
}


-(NSDate *) today {

    long now = (long) [[NSDate date] timeIntervalSince1970];
    return [NSDate dateWithTimeIntervalSince1970:(now / (3600 * 24)) * (3600 * 24)];
}


@end