//
//  OAOsmEditsLayer.m
//  OsmAnd
//
//  Created by Paul on 17/01/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmEditsLayer.h"
#import "OADefaultFavorite.h"
#import "OAFavoriteItem.h"
#import "OANativeUtilities.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OATargetPoint.h"
#import "OAUtilities.h"
#import "OpenstreetmapsDbHelper.h"
#import "OAOpenStreetMapPoint.h"
#import "OAOsmEditingPlugin.h"
#import "OAOsmBugsDBHelper.h"
#import "OAEntity.h"
#import "OAPOI.h"
#import "OAPOIType.h"
#import "OAPlugin.h"
#import "OAOsmNotesPoint.h"
#import "OAOpenStreetMapPoint.h"
#import "OAPOIHelper.h"
#import "OAAutoObserverProxy.h"
#import "OAEditPOIData.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/FavoriteLocationsPresenter.h>

@implementation OAOsmEditsLayer
{
    std::shared_ptr<OsmAnd::MapMarkersCollection> _osmEditsCollection;
    OAOsmEditingPlugin *_plugin;
    
    OAAutoObserverProxy *_editsChangedObserver;
}

- (instancetype) initWithMapViewController:(OAMapViewController *)mapViewController baseOrder:(int)baseOrder
{
    self = [super initWithMapViewController:mapViewController baseOrder:baseOrder];
    if (self) {
        _plugin = (OAOsmEditingPlugin *) [OAPlugin getPlugin:OAOsmEditingPlugin.class];
    }
    return self;
}

- (NSString *) layerId
{
    return kOsmEditsLayerId;
}

- (void) initLayer
{
    [super initLayer];
    
    _editsChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                       withHandler:@selector(onEditsCollectionChanged)
                                                       andObserve:self.app.osmEditsChangeObservable];
    
    BOOL shouldShow = [_plugin isActive] && [[OAAppSettings sharedManager].mapSettingShowOfflineEdits get];
    
    [self refreshOsmEditsCollection];
    [self.app.data.mapLayersConfiguration setLayer:self.layerId
                                        Visibility:shouldShow];
}

- (BOOL)isVisible
{
    return [_plugin isActive] && [[OAAppSettings sharedManager].mapSettingShowOfflineEdits get];
}

- (void) deinitLayer
{
    [super deinitLayer];
}

- (std::shared_ptr<OsmAnd::MapMarkersCollection>) getOsmEditsCollection
{
    return _osmEditsCollection;
}

- (void) refreshOsmEditsCollection
{
    _osmEditsCollection.reset(new OsmAnd::MapMarkersCollection());
    NSArray * data = [self getAllPoints];
    for (OAOsmPoint *point in data)
    {
        OsmAnd::MapMarkerBuilder()
        .setIsAccuracyCircleSupported(false)
        .setBaseOrder(self.baseOrder)
        .setIsHidden(false)
        .setPinIcon([OANativeUtilities skBitmapFromPngResource:@"map_osm_edit"])
        .setPosition(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon([point getLatitude], [point getLongitude])))
        .setPinIconVerticalAlignment(OsmAnd::MapMarker::CenterVertical)
        .setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal)
        .buildAndAddToCollection(_osmEditsCollection);
    }
}

- (void) show
{
    [self.mapViewController runWithRenderSync:^{
        [self.mapView addKeyedSymbolsProvider:_osmEditsCollection];
    }];
}

- (void) hide
{
    [self.mapViewController runWithRenderSync:^{
        [self.mapView removeKeyedSymbolsProvider:_osmEditsCollection];
    }];
}

- (void) onEditsCollectionChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hide];
        [self refreshOsmEditsCollection];
        [self show];
    });
}

#pragma mark - OAContextMenuProvider

- (OATargetPoint *)getTargetPointFromPoint:(OAOsmPoint *)point {
    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    targetPoint.location = CLLocationCoordinate2DMake(point.getLatitude, point.getLongitude);
    NSString *title = point.getName;
    targetPoint.title = title.length == 0 ? [NSString stringWithFormat:@"%@ • %@", point.getLocalizedAction, [OAOsmEditingPlugin getCategory:point]] : title;
    
    targetPoint.values = point.getTags;
    targetPoint.icon = [self getUIImageForPoint:point];
    
    targetPoint.type = point.getGroup == POI ? OATargetOsmEdit : OATargetOsmNote;
    
    targetPoint.targetObj = point;
    
    targetPoint.sortIndex = (NSInteger)targetPoint.type;
    return targetPoint;
}

