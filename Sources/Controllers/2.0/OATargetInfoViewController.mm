//
//  OATargetInfoViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OATargetInfoViewController.h"
#import "OsmAndApp.h"
#import "OAUtilities.h"
#import "OATargetInfoViewCell.h"
#import "OATargetInfoCollapsableViewCell.h"
#import "OATargetInfoCollapsableCoordinatesViewCell.h"
#import "OAWebViewCell.h"
#import "OAEditDescriptionViewController.h"
#import "Localization.h"
#import "OAPOIHelper.h"
#import "OAPOI.h"
#import "OACollapsableNearestPoiWikiView.h"
#import "OATransportStopRoute.h"
#import "OACollapsableTransportStopRoutesView.h"
#import "OACollapsableCardsView.h"
#import "OANoImagesCard.h"
#import "OAMapillaryImageCard.h"
#import "OAMapillaryContributeCard.h"
#import "OAUrlImageCard.h"
#import "Reachability.h"
#import "OAAppSettings.h"
#import "OAPointDescription.h"
#import "OACollapsableCoordinatesView.h"
#import "OAIAPHelper.h"
#import "OAPluginPopupViewController.h"
#import "OAWikiArticleHelper.h"
#import "OAColors.h"
#import "CocoaSecurity.h"
#import "OAPOIFiltersHelper.h"
#import "OAMapUtils.h"

#include <OsmAndCore/Utilities.h>

#define kWikiLink @".wikipedia.org/w"
#define kWhatsAppLink @"https://wa.me/%@"
#define kViberLink @"viber://contact?number=%@"
#define kSkypeLink @"skype:%@"
#define kMailLink @"mailto:%@"
#define kViewPortHtml @"<header><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'></header>"
#define kNearbyPoiMaxCount 10
#define kNearbyPoiMinRadius 250
#define kNearbyPoiMaxRadius 1000
#define kNearbyPoiSearchFactory 2

@implementation OARowInfo

