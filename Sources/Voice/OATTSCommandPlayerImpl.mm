//
//  OATTSCommandPlayerImpl.m
//  OsmAnd
//
//  Created by Paul on 7/10/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#include <JavaScriptCore/JavaScriptCore.h>
#import "OATTSCommandPlayerImpl.h"
#import "OACommandBuilder.h"
#import "OAVoiceRouter.h"
#import "OAAppSettings.h"

@implementation OATTSCommandPlayerImpl {
    AVSpeechSynthesizer *synthesizer;
    OAVoiceRouter *vrt;
    JSContext *context;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        synthesizer = [[AVSpeechSynthesizer alloc] init];
    }
    return self;
}

- (instancetype) initWithVoiceRouter:(OAVoiceRouter *) voiceRouter
{
    self = [super init];
    if (self)
    {
        synthesizer = [[AVSpeechSynthesizer alloc] init];
        vrt = voiceRouter;
        NSLocale *currLocale = [NSLocale currentLocale];
        NSString *resourceName = [NSString stringWithFormat:@"%@%@", currLocale.languageCode, @"_tts"];
        NSString *jsPath = [[NSBundle mainBundle] pathForResource:resourceName ofType:@"js"];
        if (jsPath == nil) {
            return nil;
        }
        context = [[JSContext alloc] init];
        NSString *scriptString = [NSString stringWithContentsOfFile:jsPath encoding:NSUTF8StringEncoding error:nil];
        [context evaluateScript:scriptString];
    }
    return self;
}

- (void)playCommands:(OACommandBuilder *)builder
{
    if ([vrt isMute]) {
        return;
    }
    NSMutableString *toSpeak = [[NSMutableString alloc] init];
    NSArray<NSString *> *uterrances = [builder getUtterances];
    for (NSString *utterance in uterrances) {
        [toSpeak appendString:utterance];
    }
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:toSpeak];
//    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"hu-HU"];
    [utterance setRate:0.5f];
    [synthesizer speakUtterance:utterance];
}

- (OACommandBuilder *)newCommandBuilder {
    OACommandBuilder *commandBuilder = [[OACommandBuilder alloc] initWithCommandPlayer:self jsContext:context];
    OAAppSettings *settings = [OAAppSettings sharedManager];
    [commandBuilder setParameters:[OAMetricsConstant toTTSString:settings.metricSystem] mode:YES];
    return commandBuilder;
}

@end
