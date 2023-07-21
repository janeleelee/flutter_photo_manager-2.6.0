#import <Photos/Photos.h>
#include <objc/objc.h>
#import "PhotoChangeObserver.h"
#import "core/PMLogUtils.h"

@interface PhotoChangeObserver () <PHPhotoLibraryChangeObserver>
@property(nonatomic, strong) FlutterMethodChannel *handler;
@property(nonatomic, assign) BOOL isInit;
@end

@implementation PhotoChangeObserver {
    volatile BOOL isDetach;
}

- (void)initWithRegister:(NSObject <FlutterPluginRegistrar> *)registrar {
    if (self.isInit) {
        return;
    }
    self.isInit = YES;
    self.handler = [FlutterMethodChannel methodChannelWithName:@"photo_manager/notify" binaryMessenger:[registrar messenger]];
    [PHPhotoLibrary.sharedPhotoLibrary registerChangeObserver:self];

    isDetach = NO;
}

- (void)detachFromEngine {
    isDetach = YES;
    [PHPhotoLibrary.sharedPhotoLibrary unregisterChangeObserver:self];
    [self.handler setMethodCallHandler:nil];
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    if (isDetach) {
        return;
    }
    
    PHAssetCollection *collection = [self getRecentCollection];
    if (!collection) {
        [self.handler invokeMethod:@"change" arguments:@1];
        return;
    }
    
    PHObjectChangeDetails *details = [changeInstance changeDetailsForObject:collection];
    PHObject *object = details.objectAfterChanges;
    [PMLogUtils.sharedInstance info: [NSString stringWithFormat:@"%@, %@", object.localIdentifier, object.class]];
    
    [self.handler invokeMethod:@"change" arguments:@1];
}

- (PHAssetCollection *)getRecentCollection {
    if (PHPhotoLibrary.authorizationStatus == PHAuthorizationStatusAuthorized) {
        PHFetchResult<PHAssetCollection *> *result = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
        
        for (PHAssetCollection *collection in result) {
            if (collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary) {
                return collection;
            }
        }
    }
    return nil;
}
@end