- (instancetype) initWithKey:(NSString *)key icon:(UIImage *)icon textPrefix:(NSString *)textPrefix text:(NSString *)text textColor:(UIColor *)textColor isText:(BOOL)isText needLinks:(BOOL)needLinks order:(int)order typeName:(NSString *)typeName isPhoneNumber:(BOOL)isPhoneNumber isUrl:(BOOL)isUrl
{
    self = [super init];
    if (self)
    {
        _key = key;
        _icon = icon;
        _icon = [_icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _textPrefix = textPrefix;
        _text = text;
        _textColor = textColor;
        _isText = isText;
        _needLinks = needLinks;
        _order = order;
        _typeName = typeName;
        _isPhoneNumber = isPhoneNumber;
        _isUrl = isUrl;
    }
    return self;
}

- (int) height
{
    if (_collapsable && _collapsableView && !_collapsed)
        return _height + _collapsableView.frame.size.height;
    else
        return _height;
}

- (int) getRawHeight
{
    return _height;
}

- (UIFont *) getFont
{
    return [UIFont systemFontOfSize:17.0 weight:_isUrl ? UIFontWeightMedium : UIFontWeightRegular];
}

@end

@interface OATargetInfoViewController() <OACollapsableCardViewDelegate>

@end

@implementation OATargetInfoViewController
{
    NSMutableArray<OARowInfo *> *_rows;
    CGFloat _contentHeight;
    UIColor *_contentColor;
    NSArray<OAPOI *> *_nearestWiki;
    NSArray<OAPOI *> *_nearestPoi;
    BOOL _hasOsmWiki;
    CGFloat _calculatedWidth;
    
    OARowInfo *_nearbyImagesRowInfo;
    BOOL _wikidataCardsReady;
    BOOL _wikimediaCardsReady;
    BOOL _otherCardsReady;
}

- (BOOL) needCoords
{
    return YES;
}

- (BOOL) supportMapInteraction
{
    return YES;
}

- (BOOL) supportsForceClose
{
    return YES;
}

- (BOOL)shouldEnterContextModeManually
{
    return YES;
}

+ (UIImage *) getIcon:(NSString *)fileName
{
    UIImage *img = nil;
    if ([fileName hasPrefix:@"mx_"])
    {
        img = [UIImage imageNamed:[OAUtilities drawablePath:fileName]];
        if (img)
        {
            img = [OAUtilities applyScaleFactorToImage:img];
        }
    }
    else
    {
        img = [UIImage imageNamed:fileName];
    }
    
    return img;
}

- (void) buildTopRows:(NSMutableArray<OARowInfo *> *)rows
{
    if (self.routes.count > 0)
    {
        NSArray<OATransportStopRoute *> *localTransportRoutes = [self getLocalTransportStopRoutes];
        NSArray<OATransportStopRoute *> *nearbyTransportRoutes = [self getNearbyTransportStopRoutes];
        if (localTransportRoutes.count > 0)
        {
            OARowInfo *rowInfo = [[OARowInfo alloc] initWithKey:nil icon:nil textPrefix:nil text:OALocalizedString(@"transport_routes") textColor:nil isText:NO needLinks:NO order:0 typeName:@"" isPhoneNumber:NO isUrl:NO];
            rowInfo.collapsable = YES;
            rowInfo.collapsed = NO;
            rowInfo.collapsableView = [[OACollapsableTransportStopRoutesView alloc] initWithFrame:CGRectMake([OAUtilities getLeftMargin], 0, 320, 100)];
            ((OACollapsableTransportStopRoutesView *)rowInfo.collapsableView).routes = localTransportRoutes;
            [_rows addObject:rowInfo];
        }
        if (nearbyTransportRoutes.count > 0)
        {
            OsmAndAppInstance app = [OsmAndApp instance];
            NSString *routesWithingDistance = [NSString stringWithFormat:@"%@ %@",  OALocalizedString(@"transport_nearby_routes_within"), [app getFormattedDistance:kShowStopsRadiusMeters]];
            OARowInfo *rowInfo = [[OARowInfo alloc] initWithKey:nil icon:nil textPrefix:nil text:routesWithingDistance textColor:nil isText:NO needLinks:NO order:0 typeName:@"" isPhoneNumber:NO isUrl:NO];
            rowInfo.collapsable = YES;
            rowInfo.collapsed = NO;
            rowInfo.collapsableView = [[OACollapsableTransportStopRoutesView alloc] initWithFrame:CGRectMake([OAUtilities getLeftMargin], 0, 320, 100)];
            ((OACollapsableTransportStopRoutesView *)rowInfo.collapsableView).routes = nearbyTransportRoutes;
            [_rows addObject:rowInfo];
        }
    }
}

- (void) buildRows:(NSMutableArray<OARowInfo *> *)rows
{
    // implement in subclasses
}

- (void) buildRowsInternal
{    
    _rows = [NSMutableArray array];

    [self buildTopRows:_rows];
    
    [self buildRows:_rows];

    if (self.additionalRows)
    {
        [_rows addObjectsFromArray:self.additionalRows];
    }
    
    [_rows sortUsingComparator:^NSComparisonResult(OARowInfo *row1, OARowInfo *row2) {
        if (row1.order < row2.order)
        {
            return NSOrderedAscending;
        }
        else if (row1.order == row2.order)
        {
            return [row1.typeName localizedCompare:row2.typeName];
        }
        else
        {
            return NSOrderedDescending;
        }
    }];

    if ([self showNearestWiki])
        [self buildRowsPoi:YES];

    if ([self showNearestPoi])
        [self buildRowsPoi:NO];

    if ([self needCoords])
    {
        OARowInfo *coordinatesRow = [[OARowInfo alloc] initWithKey:nil icon:nil textPrefix:nil text:@"" textColor:nil isText:NO needLinks:NO order:0 typeName:@"" isPhoneNumber:NO isUrl:NO];
        coordinatesRow.collapsed = YES;
        coordinatesRow.collapsable = YES;
        OACollapsableCoordinatesView *collapsableView = [[OACollapsableCoordinatesView alloc] initWithFrame:CGRectMake(0, 0, 320, 100) lat:self.location.latitude lon:self.location.longitude];
        coordinatesRow.collapsableView = collapsableView;
        [_rows addObject:coordinatesRow];
    }
    
    [self addNearbyImagesIfNeeded];

    _calculatedWidth = 0;
    [self contentHeight:self.tableView.bounds.size.width];
}

- (void)buildRowsPoi:(BOOL)isWiki
{
    id targetObj = [self getTargetObj];
    if ([targetObj isKindOfClass:OAPOI.class])
    {
        OAPOI *poi = (OAPOI *) targetObj;
        OAPOIUIFilter *filter = [self getPoiFilterForType:poi isWiki:isWiki];

        if (isWiki)
            [self processNearestWiki:poi];
        else
            [self processNearestPoi:poi filter:filter];

        NSArray<OAPOI *> *nearest = isWiki ? _nearestWiki : _nearestPoi;
        NSString *rowText = isWiki ? [NSString stringWithFormat:@"%@ (%d)", OALocalizedString(@"wiki_around"), (int) nearest.count] : [NSString stringWithFormat:@"%@ \"%@\" (%d)", OALocalizedString(@"speak_poi"), poi.type.nameLocalized, (int) nearest.count];

        if (nearest.count > 0)
        {
            UIImage *icon = isWiki ? [UIImage imageNamed:[OAUtilities drawablePath:@"mx_wiki_place"]] : poi.icon;
            OARowInfo *rowInfo = [[OARowInfo alloc] initWithKey:nil icon:icon textPrefix:nil text:rowText textColor:nil isText:NO needLinks:NO order:0 typeName:@"" isPhoneNumber:NO isUrl:NO];
            rowInfo.collapsable = YES;
            rowInfo.collapsed = YES;
            rowInfo.collapsableView = [[OACollapsableNearestPoiWikiView alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
            [((OACollapsableNearestPoiWikiView *) rowInfo.collapsableView) setData:nearest hasItems:(isWiki ? _hasOsmWiki : YES) latitude:self.location.latitude longitude:self.location.longitude filter:filter];
            [_rows addObject:rowInfo];
        }
    }
}

- (void) calculateRowsHeight:(CGFloat)width
{
    CGFloat regularTextWidth = width - kMarginLeft - kMarginRight;
    CGFloat collapsableTitleWidth = width - kMarginLeft - kCollapsableTitleMarginRight;
    for (OARowInfo *row in _rows)
    {
        CGFloat textWidth = row.collapsable ? collapsableTitleWidth : regularTextWidth;
        CGFloat rowHeight;
        if (row.isHtml)
        {
            rowHeight = 230.0;
            row.height = rowHeight;
            row.moreText = YES;
        }
        else
        {
            NSString *text = row.textPrefix.length == 0 ? row.text : [NSString stringWithFormat:@"%@: %@", row.textPrefix, row.text];
            CGSize fullBounds = [OAUtilities calculateTextBounds:text width:textWidth font:[row getFont]];
            CGSize bounds = [OAUtilities calculateTextBounds:text width:textWidth height:150.0 font:[row getFont]];
            
            rowHeight = MAX(bounds.height, 28.0) + 11.0 + 11.0;
            row.height = rowHeight;
            row.moreText = fullBounds.height > bounds.height;
        }
        if (row.collapsable)
            [row.collapsableView adjustHeightForWidth:width];
    }
}

- (CGFloat) contentHeight
{
    return _contentHeight;
}

- (CGFloat) contentHeight:(CGFloat)width
{
    if (_calculatedWidth != width)
    {
        [self calculateRowsHeight:width];
        [self calculateContentHeight];
        _calculatedWidth = width;
    }
    return _contentHeight;
}

- (void) calculateContentHeight
{
    CGFloat h = 0;
    for (OARowInfo *row in _rows)
        h += row.height;

    _contentHeight = h;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 60, 0, 0);
    self.tableView.separatorColor = UIColorFromRGB(color_tint_gray);
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = UIColorFromRGB(0xffffff);
    self.tableView.backgroundView = view;
    self.tableView.scrollEnabled = NO;
    [self.tableView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressToCopyText:)]];
    _calculatedWidth = 0;
    [self buildRowsInternal];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void) setContentBackgroundColor:(UIColor *)color
{
    [super setContentBackgroundColor:color];
    self.tableView.backgroundColor = color;
    _contentColor = color;
}

