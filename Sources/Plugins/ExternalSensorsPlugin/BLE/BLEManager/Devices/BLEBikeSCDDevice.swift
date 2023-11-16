//
//  BLEBikeSCDDevice.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 24.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation
import CoreBluetooth

final class BLEBikeSCDDevice: Device {
    
    var name: String {
        "Bike Sensor"
    }
    
    override class var getServiceUUID: String {
        GattAttributes.SERVICE_CYCLING_SPEED_AND_CADENCE
    }
    
    override var getServiceConnectedImage: UIImage {
        UIImage(named: "widget_sensor_bicycle_power")!
    }
    
    override var getDataFields: [[String: String]]? {
        if let sensor = sensors.first(where: { $0 is BLEBikeSensor }) as? BLEBikeSensor {
            var result = [[String: String]]()
            if let lastBikeSpeedDistanceData = sensor.lastBikeSpeedDistanceData {
                let speedFormatter = MeasurementFormatter.numeric()
                let distanceFormatter = MeasurementFormatter.numeric(maximumFractionDigits: 2)
                
                print("speed-1: \(lastBikeSpeedDistanceData.speed.value)")
                print("distance-1: \(lastBikeSpeedDistanceData.totalTravelDistance.value)")
                
                let speed1 = speedFormatter.string(from: lastBikeSpeedDistanceData.speed)
                let distance1 = distanceFormatter.string(from: lastBikeSpeedDistanceData.totalTravelDistance)
                
                print("speed1: \(speed1)")
                print("distance1: \(distance1)")
                
                let speed = OAOsmAndFormatter.getFormattedSpeed(Float(lastBikeSpeedDistanceData.speed.value))
                let distance = OAOsmAndFormatter.getFormattedDistance(Float(lastBikeSpeedDistanceData.totalTravelDistance.value), forceTrailingZeroes: false)
                print("speed: \(speed ?? "")")
                print("distance: \(distance ?? "")")
                
                result.append([localizedString("external_device_characteristic_speed"): String(speed!)])
                result.append([localizedString("external_device_characteristic_total_distance"): String(distance!)])
            }
            if let lastBikeCadenceData = sensor.lastBikeCadenceData {
                result.append([localizedString("external_device_characteristic_cadence"): String(lastBikeCadenceData.cadence)])
            }
            return result.isEmpty ? nil : result
        }
        return nil
    }
    
    override var getSettingsFields: [String: Any]? {
        if let settings = DeviceHelper.shared.devicesSettingsCollection.getDeviceSettings(deviceId: id) {
            if let additionalParams = settings.additionalParams, let wheelCircumference = additionalParams[WheelDeviceSettings.WHEEL_CIRCUMFERENCE_KEY], let value = Float(wheelCircumference) {
                return [WheelDeviceSettings.WHEEL_CIRCUMFERENCE_KEY: value]
            } else {
                return [WheelDeviceSettings.WHEEL_CIRCUMFERENCE_KEY: Float(WheelDeviceSettings.DEFAULT_WHEEL_CIRCUMFERENCE)]
            }
        }
        return nil
    }
    
    init() {
        super.init(deviceType: .BLE_BICYCLE_SCD)
        sensors.append(BLEBikeSensor(device: self, sensorId: "bike_scd"))
    }
    
    override func getSupportedWidgetDataFieldTypes() -> [WidgetType]? {
        [.bicycleSpeed, .bicycleCadence, .bicycleDistance]
    }
    
    override func update(with characteristic: CBCharacteristic, result: (Result<Void, Error>) -> Void) {
        sensors.forEach { $0.update(with: characteristic, result: result) }
    }
}
