//
//  OAOsmMapUtils.h
//  OsmAnd
//
//  Created by Paul on 1/23/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/osm/edit/OsmMapUtils.java
//  git revision 56bc3a14c2492638d540350b8904ce0181659006

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@class OAWay, OANode;

@interface OAOsmMapUtils : NSObject

+(CLLocationCoordinate2D)getWeightCenterForWay:(OAWay *)way;

+ (void)simplifyDouglasPeucker:(NSArray<OANode *> *)nodes
                         start:(NSInteger)start
                           end:(NSInteger)end
                        result:(NSMutableArray<OANode *> *)result
                       epsilon:(double)epsilon;
@end

NS_ASSUME_NONNULL_END