- (void) rebuildRows
{
    [self buildRowsInternal];
}

- (void)processNearestWiki:(OAPOI *)poi
{
    int radius = kNearbyPoiMinRadius;
    OsmAnd::PointI locI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(self.location.latitude, self.location.longitude));
    NSMutableArray<OAPOI *> *wiki = [NSMutableArray new];
    NSMutableArray<OAPOI *> *osmwiki = [NSMutableArray new];

    while (wiki.count + osmwiki.count < kNearbyPoiMaxCount && radius <= kNearbyPoiMaxRadius)
    {
        wiki = [[OAPOIHelper findPOIsByTagName:@"wikipedia" name:nil location:locI categoryName:nil poiTypeName:nil radius:radius] mutableCopy];
        osmwiki = [[OAPOIHelper findPOIsByTagName:nil name:nil location:locI categoryName:@"osmwiki" poiTypeName:nil radius:radius] mutableCopy];
        [osmwiki removeObject:poi];

        OAPOI *prevW;
        NSMutableArray<OAPOI *> *duplicateItems = [NSMutableArray new];
        for (OAPOI *w in wiki)
        {
            if ((prevW && prevW.obfId == w.obfId) || (poi.obfId != 0 && w.obfId == poi.obfId))
                [duplicateItems addObject:w];
            prevW = w;
        }
        [wiki removeObjectsInArray:duplicateItems];

        radius *= kNearbyPoiSearchFactory;
    }
    [wiki addObjectsFromArray:osmwiki];
    wiki = [[OAMapUtils sortPOI:wiki lat:self.location.latitude lon:self.location.longitude] mutableCopy];

    _hasOsmWiki = osmwiki.count > 0 && [wiki firstObjectCommonWithArray:osmwiki];
    _nearestWiki = [NSArray arrayWithArray:[wiki subarrayWithRange:NSMakeRange(0, MIN(kNearbyPoiMaxCount, wiki.count))]];
}