-(UIImage *)getUIImageForPoint:(OAOsmPoint *)point
{
    if (point.getGroup == POI)
    {
        OAOpenStreetMapPoint *osmP = (OAOpenStreetMapPoint *) point;
        NSString *poiTranslation = [osmP.getEntity getTagFromString:POI_TYPE_TAG];
        
        if (poiTranslation)
        {
            OAPOIHelper *poiHelper = [OAPOIHelper sharedInstance];
            NSDictionary *translatedNames = [poiHelper getAllTranslatedNames:NO];
            OAPOIType *poiType = translatedNames[[poiTranslation lowerCase]];
            if (poiType)
                return poiType.icon;
        }
    }
    
    return [UIImage imageNamed:@"map_osm_edit"];
}

- (OATargetPoint *) getTargetPoint:(id)obj
{
    if ([obj isKindOfClass:OAOsmPoint.class])
        return [self getTargetPointFromPoint:(OAOsmPoint *)obj];
    return nil;
}

- (OATargetPoint *) getTargetPointCpp:(const void *)obj
{
    return nil;
}

- (NSArray *)getAllPoints {
    NSMutableArray *data = [NSMutableArray new];
    [data addObjectsFromArray:[[OpenstreetmapsDbHelper sharedDatabase] getOpenstreetmapPoints]];
    [data addObjectsFromArray:[[OAOsmBugsDBHelper sharedDatabase] getOsmbugsPoints]];
    return [NSArray arrayWithArray:data];
}

- (void) collectObjectsFromPoint:(CLLocationCoordinate2D)point touchPoint:(CGPoint)touchPoint symbolInfo:(const OsmAnd::IMapRenderer::MapSymbolInformation *)symbolInfo found:(NSMutableArray<OATargetPoint *> *)found unknownLocation:(BOOL)unknownLocation
{
    if (![[OAAppSettings sharedManager].mapSettingShowOfflineEdits get])
        return;
    for (const auto& edit : _osmEditsCollection->getMarkers())
    {
        double lat = OsmAnd::Utilities::get31LatitudeY(edit->getPosition().y);
        double lon = OsmAnd::Utilities::get31LongitudeX(edit->getPosition().x);
        NSArray * data = [self getAllPoints];
        for (OAOsmPoint *osmPoint in data)
        {
            double pointLat = osmPoint.getLatitude;
            double pointLon = osmPoint.getLongitude;
            if ([OAUtilities isCoordEqual:pointLat srcLon:pointLon destLat:lat destLon:lon])
            {
                if (OsmAnd::Utilities::distance(pointLon, pointLat, point.longitude, point.latitude) < 15) {
                    OATargetPoint *targetPoint = [self getTargetPoint:osmPoint];
                    if (![found containsObject:targetPoint])
                        [found addObject:targetPoint];
                }
            }
        }
    }
}

#pragma mark - OAMoveObjectProvider

- (BOOL)isObjectMovable:(id)object
{
    return [object isKindOfClass:OAOsmPoint.class];
}

- (void)applyNewObjectPosition:(id)object position:(CLLocationCoordinate2D)position
{
    if (object && [self isObjectMovable:object])
    {
        OAOsmPoint *p = (OAOsmPoint *)object;
        if ([p isKindOfClass:OAOpenStreetMapPoint.class])
        {
            OAOpenStreetMapPoint *point = (OAOpenStreetMapPoint *)p;
            [[OpenstreetmapsDbHelper sharedDatabase] updateEditLocation:point.getId newPosition:position];
        }
        else if ([p isKindOfClass:OAOsmNotesPoint.class])
        {
            OAOsmNotesPoint *point = (OAOsmNotesPoint *) p;
            [[OAOsmBugsDBHelper sharedDatabase] updateOsmBugLocation:point.getId newPosition:position];
        }
        [self.app.osmEditsChangeObservable notifyEvent];
    }
}

- (UIImage *) getPointIcon:(id)object
{
    return [UIImage imageNamed:@"map_osm_edit"];
}

- (void)setPointVisibility:(id)object hidden:(BOOL)hidden
{
    if (object && [self isObjectMovable:object])
    {
        OAOsmPoint *p = (OAOsmPoint *)object;
        const auto& pos = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon([p getLatitude], [p getLongitude]));
        for (const auto& marker : _osmEditsCollection->getMarkers())
        {
            if (pos == marker->getPosition())
            {
                marker->setIsHidden(hidden);
            }
        }
    }
}

- (EOAPinVerticalAlignment) getPointIconVerticalAlignment
{
    return EOAPinAlignmentCenterVertical;
}


- (EOAPinHorizontalAlignment) getPointIconHorizontalAlignment
{
    return EOAPinAlignmentCenterHorizontal;
}

@end
