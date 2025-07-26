//
//  DataTypes.swift
//  dogma-engine

//  Created by Oskar on 7/25/25.

import Foundation

struct `Type`: Codable {
    var groupID: Int
    var categoryID: Int
    var capacity: Double?
    var mass: Double?
    var radius: Double?
    var volume: Double?
}

struct TypeDogmaAttribute: Codable {
    var attributeID: Int
    var value: Double
}

struct TypeDogmaEffect: Codable {
    var effectID: Int
    var isDefault: Bool
}

struct DogmaAttribute: Codable {
    var defaultValue: Double
    var highIsGood: Bool
    var stackable: Bool
}

enum DogmaEffectModifierInfoDomain: Int, Codable {
    case itemID = 0
    case shipID = 1
    case charID = 2
    case otherID = 3
    case structureID = 4
    case target = 5
    case targetID = 6
}

enum DogmaEffectModifierInfoFunc: Int, Codable {
    case itemModifier = 0
    case locationGroupModifier = 1
    case locationModifier = 2
    case locationRequiredSkillModifier = 3
    case ownerRequiredSkillModifier = 4
    case effectStopper = 5
}

struct DogmaEffectModifierInfo: Codable {
    var domain: DogmaEffectModifierInfoDomain
    var `func`: DogmaEffectModifierInfoFunc
    var modifiedAttributeID: Int?
    var modifyingAttributeID: Int?
    var operation: Int?
    var groupID: Int?
    var skillTypeID: Int?
}

struct DogmaEffect: Codable {
    var dischargeAttributeID: Int?
    var durationAttributeID: Int?
    var effectCategory: Int
    var electronicChance: Bool
    var isAssistance: Bool
    var isOffensive: Bool
    var isWarpSafe: Bool
    var propulsionChance: Bool
    var rangeChance: Bool
    var rangeAttributeID: Int?
    var falloffAttributeID: Int?
    var trackingSpeedAttributeID: Int?
    var fittingUsageChanceAttributeID: Int?
    var resistanceAttributeID: Int?
    var modifierInfo: [DogmaEffectModifierInfo]
}

enum EsfState: Codable {
    case passive, online, active, overload
}

enum EsfSlotType: Codable {
    case high, medium, low, rig, subSystem, service
}

struct EsfCharge: Codable {
    var typeID: Int
}

struct EsfSlot: Codable {
    var type: EsfSlotType
    var index: Int
}

struct EsfModule: Codable {
    var typeID: Int
    var slot: EsfSlot
    var state: EsfState
    var charge: EsfCharge?
}

struct EsfDrone: Codable {
    var typeID: Int
    var state: EsfState
}

struct EsfFit: Codable {
    var shipTypeID: Int
    var modules: [EsfModule]
    var drones: [EsfDrone]
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
