#import "PMNotificationManager.h"
#include <objc/objc.h>
#import "PMConvertUtils.h"
#import "core/PMLogUtils.h"
#import <FirebaseCrashlytics/FirebaseCrashlytics.h>

@interface PMNotificationManager () <PHPhotoLibraryChangeObserver>
@end

@implementation PMNotificationManager {
    FlutterMethodChannel *channel;
    BOOL _notifying;
    PHFetchResult<PHAsset *> *result;
    volatile BOOL isDetach;
}

- (instancetype)initWithRegistrar:
(NSObject<FlutterPluginRegistrar> *)registrar {
    self = [super init];
    if (self) {
        self.registrar = registrar;
        channel = [FlutterMethodChannel
                   methodChannelWithName:@"com.fluttercandies/photo_manager/notify"
                   binaryMessenger:[registrar messenger]];
        _notifying = NO;
    }

    isDetach = NO;
    
    return self;
}

- (void)detachFromEngine {
    NSString *thread = [NSString stringWithFormat:@"detachFromEngine %@", [NSThread currentThread]];
    [[FIRCrashlytics crashlytics] log: thread];
    isDetach = YES;
    if (_notifying) {
        [self stopNotify];
    }
    [channel setMethodCallHandler:nil];
}

+ (instancetype)managerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    return [[self alloc] initWithRegistrar:registrar];
}

- (void)startNotify {
    if (isDetach) {
        return;
    }

    PHPhotoLibrary *library = PHPhotoLibrary.sharedPhotoLibrary;
    [library registerChangeObserver:self];
    _notifying = YES;
    [self refreshFetchResult];
}

- (void)stopNotify {
    PHPhotoLibrary *library = PHPhotoLibrary.sharedPhotoLibrary;
    [library unregisterChangeObserver:self];
    _notifying = NO;
}

#pragma "photo library notify"

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    [[FIRCrashlytics crashlytics] log: [NSString stringWithFormat:@"photoLibraryDidChange %@", [NSThread currentThread]]];

    if (!result || isDetach) {
        [[FIRCrashlytics crashlytics] log: [NSString stringWithFormat:@"photoLibraryDidChange is detach %@", [NSThread currentThread]]];
        return;
    }
    PHFetchResultChangeDetails *details = [changeInstance changeDetailsForFetchResult:result];
    NSUInteger oldCount = result.count;
    [self refreshFetchResult];
    if (!result) {
        return;
    }
    NSUInteger newCount = result.count;
    NSMutableDictionary *detailResult = [self convertChangeDetailsToNotifyDetail:details];
    detailResult[@"oldCount"] = @(oldCount);
    detailResult[@"newCount"] = @(newCount);
    
    [PMLogUtils.sharedInstance
     info:[NSString stringWithFormat:@"on change result = %@", detailResult]];

    if (isDetach) {
        [[FIRCrashlytics crashlytics] log: [NSString stringWithFormat:@"photoLibraryDidChange is detach before calling invoke method %@", [NSThread currentThread]]];
        return;
    }

    [[FIRCrashlytics crashlytics] log: [NSString stringWithFormat:@"photoLibraryDidChange call invoke method %@", [NSThread currentThread]]];
    [channel invokeMethod:@"change" arguments:detailResult];
}

- (void)refreshFetchResult {
    if (isDetach) {
        return;
    }
    
    result = [self getLastAssets];
}

- (NSMutableDictionary *)convertChangeDetailsToNotifyDetail:(PHFetchResultChangeDetails *)details {
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    NSArray<PHObject *> *changedObjects = details.changedObjects;
    NSArray<PHObject *> *insertedObjects = details.insertedObjects;
    NSArray<PHObject *> *removedObjects = details.removedObjects;
    
    [self addToResult:dictionary key:@"update" objects:changedObjects];
    [self addToResult:dictionary key:@"create" objects:insertedObjects];
    [self addToResult:dictionary key:@"delete" objects:removedObjects];
    
    return dictionary;
}

- (void)addToResult:(NSMutableDictionary *)dictionary
                key:(NSString *)key
            objects:(NSArray<PHObject *> *)changedObjects {
    NSMutableArray *items = [NSMutableArray new];
    
    for (PHObject *object in changedObjects) {
        if ([object isMemberOfClass:PHAsset.class]) {
            PHAsset *asset = (PHAsset *)object;
            NSMutableDictionary *itemDict = [NSMutableDictionary new];
            PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection
                                                               fetchAssetCollectionsContainingAsset:asset
                                                               withType:PHAssetCollectionTypeAlbum
                                                               options:nil];
            itemDict[@"id"] = object.localIdentifier;
            NSMutableArray *collectionArray = [NSMutableArray new];
            for (PHAssetCollection *collection in collections) {
                NSDictionary *collectionDict = @{
                    @"id" : collection.localIdentifier,
                    @"title" : collection.localizedTitle
                };
                [collectionArray addObject:collectionDict];
            }
            [items addObject:itemDict];
        }
    }
    
    dictionary[key] = items;
}

- (PHFetchResult<PHAsset *> *)getLastAssets {
#if __IPHONE_14_0
    if (@available(iOS 14, *)) {
        if (PHPhotoLibrary.authorizationStatus == PHAuthorizationStatusLimited) {
            return [PHAsset fetchAssetsWithOptions:nil];
        }
    }
#endif
    if (PHPhotoLibrary.authorizationStatus == PHAuthorizationStatusAuthorized) {
        return [PHAsset fetchAssetsWithOptions:nil];
    }
    return nil;
}

- (BOOL)isNotifying {
    return _notifying;
}
@end