- (void)processNearestPoi:(OAPOI *)poi filter:(OAPOIUIFilter *)filter
{
    NSMutableArray<OAPOI *> *amenities = [NSMutableArray new];
    if (!poi.type.category.isWiki)
    {
        int radius = kNearbyPoiMinRadius;
        while (amenities.count < kNearbyPoiMaxCount && radius <= kNearbyPoiMaxRadius)
        {
            OsmAnd::PointI pointI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(self.location.latitude, self.location.longitude));
            const auto rect = OsmAnd::Utilities::boundingBox31FromAreaInMeters(radius, pointI);
            const auto top = OsmAnd::Utilities::get31LatitudeY(rect.top());
            const auto left = OsmAnd::Utilities::get31LongitudeX(rect.left());
            const auto bottom = OsmAnd::Utilities::get31LatitudeY(rect.bottom());
            const auto right = OsmAnd::Utilities::get31LongitudeX(rect.right());
            amenities = [[filter searchAmenities:top left:left bottom:bottom right:right zoom:-1 matcher:nil] mutableCopy];
            [amenities removeObject:poi];
            radius *= kNearbyPoiSearchFactory;
        }
        amenities = [[OAMapUtils sortPOI:amenities lat:self.location.latitude lon:self.location.longitude] mutableCopy];
    }
    _nearestPoi = amenities.count > 0 ? [NSArray arrayWithArray:[amenities subarrayWithRange:NSMakeRange(0, MIN(kNearbyPoiMaxCount, amenities.count))]] : [NSArray new];
}

- (BOOL) showNearestWiki
{
    return YES;
}

- (BOOL) showNearestPoi
{
    return YES;
}

- (OAPOIUIFilter *) getPoiFilterForType:(OAPOI *)target isWiki:(BOOL)isWiki
{
    if (target)
    {
        OAPOIFiltersHelper *helper = [OAPOIFiltersHelper sharedInstance];
        return isWiki ? [helper getTopWikiPoiFilter] : [helper getFilterById:[NSString stringWithFormat:@"std_%@", target.type.name]];
    }
    return nil;
}

- (NSArray<OATransportStopRoute *> *) getSubTransportStopRoutes:(BOOL)nearby
{
    NSMutableArray<OATransportStopRoute *> *res = [NSMutableArray array];
    for (OATransportStopRoute *route in self.routes)
    {
        BOOL isCurrentRouteNearby = route.refStop && route.refStop->getName("", false) != route.stop->getName("", false);
        if ((nearby && isCurrentRouteNearby) || (!nearby && !isCurrentRouteNearby))
            [res addObject:route];
    }
    return res;
}

- (void)sendNearbyImagesRequest:(OARowInfo *)nearbyImagesRowInfo
{
    OACollapsableCardsView *cardsView = (OACollapsableCardsView *)nearbyImagesRowInfo.collapsableView;
    if (!nearbyImagesRowInfo || cardsView.cards.count > 0)
        return;
    
    [cardsView setCards:@[[[OAImageCard alloc] initWithData:@{@"key" : @"loading"}]]];
    NSMutableArray <OAAbstractCard *> *cards = [NSMutableArray new];
    NSString *imageTagContent = nil;
    NSString *mapillaryTagContent = nil;
    NSString *wikimediaTagContent = nil;
    NSString *wikidataTagContent = nil;
    if ([self.getTargetObj isKindOfClass:OAPOI.class])
    {
        OAPOI *poi = self.getTargetObj;
        imageTagContent = poi.values[@"image"];
        mapillaryTagContent = poi.values[@"mapillary"];
        wikimediaTagContent = poi.values[@"wikimedia_commons"];
        wikidataTagContent = poi.values[@"wikidata"];
    }
    _wikidataCardsReady = NO;
    _wikimediaCardsReady = NO;
    _otherCardsReady = NO;
    [self addWikimediaCards:wikimediaTagContent cards:cards rowInfo:nearbyImagesRowInfo];
    [self addWikidataCards:wikidataTagContent cards:cards rowInfo:nearbyImagesRowInfo];
    [self addOtherCards:imageTagContent mapillary:mapillaryTagContent cards:cards rowInfo:nearbyImagesRowInfo];
}

- (void) addWikidataCards:(NSString *)wikidataTagContent cards:(NSMutableArray<OAAbstractCard *> *)cards rowInfo:(OARowInfo *)nearbyImagesRowInfo
{
    if (wikidataTagContent && [wikidataTagContent hasPrefix:@"Q"])
    {
        NSURL *urlObj = [[NSURL alloc] initWithString: [NSString stringWithFormat:@"https://www.wikidata.org/w/api.php?action=wbgetclaims&property=P18&entity=%@&format=json", wikidataTagContent]];
        NSURLSession *aSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        [[aSession dataTaskWithURL:urlObj completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            OAUrlImageCard *resultCard = nil;
            if (((NSHTTPURLResponse *)response).statusCode == 200)
            {
                if (data && !error)
                {
                    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                    if (jsonDict)
                    {
                        try {
                            NSArray *records = jsonDict[@"claims"][@"P18"];
                            if (records && records.count > 0)
                            {
                                NSString *imageName = records.firstObject[@"mainsnak"][@"datavalue"][@"value"];
                                if (imageName)
                                    resultCard = [self createWikimediaCard:[NSString stringWithFormat:@"File:%@",imageName] isFromWikidata:YES];
                            }
                        }
                        catch(NSException *e)
                        {
                            NSLog(@"Wikidata image json serialising error");
                        }
                    }
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (resultCard)
                    [cards addObject:resultCard];
                [self onWikidataCardsReady:cards rowInfo:nearbyImagesRowInfo];
            });
        }] resume];
    }
    else
    {
        [self onWikidataCardsReady:cards rowInfo:nearbyImagesRowInfo];
    }
}

