//
//  NameTagsDetailsViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 20.06.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class NameTagsDetailsViewController: OABaseNavbarViewController {
    private var tags: [NSDictionary]
    
    init(tags: [NSDictionary]) {
        self.tags = tags
        super.init(nibName: "OABaseNavbarViewController", bundle: nil)
        initTableData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
    }
    
    override func getTitle() -> String? {
        localizedString("shared_string_name")
    }
    
    override func getLeftNavbarButtonTitle() -> String? {
        localizedString("shared_string_cancel")
    }
    
    override func generateData() {
        tableData.clearAllData()
        var sections = [String: [(tag: (key: String, value: String, descr: String), header: String)]]()
        for tagDict in tags {
            guard let tagKey = tagDict["key"] as? String,
                  let localizedTitle = tagDict["localizedTitle"] as? String,
                  let value = tagDict["value"] as? String else { continue }
            
            let baseKey = String(tagKey.split(separator: ":").first ?? "")
            let description = extractDescription(from: localizedTitle)
            let header = extractHeader(from: localizedTitle, withKey: tagKey)
            sections[baseKey, default: []].append((tag: (key: tagKey, value: value, descr: description), header: header))
        }
        
        for (baseKey, tagsWithHeaders) in sections {
            let section = tableData.createNewSection()
            section.headerText = tagsWithHeaders.first?.header ?? baseKey
            for tagWithHeader in tagsWithHeaders {
                let row = section.createNewRow()
                configureRow(row, with: tagWithHeader.tag)
            }
        }
    }
    
    private func extractHeader(from title: String, withKey key: String) -> String {
        if key.hasPrefix("name:") {
            return localizedString("shared_string_name")
        } else {
            let endIndex = title.firstIndex(of: "(") ?? title.endIndex
            return String(title[..<endIndex]).trimmingCharacters(in: .whitespaces)
        }
    }
    
    private func extractDescription(from title: String) -> String {
        guard let (start, end) = findEnclosingBrackets(in: title) else {
            return ""
        }
        
        return String(title[start..<end]).capitalized(with: Locale.current)
    }
    
    private func findEnclosingBrackets(in text: String) -> (start: String.Index, end: String.Index)? {
        var depth = 0
        var startIndex: String.Index?
        var endIndex: String.Index?
        for index in text.indices {
            switch text[index] {
            case "(":
                if depth == 0 { startIndex = text.index(after: index) }
                depth += 1
            case ")":
                depth -= 1
                if depth == 0 { endIndex = index; break }
            default:
                continue
            }
        }
        
        if let start = startIndex, let end = endIndex, start <= end {
            return (start, end)
        }
        
        return nil
    }
    
    private func configureRow(_ row: OATableRowData, with tag: (key: String, value: String, descr: String)) {
        row.cellType = OASimpleTableViewCell.reuseIdentifier
        row.key = tag.key
        row.title = tag.value
        row.descr = tag.descr
    }
    
    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier, for: indexPath) as! OASimpleTableViewCell
        cell.selectionStyle = .none
        cell.leftIconVisibility(false)
        cell.descriptionVisibility(!(item.descr?.isEmpty ?? true))
        cell.titleLabel.text = item.title
        cell.descriptionLabel.text = item.descr
        return cell
    }
}
