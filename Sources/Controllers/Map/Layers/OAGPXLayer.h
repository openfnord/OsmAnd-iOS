//
//  OAGPXLayer.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OABaseVectorLinesLayer.h"
#import "OAContextMenuProvider.h"

#include <OsmAndCore/Map/VectorLinesCollection.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>

#define kCurrentTrack @"current_track"

@class OASGpxFile;

@interface OAGPXLayer : OABaseVectorLinesLayer<OAContextMenuProvider, OAMoveObjectProvider>

//@property (nonatomic) QHash< QString, std::shared_ptr<const OsmAnd::GpxDocument> > gpxDocs;

@property (nonatomic) std::shared_ptr<OsmAnd::VectorLinesCollection> linesCollection;

- (void)refreshGpxTracks:(NSDictionary<NSString *, OASGpxFile *> *)gpxDocs reset:(BOOL)reset;
- (void)refreshGpxWaypoints;
- (CGFloat)getLineWidth:(NSString *)gpxWidth;
- (void)updateCachedGpxItem:(NSString *)filePath;

@end
