// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public struct OutputCapacitor: Codable {
    public var stable: Bool
    public var depletesIn: Double
    public var capacity: Double
    public var recharge: Double
    public var peak: Double
    public var percentage: Double
}

public struct OutputOffense: Codable {
    public var dps: Double
    public var dpsWithReload: Double
    public var alpha: Double
    public var droneDps: Double
}

public struct OutputDefenseRecharge: Codable {
    public var passive: Double
    public var shield: Double
    public var armor: Double
    public var hull: Double
}

public struct OutputDefenseResist: Codable {
    public var em: Double
    public var therm: Double
    public var kin: Double
    public var expl: Double
}

public struct OutputDefenseShield: Codable {
    public var resist: OutputDefenseResist
    public var hp: Double
    public var recharge: Double
}

public struct OutputDefenseArmor: Codable {
    public var resist: OutputDefenseResist
    public var hp: Double
}

public struct OutputDefenseStructure: Codable {
    public var resist: OutputDefenseResist
    public var hp: Double
}

public struct OutputDefense: Codable {
    public var recharge: OutputDefenseRecharge
    public var shield: OutputDefenseShield
    public var armor: OutputDefenseArmor
    public var structure: OutputDefenseStructure
    public var ehp: Double
}

public struct OutputTargeting: Codable {
    public var lockRange: Double
    public var sensorStrength: Double
    public var scanResolution: Double
    public var signatureRadius: Double
    public var maxLockedTargets: Double
}

public struct OutputNavigation: Codable {
    public var speed: Double
    public var mass: Double
    public var agility: Double
    public var warpSpeed: Double
    public var alignTime: Double
}

public struct OutputDrones: Codable {
    public var dps: Double
    public var bandwidthLoad: Double
    public var bandwidth: Double
    public var range: Double
    public var active: Double
    public var capacityLoad: Double
    public var capacity: Double
}

public struct OutputCpu: Codable {
    public var free: Double
    public var capacity: Double
}

public struct OutputPower: Codable {
    public var free: Double
    public var capacity: Double
}

public struct OutputSlots: Codable {
    public var hi1: String
    public var hi2: String
    public var hi3: String
    public var hi4: String
    public var hi5: String
    public var hi6: String
    public var hi7: String
    public var hi8: String
    public var med1: String
    public var med2: String
    public var med3: String
    public var med4: String
    public var med5: String
    public var med6: String
    public var med7: String
    public var med8: String
    public var lo1: String
    public var lo2: String
    public var lo3: String
    public var lo4: String
    public var lo5: String
    public var lo6: String
    public var lo7: String
    public var lo8: String
}

public struct Output: Codable {
    public var capacitor: OutputCapacitor
    public var offense: OutputOffense
    public var defense: OutputDefense
    public var targeting: OutputTargeting
    public var navigation: OutputNavigation
    public var drones: OutputDrones
    public var cpu: OutputCpu
    public var power: OutputPower
    public var slots: OutputSlots
}

// Helper to get an attribute value (uses .value if set, otherwise defaultValue)
func getAttributeByName(info: Info, attributes: [Int: Attribute], name: String) -> Double {
    let attributeId = info.attributeNameToId(name)
    let defaultAttribute = info.getDogmaAttribute(attributeId)
    if let attribute = attributes[attributeId], let v = attribute.value {
        return v
    } else {
        return defaultAttribute.defaultValue
    }
}

// Helper to get effect category name for a slot
func effectCategoryToName(items: [Item], slotType: SlotType, index: Int) -> String {
    if let item = items.first(where: { $0.slot.type == slotType && $0.slot.index == index }) {
        switch item.state {
        case .passive:  return "passive"
        case .online:   return "online"
        case .active:   return "active"
        case .overload: return "overload"
        default:        return "unknown"
        }
    } else {
        return "empty"
    }
}