- (void) onWikidataCardsReady:(NSMutableArray<OAAbstractCard *> *)cards rowInfo:(OARowInfo *)nearbyImagesRowInfo
{
    _wikidataCardsReady = YES;
    [self updateDisplayingCards:cards rowInfo:nearbyImagesRowInfo];
}

- (void) addWikimediaCards:(NSString *)wikiMediaTagContent cards:(NSMutableArray<OAAbstractCard *> *)cards rowInfo:(OARowInfo *)nearbyImagesRowInfo
{
    NSString *wikimediaFilePrefix = @"File:";
    NSString *wikimediaCategoryPrefix = @"Category:";
    
    if (wikiMediaTagContent && [wikiMediaTagContent hasPrefix:wikimediaFilePrefix])
    {
        OAUrlImageCard *card = [self createWikimediaCard:wikiMediaTagContent isFromWikidata:NO];
        if (card)
        {
            [cards addObject:card];
            [self onWikimediaCardsReady:cards rowInfo:nearbyImagesRowInfo];
        }
    }
    else if (wikiMediaTagContent && [wikiMediaTagContent hasPrefix:wikimediaCategoryPrefix])
    {
        NSString *urlSafeFileName = [[wikiMediaTagContent stringByReplacingOccurrencesOfString:@" "  withString:@"_"] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        NSString *url = [NSString stringWithFormat:@"https://commons.wikimedia.org/w/api.php?action=query&list=categorymembers&cmtitle=%@&cmlimit=500&format=json", urlSafeFileName];
        NSURL *urlObj = [[NSURL alloc] initWithString:url];
        NSURLSession *aSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        [[aSession dataTaskWithURL:urlObj completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            NSMutableArray<OAAbstractCard *> *resultCards = [NSMutableArray array];
            if (((NSHTTPURLResponse *)response).statusCode == 200)
            {
                if (data)
                {
                    NSError *error;
                    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                    NSDictionary *imagesDict = jsonDict[@"query"][@"categorymembers"];
                    if (!error && imagesDict)
                    {
                        for (NSDictionary *imageDict in imagesDict)
                        {
                            NSString *imageName = imageDict[@"title"];
                            if (imageName)
                            {
                                OAAbstractCard *card = [self createWikimediaCard:imageName isFromWikidata:NO];
                                if (card)
                                    [resultCards addObject:card];
                            }
                        }
                    }
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [cards addObjectsFromArray:resultCards];
                [self onWikimediaCardsReady:cards rowInfo:nearbyImagesRowInfo];
            });
        }] resume];
    }
    else
    {
        [self onWikimediaCardsReady:cards rowInfo:nearbyImagesRowInfo];
    }
}

- (void) onWikimediaCardsReady:(NSMutableArray<OAAbstractCard *> *)cards rowInfo:(OARowInfo *)nearbyImagesRowInfo
{
    _wikimediaCardsReady = YES;
    [self updateDisplayingCards:cards rowInfo:nearbyImagesRowInfo];
}

