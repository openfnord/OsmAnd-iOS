//
//  OAWikipediaSettingsViewController.m
//  OsmAnd Maps
//
//  Created by Skalii on 02.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAWikipediaSettingsViewController.h"
#import "OAWikipediaLanguagesViewController.h"
#import "OAValueTableViewCell.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OAWikipediaPlugin.h"
#import "OAApplicationMode.h"
#import "OAColors.h"
#import "Localization.h"

@interface OAWikipediaSettingsViewController () <OAWikipediaScreenDelegate>

@end

@implementation OAWikipediaSettingsViewController
{
    OATableDataModel *_data;
    OAWikipediaPlugin *_wikiPlugin;
    NSIndexPath *_selectedIndexPath;
}

#pragma mark - Initialization

- (void)commonInit
{
    _wikiPlugin = (OAWikipediaPlugin *) [OAPlugin getPlugin:OAWikipediaPlugin.class];
}

#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    _selectedIndexPath = nil;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"download_wikipedia_maps");
}

- (NSString *)getSubtitle
{
    return OALocalizedString(@"shared_string_settings");
}

#pragma mark - Table data

- (void)generateData
{
    _data = [OATableDataModel model];

    OATableSectionData *languageSection = [_data createNewSection];
    languageSection.footerText = OALocalizedString(@"wikipedia_language_settings_descr");

    OATableRowData *languageItem = [languageSection createNewRow];
    languageItem.key = @"language";
    languageItem.cellType = [OAValueTableViewCell getCellIdentifier];
    languageItem.title = OALocalizedString(@"shared_string_language");
    languageItem.iconName = @"ic_custom_map_languge";
    [self generateValueForItem:languageItem];
}

- (void)generateValueForItem:(OATableRowData *)item
{
    NSString *value = @"";
    if ([item.key isEqualToString:@"language"])
        value = [_wikiPlugin getLanguagesSummary];
    [item setObj:value forKey:@"value"];
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    return [_data sectionDataForIndex:section].footerText;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return [_data rowCount:section];
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.leftIconView.tintColor = UIColorFromRGB([self.appMode getIconColor]);
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            cell.valueLabel.text = [item stringForKey:@"value"];
            cell.leftIconView.image = [UIImage templateImageNamed:item.iconName];
        }
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return [_data sectionCount];
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    _selectedIndexPath = indexPath;

    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.key isEqualToString:@"language"])
    {
        OAWikipediaLanguagesViewController *controller = [[OAWikipediaLanguagesViewController alloc] init];
        controller.delegate = self;
        [self showModalViewController:controller];
    }
}

#pragma mark - OAWikipediaScreenDelegate

- (void)updateSelectedLanguage
{
    if (_selectedIndexPath)
    {
        OATableRowData *item = [_data itemForIndexPath:_selectedIndexPath];
        [self generateValueForItem:item];
        [self.tableView reloadRowsAtIndexPaths:@[_selectedIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

@end
