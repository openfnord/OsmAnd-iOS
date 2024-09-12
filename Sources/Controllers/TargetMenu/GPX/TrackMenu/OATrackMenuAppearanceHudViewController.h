//
//  OATrackMenuAppearanceHudViewController.h
//  OsmAnd
//
//  Created by Skalii on 25.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseTrackMenuHudViewController.h"
#import "OsmAndSharedWrapper.h"

@class OATrackMenuViewControllerState, OAColoringType;

@interface OATrackAppearanceItem : NSObject

@property (nonatomic) OAColoringType *coloringType;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *attrName;
@property (nonatomic, assign) BOOL isAvailable;
@property (nonatomic, assign) BOOL isEnabled;

- (instancetype)initWithColoringType:(OAColoringType *)coloringType
                               title:(NSString *)title
                            attrName:(NSString *)attrName
                         isAvailable:(BOOL)isAvailable
                           isEnabled:(BOOL)isEnabled;

@end

@interface OATrackMenuAppearanceHudViewController : OABaseTrackMenuHudViewController

- (instancetype)initWithGpx:(OASGpxDataItem *)gpx state:(OATrackMenuViewControllerState *)state;
- (instancetype)initWithGpx:(OASGpxDataItem *)gpx tracks:(NSArray<OASGpxDataItem *> *)tracks state:(OATrackMenuViewControllerState *)state;

@end