- (OAUrlImageCard *) createWikimediaCard:(NSString *)wikiMediaTagContent isFromWikidata:(BOOL)isFromWikidata
{
    NSString *wikimediaFilePrefix = @"File:";
    NSString *imageFileName = [wikiMediaTagContent substringWithRange:NSMakeRange(wikimediaFilePrefix.length, wikiMediaTagContent.length - wikimediaFilePrefix.length)];
    NSString *preparedFileName = [imageFileName stringByReplacingOccurrencesOfString:@" "  withString:@"_"];
    NSString *urlSafeFileName = [preparedFileName stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
    
    NSString *hash = [CocoaSecurity md5:preparedFileName].hexLower;
    NSString *hashFirstPart = [hash substringWithRange:NSMakeRange(0, 1)];
    NSString *hashSecondPart = [hash substringWithRange:NSMakeRange(0, 2)];
    
    NSString *thumbSize = @"500";
    NSString *url = [NSString stringWithFormat:@"https://commons.wikimedia.org/wiki/%@", [wikiMediaTagContent stringByReplacingOccurrencesOfString:@" "  withString:@"_"]];
    NSString *imageHiResUrl = [NSString stringWithFormat:@"https://upload.wikimedia.org/wikipedia/commons/%@/%@/%@", hashFirstPart, hashSecondPart, urlSafeFileName];
    NSString *imageStubUrl = [NSString stringWithFormat:@"https://upload.wikimedia.org/wikipedia/commons/thumb/%@/%@/%@/%@px-%@", hashFirstPart, hashSecondPart, urlSafeFileName, thumbSize, urlSafeFileName];
    NSString *type = isFromWikidata ? @"wikidata-photo" : @"wikimedia-photo";
    
    NSDictionary *wikimediaFeature = @{
        @"type": type,
        @"lat": [NSNumber numberWithDouble:self.location.latitude],
        @"lon": [NSNumber numberWithDouble:self.location.longitude],
        @"key": wikiMediaTagContent,
        @"title": imageFileName,
        @"url": url,
        @"imageUrl": imageStubUrl,
        @"imageHiresUrl": imageHiResUrl,
        @"username": @"",
        @"timestamp": @"",
        @"externalLink": @NO,
        @"360": @NO
    };
    
    return (OAUrlImageCard *)[self getCard: wikimediaFeature];
}

- (OAAbstractCard *) getCard:(NSDictionary *) feature
{
    NSString *type = feature[@"type"];
    if ([TYPE_MAPILLARY_PHOTO isEqualToString:type])
        return [[OAMapillaryImageCard alloc] initWithData:feature];
    else if ([TYPE_MAPILLARY_CONTRIBUTE isEqualToString:type])
        return [[OAMapillaryContributeCard alloc] init];
    else if ([TYPE_URL_PHOTO isEqualToString:type])
        return [[OAUrlImageCard alloc] initWithData:feature];
    else if ([TYPE_WIKIMEDIA_PHOTO isEqualToString:type])
        return [[OAUrlImageCard alloc] initWithData:feature];
    else if ([TYPE_WIKIDATA_PHOTO isEqualToString:type])
        return [[OAUrlImageCard alloc] initWithData:feature];
    
    return nil;
}

- (void) addOtherCards:(NSString *)imageTagContent mapillary:(NSString *)mapillaryTagContent  cards:(NSMutableArray<OAAbstractCard *> *)cards rowInfo:(OARowInfo *)nearbyImagesRowInfo
{
    NSString *urlString = [NSString stringWithFormat:@"https://osmand.net/api/cm_place?lat=%f&lon=%f",
    self.location.latitude, self.location.longitude];
    if (imageTagContent)
        urlString = [urlString stringByAppendingString:[NSString stringWithFormat:@"&osm_image=%@", imageTagContent]];
    if (mapillaryTagContent)
        urlString = [urlString stringByAppendingString:[NSString stringWithFormat:@"&osm_mapillary_key=%@", mapillaryTagContent]];
    
    NSURL *urlObj = [[NSURL alloc] initWithString:[[urlString stringByReplacingOccurrencesOfString:@" "  withString:@"_"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURLSession *aSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[aSession dataTaskWithURL:urlObj completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSMutableArray<OAAbstractCard *> *resultCards = [NSMutableArray array];
        if (((NSHTTPURLResponse *)response).statusCode == 200)
        {
            if (data)
            {
                NSError *error;
                NSString *safeCharsString = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
                NSData *safeCharsData = [safeCharsString dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:safeCharsData options:NSJSONReadingAllowFragments error:&error];
                if (!error)
                {
                    for (NSDictionary *dict in jsonDict[@"features"])
                    {
                        OAAbstractCard *card = [self getCard:dict];
                        if (card)
                            [resultCards addObject:card];
                    }
                }
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [cards addObjectsFromArray:resultCards];
            [self onOtherCardsReady:cards rowInfo:nearbyImagesRowInfo];
        });
    }] resume];
}

- (void) onOtherCardsReady:(NSMutableArray<OAAbstractCard *> *)cards rowInfo:(OARowInfo *)nearbyImagesRowInfo
{
    _otherCardsReady = YES;
    [self updateDisplayingCards:cards rowInfo:nearbyImagesRowInfo];
}

- (void) updateDisplayingCards:(NSMutableArray<OAAbstractCard *> *)cards rowInfo:(OARowInfo *)nearbyImagesRowInfo
{
    if (_wikidataCardsReady && _wikimediaCardsReady && _otherCardsReady)
    {
        if (cards.count == 0)
            [cards addObject:[[OANoImagesCard alloc] init]];
        else if (cards.count > 1)
            [self removeDublicatesFromCards:cards];
    
        [((OACollapsableCardsView *)nearbyImagesRowInfo.collapsableView) setCards:cards];
    }
}

- (void) removeDublicatesFromCards:(NSMutableArray<OAAbstractCard *> *)cards
{
    NSMutableArray *wikimediaCards = [NSMutableArray new];
    NSMutableArray *mapilaryCards = [NSMutableArray new];
    OAMapillaryContributeCard *mapilaryContributeCard = nil;
    
    for (OAAbstractCard *card in cards)
    {
        if ([card isKindOfClass:OAUrlImageCard.class])
            [wikimediaCards addObject:card];
        else if ([card isKindOfClass:OAMapillaryImageCard.class])
            [mapilaryCards addObject:card];
        else if ([card isKindOfClass:OAMapillaryContributeCard.class])
            mapilaryContributeCard = card;
    }
    if (wikimediaCards.count > 0)
    {
        NSArray *sortedWikimediaCards = [wikimediaCards sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            NSString *first = [(OAUrlImageCard *)a imageHiresUrl];
            NSString *second = [(OAUrlImageCard *)b imageHiresUrl];
            return [first compare:second];
        }];
        
        [wikimediaCards removeAllObjects];
        [wikimediaCards addObject:sortedWikimediaCards.firstObject];
        OAUrlImageCard *previousCard = sortedWikimediaCards.firstObject;
        for (int i = 1; i < sortedWikimediaCards.count; i++)
        {
            OAUrlImageCard *card = sortedWikimediaCards[i];
            if (![card.imageHiresUrl isEqualToString:previousCard.imageHiresUrl])
            {
                [wikimediaCards addObject:card];
                previousCard = card;
            }
        }
    }
    
    [cards removeAllObjects];
    [cards addObjectsFromArray:wikimediaCards];
    [cards addObjectsFromArray:mapilaryCards];
    if (mapilaryContributeCard)
        [cards addObject:mapilaryContributeCard];
}

- (void) addNearbyImagesIfNeeded
{
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == NotReachable)
        return;
    
    OARowInfo *nearbyImagesRowInfo = [[OARowInfo alloc] initWithKey:nil icon:[UIImage imageNamed:@"ic_custom_photo"] textPrefix:nil text:OALocalizedString(@"mapil_images_nearby") textColor:nil isText:NO needLinks:NO order:0 typeName:@"" isPhoneNumber:NO isUrl:NO];

    OACollapsableCardsView *cardView = [[OACollapsableCardsView alloc] init];
    cardView.delegate = self;
    nearbyImagesRowInfo.collapsable = YES;
    nearbyImagesRowInfo.collapsed = [OAAppSettings sharedManager].onlinePhotosRowCollapsed.get;
    nearbyImagesRowInfo.collapsableView = cardView;
    nearbyImagesRowInfo.collapsableView.frame = CGRectMake([OAUtilities getLeftMargin], 0, 320, 100);
    [_rows addObject:nearbyImagesRowInfo];
    
    _nearbyImagesRowInfo = nearbyImagesRowInfo;
}

