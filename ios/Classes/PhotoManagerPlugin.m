#import "PhotoManagerPlugin.h"
#include <Foundation/Foundation.h>
#import "PMPlugin.h"
#import <FirebaseCrashlytics/FirebaseCrashlytics.h>

@implementation PhotoManagerPlugin {
}

@synthesize plugin;
@synthesize registrar;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    PhotoManagerPlugin* photoManagerPlugin = [[PhotoManagerPlugin alloc] init];
    photoManagerPlugin.plugin = [[PMPlugin alloc] init];

    photoManagerPlugin.registrar = registrar;
    [photoManagerPlugin.plugin registerPlugin:registrar];
    [registrar addApplicationDelegate:photoManagerPlugin.plugin];
}

@end
