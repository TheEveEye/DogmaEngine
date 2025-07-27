//
//  DataTypes.swift
//  dogma-engine

//  Created by Oskar on 7/25/25.

import Foundation

public struct `Type`: Codable {
    public var groupID: Int
    public var categoryID: Int? // This will be resolved from groups
    public var basePrice: Double?
    public var graphicID: Int?
    public var iconID: Int?
    public var portionSize: Int?
    public var published: Bool?
    public var raceID: Int?
    public var radius: Double?
    public var volume: Double?
    // Note: description and name are complex objects in JSON, not included for simplicity
    
    // Computed property to get categoryID with fallback
    public var resolvedCategoryID: Int {
        return categoryID ?? 0
    }
}

public struct Group: Codable {
    var categoryID: Int
    var anchorable: Bool?
    var anchored: Bool?
    var fittableNonSingleton: Bool?
    var published: Bool?
    var useBasePrice: Bool?
}

public struct TypeDogmaAttribute: Codable {
    var attributeID: Int
    var value: Double
}

public struct TypeDogmaEffect: Codable {
    var effectID: Int
    var isDefault: Bool
}

public struct TypeDogma: Codable {
    var dogmaAttributes: [TypeDogmaAttribute]
    var dogmaEffects: [TypeDogmaEffect]
}

public struct DogmaAttribute: Codable {
    var attributeID: Int?
    var categoryID: Int?
    var dataType: Int?
    var defaultValue: Double
    var highIsGood: Bool
    var iconID: Int?
    var published: Bool?
    var stackable: Bool
    var unitID: Int?
    // Note: description, displayNameID, and name are complex/optional, not included for simplicity
}

enum DogmaEffectModifierInfoDomain: String, Codable {
    case itemID = "itemID"
    case shipID = "shipID"
    case charID = "charID"
    case otherID = "otherID"
    case structureID = "structureID"
    case target = "target"
    case targetID = "targetID"
}

enum DogmaEffectModifierInfoFunc: String, Codable {
    case itemModifier = "ItemModifier"
    case locationGroupModifier = "LocationGroupModifier"
    case locationModifier = "LocationModifier"
    case locationRequiredSkillModifier = "LocationRequiredSkillModifier"
    case ownerRequiredSkillModifier = "OwnerRequiredSkillModifier"
    case effectStopper = "EffectStopper"
}

struct DogmaEffectModifierInfo: Codable {
    var domain: DogmaEffectModifierInfoDomain
    var `func`: DogmaEffectModifierInfoFunc
    var modifiedAttributeID: Int?
    var modifyingAttributeID: Int?
    var operation: Int?
    var groupID: Int?
    // Note: skillTypeID not present in actual JSON, removed
}

public struct DogmaEffect: Codable {
    var descriptionID: [String: String]? // Complex object with language keys
    var disallowAutoRepeat: Bool?
    var effectCategory: Int?
    var effectID: Int?
    var effectName: String?
    var electronicChance: Bool
    var isAssistance: Bool
    var isOffensive: Bool
    var isWarpSafe: Bool
    var modifierInfo: [DogmaEffectModifierInfo]? // Made optional
    var propulsionChance: Bool
    var published: Bool?
    var rangeChance: Bool
}

public enum EsfState: Codable {
    case passive, online, active, overload
}

public enum EsfSlotType: Codable {
    case high, medium, low, rig, subSystem, service
}

public struct EsfCharge: Codable {
    var typeID: Int
    
    public init(typeID: Int) {
        self.typeID = typeID
    }
}

public struct EsfSlot: Codable {
    var type: EsfSlotType
    var index: Int
    
    public init(type: EsfSlotType, index: Int) {
        self.type = type
        self.index = index
    }
}

public struct EsfModule: Codable {
    var typeID: Int
    var slot: EsfSlot
    var state: EsfState
    var charge: EsfCharge?
    
    public init(typeID: Int, slot: EsfSlot, state: EsfState, charge: EsfCharge?) {
        self.typeID = typeID
        self.slot = slot
        self.state = state
        self.charge = charge
    }
}

public struct EsfDrone: Codable {
    var typeID: Int
    var state: EsfState
    
    public init(typeID: Int, state: EsfState) {
        self.typeID = typeID
        self.state = state
    }
}

public struct EsfFit {
    public var shipTypeID: Int
    public var modules: [EsfModule]
    public var drones: [EsfDrone]
    
    public init(shipTypeID: Int, modules: [EsfModule], drones: [EsfDrone]) {
        self.shipTypeID = shipTypeID
        self.modules = modules
        self.drones = drones
    }
}

extension DogmaEffectModifierInfoDomain {
    init(_ rawValue: Int) {
        switch rawValue {
        case 0: self = .itemID
        case 1: self = .shipID
        case 2: self = .charID
        case 3: self = .otherID
        case 4: self = .structureID
        case 5: self = .target
        case 6: self = .targetID
        default: self = .itemID
        }
    }
}

extension DogmaEffectModifierInfoFunc {
    init(_ rawValue: Int) {
        switch rawValue {
        case 0: self = .itemModifier
        case 1: self = .locationGroupModifier
        case 2: self = .locationModifier
        case 3: self = .locationRequiredSkillModifier
        case 4: self = .ownerRequiredSkillModifier
        case 5: self = .effectStopper
        default: self = .itemModifier
        }
    }
}