-(void)handleLongPressToCopyText:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded)
    {
        CGPoint p = [gestureRecognizer locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
        if (indexPath)
        {
            OARowInfo *info = _rows[indexPath.row];
            NSString *textToCopy;
            if ([info.collapsableView isKindOfClass:OACollapsableCoordinatesView.class])
                textToCopy = [OAPointDescription getLocationName:self.location.latitude lon:self.location.longitude sh:YES];
            else
                textToCopy = info.textPrefix.length == 0 ? info.text : [NSString stringWithFormat:@"%@: %@", info.textPrefix, info.text];

            [[UIPasteboard generalPasteboard] setString:textToCopy];
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _rows.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    OARowInfo *info = _rows[indexPath.row];
    
    if (!info.isHtml)
    {
        if ([info.collapsableView isKindOfClass:OACollapsableCoordinatesView.class])
        {
            OATargetInfoCollapsableCoordinatesViewCell *cell;
            cell = (OATargetInfoCollapsableCoordinatesViewCell *)[tableView dequeueReusableCellWithIdentifier:[OATargetInfoCollapsableCoordinatesViewCell getCellIdentifier]];
            
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATargetInfoCollapsableCoordinatesViewCell getCellIdentifier] owner:self options:nil];
                cell = (OATargetInfoCollapsableCoordinatesViewCell *)[nib objectAtIndex:0];
            }
            
            OACollapsableCoordinatesView *coordinateView = (OACollapsableCoordinatesView *) info.collapsableView;
            [cell setupCellWithLat:coordinateView.lat lon:coordinateView.lon];
            
            cell.collapsableView = coordinateView;
            [cell setCollapsed:info.collapsed rawHeight:[info getRawHeight]];

            return cell;
        }
        else if (info.collapsable)
        {
            OATargetInfoCollapsableViewCell* cell;
            cell = (OATargetInfoCollapsableViewCell *)[tableView dequeueReusableCellWithIdentifier:[OATargetInfoCollapsableViewCell getCellIdentifier]];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATargetInfoCollapsableViewCell getCellIdentifier] owner:self options:nil];
                cell = (OATargetInfoCollapsableViewCell *)[nib objectAtIndex:0];
            }
            if (info.icon.size.width < cell.iconView.frame.size.width && info.icon.size.height < cell.iconView.frame.size.height)
                cell.iconView.contentMode = UIViewContentModeCenter;
            else
                cell.iconView.contentMode = UIViewContentModeScaleAspectFit;
            
            cell.backgroundColor = _contentColor;
            [cell setImage:info.icon];
            cell.textView.text = info.textPrefix.length == 0 ? info.text : [NSString stringWithFormat:@"%@: %@", info.textPrefix, info.text];
            cell.textView.textColor = info.textColor;
            cell.textView.numberOfLines = info.height > 50.0 ? 20 : 1;

            cell.collapsableView = info.collapsableView;
            [cell setCollapsed:info.collapsed rawHeight:[info getRawHeight]];

            return cell;
        }
        else
        {
            OATargetInfoViewCell* cell;
            cell = (OATargetInfoViewCell *)[tableView dequeueReusableCellWithIdentifier:[OATargetInfoViewCell getCellIdentifier]];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATargetInfoViewCell getCellIdentifier] owner:self options:nil];
                cell = (OATargetInfoViewCell *)[nib objectAtIndex:0];
            }
            if (info.icon.size.width < cell.iconView.frame.size.width && info.icon.size.height < cell.iconView.frame.size.height)
                cell.iconView.contentMode = UIViewContentModeCenter;
            else
                cell.iconView.contentMode = UIViewContentModeScaleAspectFit;
            
            cell.backgroundColor = _contentColor;
            cell.iconView.image = info.icon;
            
            cell.textView.text = info.textPrefix.length == 0 ? info.text : [NSString stringWithFormat:@"%@: %@", info.textPrefix, info.text];
            cell.textView.textColor = info.textColor;
            cell.textView.font = [info getFont];
            cell.textView.numberOfLines = info.height > 50.0 ? 20 : 1;

            return cell;
        }
    }
    else
    {
        OAWebViewCell* cell;
        cell = (OAWebViewCell *)[tableView dequeueReusableCellWithIdentifier:[OAWebViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAWebViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAWebViewCell *)[nib objectAtIndex:0];
        }
        if (info.icon.size.width < cell.iconView.frame.size.width && info.icon.size.height < cell.iconView.frame.size.height)
        {
            cell.iconView.contentMode = UIViewContentModeCenter;
        }
        else
        {
            cell.iconView.contentMode = UIViewContentModeScaleAspectFit;
        }
        cell.backgroundColor = _contentColor;
        cell.webView.backgroundColor = _contentColor;
        cell.iconView.image = info.icon;
        [cell.webView loadHTMLString:[kViewPortHtml stringByAppendingString:info.text]  baseURL:nil];
        
        return cell;
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OARowInfo *info = _rows[indexPath.row];
    return info.height;
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OARowInfo *info = _rows[indexPath.row];
    if (info.collapsable)
        [info.collapsableView adjustHeightForWidth:tableView.frame.size.width];
    return info.height;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    OARowInfo *info = _rows[indexPath.row];
    if (info.delegate)
    {
        [info.delegate onRowClick:self rowInfo:info];
    }
    else if (info.collapsable)
    {
        info.collapsed = !info.collapsed;
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self calculateContentHeight];
        if (self.delegate)
            [self.delegate contentHeightChanged:0];
    }
    else if (info.isPhoneNumber)
    {
        if ([info.key isEqual:@"phone"] || [info.key isEqual:@"mobile"])
            [OAUtilities callPhone:info.text];
        else
        {
            NSString *url;
            if ([info.key isEqual:@"whatsapp"])
            {
                NSString *phoneNumber = [[info.text componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
                url = [NSString stringWithFormat:kWhatsAppLink, phoneNumber];
            }
            else if ([info.key isEqual:@"viber"])
            {
                url = [NSString stringWithFormat:kViberLink, info.text];
            }
            [OAUtilities callUrl:url];
        }
    }
    else if (info.isUrl)
    {
        if ([info.text containsString:kWikiLink])
        {
            OAIAPHelper *helper = [OAIAPHelper sharedInstance];
            if ([helper.wiki isPurchased])
            {
                [OAWikiArticleHelper showWikiArticle:self.location url:info.text];
            }
            else
            {
                [OAPluginPopupViewController askForPlugin:kInAppId_Addon_Wiki];
            }
        }
        else if ([info.key isEqual:@"skype"])
        {
            [OAUtilities callUrl:[NSString stringWithFormat:kSkypeLink, info.text]];
        }
        else if ([info.text isValidEmail])
        {
            [OAUtilities callUrl:[NSString stringWithFormat:kMailLink, info.text]];
        }
        else
        {
            [OAUtilities callUrl:info.text];
        }
    }
    else if (info.isText && info.moreText)
    {
        OAEditDescriptionViewController *_editDescController = [[OAEditDescriptionViewController alloc] initWithDescription:info.text isNew:NO readOnly:YES];
        [self.navController pushViewController:_editDescController animated:YES];
    }
}

#pragma mark - OACollapsableCardViewDelegate

- (void) onViewExpanded
{
    [self sendNearbyImagesRequest:_nearbyImagesRowInfo];
}

@end
