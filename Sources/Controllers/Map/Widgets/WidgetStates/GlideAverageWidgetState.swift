//
//  GlideAverageWidgetState.swift
//  OsmAnd Maps
//
//  Created by Skalii on 29.03.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAGlideAverageWidgetState)
@objcMembers
final class GlideAverageWidgetState: OAWidgetState {

    private static let prefBaseId = "glide_widget_show_average_vertical_speed"

    private let widgetType: WidgetType
    private let preference: OACommonBoolean

    init(_ customId: String?, widgetParams: ([String: Any])? = nil) {
        widgetType = .glideAverage
        preference = Self.registerPreference(customId, widgetParams: widgetParams)
    }

    func getPreference() -> OACommonBoolean {
        preference
    }

    override func getMenuTitle() -> String {
        widgetType.title
    }

    override func getSettingsIconId(_ night: Bool) -> String {
        widgetType.iconName
    }

    override func changeToNextState() {
        preference.set(!preference.get())
    }

    override func copyPrefs(_ appMode: OAApplicationMode, customId: String?) {
        Self.registerPreference(customId).set(preference.get(appMode), mode: appMode)
    }

    private static func registerPreference(_ customId: String?, widgetParams: ([String: Any])? = nil) -> OACommonBoolean {
        var prefId = Self.prefBaseId
        if let customId, !customId.isEmpty {
            prefId += "_\(customId)"
        }
        
        var defValue = false
        
        if let string = widgetParams?[Self.prefBaseId] as? String, let widgetValue = Bool(string) {
            defValue = widgetValue
        }

        return OAAppSettings.sharedManager().registerBooleanPreference(prefId, defValue: defValue)
    }
}
