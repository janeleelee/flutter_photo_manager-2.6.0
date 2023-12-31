#import <Foundation/Foundation.h>
#import "PMImport.h"

@protocol FlutterPluginRegistrar;

@interface PMNotificationManager : NSObject
@property(nonatomic, strong) NSObject <FlutterPluginRegistrar> *registrar;
- (instancetype)initWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar;
- (void)detachFromEngine;
- (void)startNotify;
- (void)stopNotify;
+ (instancetype)managerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar;
- (BOOL)isNotifying;

@end
