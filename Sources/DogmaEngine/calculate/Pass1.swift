//
//  File.swift
//  dogma-engine
//
//  Created by Oskar on 7/25/25.
//

import Foundation

let ATTRIBUTE_MASS_ID: Int = 4
let ATTRIBUTE_CAPACITY_ID: Int = 38
let ATTRIBUTE_VOLUME_ID: Int = 161
let ATTRIBUTE_RADIUS_ID: Int = 162
let ATTRIBUTE_SKILL_LEVEL_ID: Int = 280

extension Item {
    // equivalent to `pub fn set_attribute`
    func setAttribute(attributeId: Int, value: Double) {
        attributes[attributeId] = Attribute(value)
    }

    // equivalent to `fn set_attributes`
    func setAttributes(from info: Info) {
        // dogma attributes
        for dogmaAttribute in info.getDogmaAttributes(typeId) {
            setAttribute(attributeId: dogmaAttribute.attributeID,
                         value: dogmaAttribute.value)
        }

        // some attributes come from Type info
        let typeInfo = info.getType(typeId)
        // Note: mass and capacity are not available in the current Type structure
        // They would need to be retrieved from dogma attributes if needed
        if let volume = typeInfo.volume {
            setAttribute(attributeId: ATTRIBUTE_VOLUME_ID, value: volume)
        }
        if let radius = typeInfo.radius {
            setAttribute(attributeId: ATTRIBUTE_RADIUS_ID, value: radius)
        }
    }
}

public struct PassOne: Pass {
    static func pass(info: Info, ship: inout Ship) {
        // set hull attributes
        ship.hull.setAttributes(from: info)

        // apply skills
        for (skillId, skillLevel) in info.skills() {
            let skill = Item.newFake(typeId: skillId)
            skill.setAttributes(from: info)
            skill.setAttribute(attributeId: ATTRIBUTE_SKILL_LEVEL_ID, value: Double(skillLevel))
            ship.skills.append(skill)
        }

        // apply modules
        for module in info.fit().modules {
            let state: EffectCategory
            switch module.state {
            case .passive:
                state = .passive
            case .online:
                state = .online
            case .active:
                state = .active
            case .overload:
                state = .overload
            }

            let slotType: SlotType
            switch module.slot.type {
            case .high:
                slotType = .high
            case .medium:
                slotType = .medium
            case .low:
                slotType = .low
            case .rig:
                slotType = .rig
            case .subSystem:
                slotType = .subSystem
            case .service:
                slotType = .service
            }

            let slot = Slot(type: slotType, index: module.slot.index)
            let item = Item.newModule(
                typeId: module.typeID,
                slot: slot,
                chargeTypeId: module.charge?.typeID,
                state: state
            )
            item.setAttributes(from: info)
            item.charge?.setAttributes(from: info)
            ship.items.append(item)
        }

        // apply drones
        for drone in info.fit().drones {
            let state: EffectCategory
            switch drone.state {
            case .passive:
                state = .passive
            default:
                state = .active
            }
            let item = Item.newDrone(typeId: drone.typeID, state: state)
            item.setAttributes(from: info)
            ship.items.append(item)
        }
    }
}
