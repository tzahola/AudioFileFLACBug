//
//  AppDelegate.m
//  AudioFileFLACBug
//
//  Created by Tamás Zahola on 2018. 02. 07..
//  Copyright © 2018. Tamás Zahola. All rights reserved.
//

#import "AppDelegate.h"

#import <AudioToolbox/AudioToolbox.h>

static inline void check(OSStatus status) {
    NSCAssert(status == noErr, @"Error: %lld", (long long)status);
}

@interface AppDelegate ()
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    NSURL* bigFileURL = [NSBundle.mainBundle URLForResource:@"big" withExtension:@"flac"];
    
    AudioFileID audioFile;
    check(AudioFileOpenURL((__bridge CFURLRef)bigFileURL, kAudioFileReadPermission, kAudioFileFLACType, &audioFile));
    
    AudioStreamBasicDescription asbd;
    {
        UInt32 size = sizeof(asbd);
        check(AudioFileGetProperty(audioFile, kAudioFilePropertyDataFormat, &size, &asbd));
        assert(size == sizeof(asbd));
    }
    
    AudioFilePacketTableInfo packetTableInfo;
    {
        UInt32 size = sizeof(packetTableInfo);
        check(AudioFileGetProperty(audioFile, kAudioFilePropertyPacketTableInfo, &size, &packetTableInfo));
        assert(size == sizeof(packetTableInfo));
    }
    
    UInt32 packetSizeUpperBound;
    {
        UInt32 size = sizeof(packetSizeUpperBound);
        check(AudioFileGetProperty(audioFile, kAudioFilePropertyPacketSizeUpperBound, &size, &packetSizeUpperBound));
        assert(size == sizeof(packetSizeUpperBound));
    }
    
    const int maxPacketCount = 2;
    const size_t bufferSize = packetSizeUpperBound * maxPacketCount;
    void* buffer = malloc(bufferSize);
    AudioStreamPacketDescription* packets = malloc(sizeof(*packets) * maxPacketCount);
    
    UInt64 totalFrames = packetTableInfo.mPrimingFrames + packetTableInfo.mNumberValidFrames + packetTableInfo.mRemainderFrames;
    UInt32 framesRead = 0;
    SInt64 currentPacket = 0;
    while (framesRead < totalFrames) {
        UInt32 size = (UInt32)bufferSize;
        UInt32 packetCount = maxPacketCount;
        
        NSTimeInterval time = NSDate.timeIntervalSinceReferenceDate;
        NSLog(@"AudioFileReadPacketData begin: %d packets, %lld bytes", (int)packetCount, (long long)size);
        check(AudioFileReadPacketData(audioFile, true, &size, packets, currentPacket, &packetCount, buffer));
        NSLog(@"AudioFileReadPacketData done : %d packets, %lld bytes, took: %f s", (int)packetCount, (long long)size, NSDate.timeIntervalSinceReferenceDate - time);
        
        currentPacket += packetCount;
        
        if (asbd.mFramesPerPacket != 0) {
            framesRead += asbd.mFramesPerPacket * packetCount;
        } else {
            for (int i = 0; i < packetCount; ++i) {
                framesRead += packets[i].mVariableFramesInPacket;
            }
        }
    }
    assert(framesRead == totalFrames);
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
