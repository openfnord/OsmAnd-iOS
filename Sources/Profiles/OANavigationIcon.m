//
//  OANavigationIcon.m
//  OsmAnd
//
//  Created by Alexey on 29.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OANavigationIcon.h"
#import "OAUtilities.h"
#import "OAAppSettings.h"
#import "OAIndexConstants.h"
#import "OsmAndApp.h"
#import "OsmAnd_Maps-Swift.h"

@interface OANavigationIcon()

@property (nonatomic) NSString *iconName;

@end

@implementation OANavigationIcon

+ (instancetype) withIconName:(NSString *)iconName
{
    OANavigationIcon *obj = [[OANavigationIcon alloc] init];
    if (obj)
    {
        NSString *migratedOldValue = [self getMigratedValue:iconName];
        obj.iconName = migratedOldValue ?: iconName;
        obj.iconName = [self changeNameFor3dMode:obj.iconName];
    }

    return obj;
}

+ (NSString *) getMigratedValue:(id)value
{
    if ([value isKindOfClass:NSNumber.class])
    {
        NSNumber *oldEnumValue = value;
        if (oldEnumValue.intValue == 0)
            return NAVIGATION_ICON_DEFAULT;
        else if (oldEnumValue.intValue == 1)
            return NAVIGATION_ICON_NAUTICAL;
        else if (oldEnumValue.intValue == 2)
            return NAVIGATION_ICON_CAR;
    }
    return nil;
}

+ (NSString *) changeNameFor3dMode:(NSString *)savedIconName
{
    if (OAAppSettings.sharedManager.use3dIconsByDefault.get)
    {
        if ([savedIconName isEqualToString:NAVIGATION_ICON_DEFAULT])
            return NAVIGATION_MODEL_ICON_DEFAULT;
        else if ([savedIconName isEqualToString:NAVIGATION_ICON_NAUTICAL])
            return NAVIGATION_MODEL_ICON_NAUTICAL;
        else if ([savedIconName isEqualToString:NAVIGATION_ICON_CAR])
            return NAVIGATION_MODEL_ICON_CAR;
    }
    else
    {
        if ([savedIconName isEqualToString:NAVIGATION_MODEL_ICON_DEFAULT])
            return NAVIGATION_ICON_DEFAULT;
        else if ([savedIconName isEqualToString:NAVIGATION_MODEL_ICON_NAUTICAL])
            return NAVIGATION_ICON_NAUTICAL;
        else if ([savedIconName isEqualToString:NAVIGATION_MODEL_ICON_CAR])
            return NAVIGATION_ICON_CAR;
    }
    return savedIconName;
}

- (NSString *) iconName
{
    return _iconName;
}

- (UIImage *) iconWithColor:(UIColor *)color
{
    return [self.class getIcon:_iconName color:color];
}

- (UIImage *) getMapIcon:(UIColor *)color
{
    return [self.class getIcon:_iconName color:color scaleFactor:[[OAAppSettings sharedManager].textSize get]];
}

+ (UIImage *) getIcon:(NSString *)iconName color:(UIColor *)color
{
    return [self getIcon:iconName color:color scaleFactor:1.0];
}

+ (UIImage *) getIcon:(NSString *)iconName color:(UIColor *)color scaleFactor:(CGFloat)currentScaleFactor
{
    UIImage *bottomImage;
    UIImage *centerImage;
    UIImage *topImage;
    if ([iconName isEqualToString:NAVIGATION_ICON_DEFAULT])
    {
        bottomImage = [UIImage imageNamed:@"map_navigation_default_bottom"];
        centerImage = [UIImage imageNamed:@"map_navigation_default_center"];
        topImage = [UIImage imageNamed:@"map_navigation_default_top"];
    }
    else if ([iconName isEqualToString:NAVIGATION_ICON_NAUTICAL])
    {
        bottomImage = [UIImage imageNamed:@"map_navigation_nautical_bottom"];
        centerImage = [UIImage imageNamed:@"map_navigation_nautical_center"];
        topImage = [UIImage imageNamed:@"map_navigation_nautical_top"];
    }
    else if ([iconName isEqualToString:NAVIGATION_ICON_CAR])
    {
        bottomImage = [UIImage imageNamed:@"map_navigation_car_bottom"];
        centerImage = [UIImage imageNamed:@"map_navigation_car_center"];
        topImage = [UIImage imageNamed:@"map_navigation_car_top"];
    }
    else if ([self isModel:iconName])
    {
        bottomImage = [UIImage imageNamed:@"map_navigation_default_bottom"];
        centerImage = [UIImage imageNamed:@"map_navigation_default_center"];
        topImage = [UIImage imageNamed:@"map_navigation_default_top"];
    }
    return [OAUtilities layeredImageWithColor:color bottom:bottomImage center:centerImage top:topImage scaleFactor:currentScaleFactor];
}

+ (UIImage *) getPreviewIcon:(NSString *)iconName color:(UIColor *)color
{
    UIImage *modelPreview = [self getModelPreviewDrawable:iconName];
    if (modelPreview)
        return modelPreview;
    return [self getIcon:iconName color:color scaleFactor:1];
}

+ (UIImage *) getModelPreviewDrawable:(NSString *)iconName
{
    if ([self isModel:iconName])
    {
        NSDictionary<NSString *, NSString *> *dirs = [Model3dHelper listModelsWithNames];
        
        NSString *shortIconName = [iconName substringFromIndex:MODEL_NAME_PREFIX.length];
        NSString *modelDirPath = dirs[[MODEL_NAME_PREFIX stringByAppendingString:shortIconName]];
        NSString *iconFilePath = [Model3dHelper getModelIconFilePathWithDirPath:modelDirPath];
        if ([NSFileManager.defaultManager fileExistsAtPath:iconFilePath])
        {
            return [UIImage imageNamed:iconFilePath];
        }
    }
    return nil;
}

+ (BOOL) isModel:(NSString *)iconName
{
    return [iconName hasPrefix:MODEL_NAME_PREFIX];
}

- (BOOL) isModel
{
    return [self.class isModel:_iconName];
}

@end