// Main function to run the dogma engine calculation and generate output
public func runDogmaEngine(eftString: String, 
                          skills: [Int: Int] = [:], 
                          state: String? = nil,
                          data: Data) throws -> Output {
    
    // Create a temporary InfoName for EFT parsing
    let tempInfo = SimpleInfo(data: data, fit: EsfFit(shipTypeID: 0, modules: [], drones: []), skills: skills)
    
    // Parse EFT string using existing loadEft function
    let eftFit = try loadEft(info: tempInfo, eft: eftString)
    var fit = eftFit.esfFit
    
    // Update module states if provided
    if let state = state {
        guard state.count == 24 else {
            throw NSError(domain: "DogmaEngine", code: 1, 
                         userInfo: [NSLocalizedDescriptionKey: "State should be 24 letters; 8 for each high/medium/low slot. P = Passive (Offline), O = Online, A = Active, V = Overload."])
        }
        
        let stateChars = Array(state)
        
        // Update high slots (0-7)
        for i in 0..<8 {
            if let moduleIndex = fit.modules.firstIndex(where: { 
                $0.slot.index == i && $0.slot.type == .high 
            }) {
                fit.modules[moduleIndex].state = parseState(stateChars[i])
            }
        }
        
        // Update medium slots (8-15)
        for i in 8..<16 {
            if let moduleIndex = fit.modules.firstIndex(where: { 
                $0.slot.index == (i - 8) && $0.slot.type == .medium 
            }) {
                fit.modules[moduleIndex].state = parseState(stateChars[i])
            }
        }
        
        // Update low slots (16-23)
        for i in 16..<24 {
            if let moduleIndex = fit.modules.firstIndex(where: { 
                $0.slot.index == (i - 16) && $0.slot.type == .low 
            }) {
                fit.modules[moduleIndex].state = parseState(stateChars[i])
            }
        }
    }
    
    // Create info object
    let info = SimpleInfo(data: data, fit: fit, skills: skills)
    
    // Run calculation
    let ship = calculate(info: info)
    
    // Build output structure
    let output = Output(
        capacitor: OutputCapacitor(
            stable: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "capacitorDepletesIn") == -1.0,
            depletesIn: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "capacitorDepletesIn"),
            capacity: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "capacitorCapacity").rounded(.down),
            recharge: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "rechargeRate") / 1000.0,
            peak: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "capacitorPeakDelta"),
            percentage: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "capacitorPeakDeltaPercentage")
        ),
        offense: OutputOffense(
            dps: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "damagePerSecondWithoutReload"),
            dpsWithReload: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "damagePerSecondWithReload"),
            alpha: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "damageAlpha"),
            droneDps: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "droneDamagePerSecond")
        ),
        defense: OutputDefense(
            recharge: OutputDefenseRecharge(
                passive: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "passiveShieldRechargeRate"),
                shield: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "shieldBoostRate"),
                armor: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "armorRepairRate"),
                hull: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "hullRepairRate")
            ),
            shield: OutputDefenseShield(
                resist: OutputDefenseResist(
                    em: (1.0 - getAttributeByName(info: info, attributes: ship.hull.attributes, name: "shieldEmDamageResonance")) * 100.0,
                    therm: (1.0 - getAttributeByName(info: info, attributes: ship.hull.attributes, name: "shieldThermalDamageResonance")) * 100.0,
                    kin: (1.0 - getAttributeByName(info: info, attributes: ship.hull.attributes, name: "shieldKineticDamageResonance")) * 100.0,
                    expl: (1.0 - getAttributeByName(info: info, attributes: ship.hull.attributes, name: "shieldExplosiveDamageResonance")) * 100.0
                ),
                hp: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "shieldCapacity"),
                recharge: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "shieldRechargeRate") / 1000.0
            ),
            armor: OutputDefenseArmor(
                resist: OutputDefenseResist(
                    em: (1.0 - getAttributeByName(info: info, attributes: ship.hull.attributes, name: "armorEmDamageResonance")) * 100.0,
                    therm: (1.0 - getAttributeByName(info: info, attributes: ship.hull.attributes, name: "armorThermalDamageResonance")) * 100.0,
                    kin: (1.0 - getAttributeByName(info: info, attributes: ship.hull.attributes, name: "armorKineticDamageResonance")) * 100.0,
                    expl: (1.0 - getAttributeByName(info: info, attributes: ship.hull.attributes, name: "armorExplosiveDamageResonance")) * 100.0
                ),
                hp: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "armorHP")
            ),
            structure: OutputDefenseStructure(
                resist: OutputDefenseResist(
                    em: (1.0 - getAttributeByName(info: info, attributes: ship.hull.attributes, name: "emDamageResonance")) * 100.0,
                    therm: (1.0 - getAttributeByName(info: info, attributes: ship.hull.attributes, name: "thermalDamageResonance")) * 100.0,
                    kin: (1.0 - getAttributeByName(info: info, attributes: ship.hull.attributes, name: "kineticDamageResonance")) * 100.0,
                    expl: (1.0 - getAttributeByName(info: info, attributes: ship.hull.attributes, name: "explosiveDamageResonance")) * 100.0
                ),
                hp: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "hp")
            ),
            ehp: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "ehp")
        ),
        targeting: OutputTargeting(
            lockRange: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "maxTargetRange") / 1000.0,
            sensorStrength: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "scanStrength"),
            scanResolution: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "scanResolution"),
            signatureRadius: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "signatureRadius"),
            maxLockedTargets: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "maxLockedTargets")
        ),
        navigation: OutputNavigation(
            speed: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "maxVelocity"),
            mass: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "mass") / 1000.0,
            agility: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "agility"),
            warpSpeed: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "warpSpeedMultiplier"),
            alignTime: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "alignTime")
        ),
        drones: OutputDrones(
            dps: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "droneDamagePerSecond"),
            bandwidthLoad: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "droneBandwidthLoad"),
            bandwidth: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "droneBandwidth"),
            range: getAttributeByName(info: info, attributes: ship.char.attributes, name: "droneControlDistance") / 1000.0,
            active: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "droneActive"),
            capacityLoad: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "droneCapacityLoad"),
            capacity: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "droneCapacity")
        ),
        cpu: OutputCpu(
            free: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "cpuFree"),
            capacity: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "cpuOutput")
        ),
        power: OutputPower(
            free: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "powerFree"),
            capacity: getAttributeByName(info: info, attributes: ship.hull.attributes, name: "powerOutput")
        ),
        slots: OutputSlots(
            hi1: effectCategoryToName(items: ship.items, slotType: .high, index: 0),
            hi2: effectCategoryToName(items: ship.items, slotType: .high, index: 1),
            hi3: effectCategoryToName(items: ship.items, slotType: .high, index: 2),
            hi4: effectCategoryToName(items: ship.items, slotType: .high, index: 3),
            hi5: effectCategoryToName(items: ship.items, slotType: .high, index: 4),
            hi6: effectCategoryToName(items: ship.items, slotType: .high, index: 5),
            hi7: effectCategoryToName(items: ship.items, slotType: .high, index: 6),
            hi8: effectCategoryToName(items: ship.items, slotType: .high, index: 7),
            med1: effectCategoryToName(items: ship.items, slotType: .medium, index: 0),
            med2: effectCategoryToName(items: ship.items, slotType: .medium, index: 1),
            med3: effectCategoryToName(items: ship.items, slotType: .medium, index: 2),
            med4: effectCategoryToName(items: ship.items, slotType: .medium, index: 3),
            med5: effectCategoryToName(items: ship.items, slotType: .medium, index: 4),
            med6: effectCategoryToName(items: ship.items, slotType: .medium, index: 5),
            med7: effectCategoryToName(items: ship.items, slotType: .medium, index: 6),
            med8: effectCategoryToName(items: ship.items, slotType: .medium, index: 7),
            lo1: effectCategoryToName(items: ship.items, slotType: .low, index: 0),
            lo2: effectCategoryToName(items: ship.items, slotType: .low, index: 1),
            lo3: effectCategoryToName(items: ship.items, slotType: .low, index: 2),
            lo4: effectCategoryToName(items: ship.items, slotType: .low, index: 3),
            lo5: effectCategoryToName(items: ship.items, slotType: .low, index: 4),
            lo6: effectCategoryToName(items: ship.items, slotType: .low, index: 5),
            lo7: effectCategoryToName(items: ship.items, slotType: .low, index: 6),
            lo8: effectCategoryToName(items: ship.items, slotType: .low, index: 7)
        )
    )
    
    return output
}

// Helper function to parse state character to EsfState
private func parseState(_ char: Character) -> EsfState {
    switch char {
    case "P": return .passive
    case "O": return .online
    case "A": return .active
    case "V": return .overload
    default: return .active
    }
}
