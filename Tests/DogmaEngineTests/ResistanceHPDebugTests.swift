//
//  ResistanceHPDebugTests.swift
//  DogmaEngine Tests
//

import Testing
@testable import DogmaEngine

/// Debug test to understand resistance calculations
struct ResistanceHPDebugTests {
    
    @Test func debugRifterBaseResistances() async throws {
        let data = try TestHelpers.loadVerifiedSDEData()
        let standardFit = TestHelpers.getStandardRifterFit()
        
        // Test bare Rifter (no modules)
        let fit = EsfFit(shipTypeID: standardFit.rifterTypeID, modules: [], drones: [])
        let info = SimpleInfo(data: data, fit: fit, skills: [:])
        let ship = calculate(info: info)
        
        print("=== BARE RIFTER (NO MODULES) ===")
        
        // Shield
        let shieldEmResonance = ship.hull.attributes[271]?.value ?? 1.0
        let shieldThermalResonance = ship.hull.attributes[274]?.value ?? 1.0  
        let shieldKineticResonance = ship.hull.attributes[273]?.value ?? 1.0
        let shieldExplosiveResonance = ship.hull.attributes[272]?.value ?? 1.0
        let shieldHP = ship.hull.attributes[263]?.value ?? 0
        
        print("Shield resonances: EM=\(shieldEmResonance), Thermal=\(shieldThermalResonance), Kinetic=\(shieldKineticResonance), Explosive=\(shieldExplosiveResonance)")
        print("Shield resistances: EM=\((1-shieldEmResonance)*100)%, Thermal=\((1-shieldThermalResonance)*100)%, Kinetic=\((1-shieldKineticResonance)*100)%, Explosive=\((1-shieldExplosiveResonance)*100)%")
        print("Shield HP: \(shieldHP)")
        
        // Armor
        let armorEmResonance = ship.hull.attributes[267]?.value ?? 1.0
        let armorThermalResonance = ship.hull.attributes[270]?.value ?? 1.0
        let armorKineticResonance = ship.hull.attributes[269]?.value ?? 1.0
        let armorExplosiveResonance = ship.hull.attributes[268]?.value ?? 1.0
        let armorHP = ship.hull.attributes[265]?.value ?? 0
        
        print("Armor resonances: EM=\(armorEmResonance), Thermal=\(armorThermalResonance), Kinetic=\(armorKineticResonance), Explosive=\(armorExplosiveResonance)")
        print("Armor resistances: EM=\((1-armorEmResonance)*100)%, Thermal=\((1-armorThermalResonance)*100)%, Kinetic=\((1-armorKineticResonance)*100)%, Explosive=\((1-armorExplosiveResonance)*100)%")
        print("Armor HP: \(armorHP)")
        
        // Hull
        let hullEmResonance = ship.hull.attributes[113]?.value ?? 1.0
        let hullThermalResonance = ship.hull.attributes[110]?.value ?? 1.0
        let hullKineticResonance = ship.hull.attributes[109]?.value ?? 1.0
        let hullExplosiveResonance = ship.hull.attributes[111]?.value ?? 1.0
        let hullHP = ship.hull.attributes[9]?.value ?? 0
        
        print("Hull resonances: EM=\(hullEmResonance), Thermal=\(hullThermalResonance), Kinetic=\(hullKineticResonance), Explosive=\(hullExplosiveResonance)")
        print("Hull resistances: EM=\((1-hullEmResonance)*100)%, Thermal=\((1-hullThermalResonance)*100)%, Kinetic=\((1-hullKineticResonance)*100)%, Explosive=\((1-hullExplosiveResonance)*100)%")
        print("Hull HP: \(hullHP)")
    }
    
    @Test func debugRifterWithDamageControl() async throws {
        let data = try TestHelpers.loadVerifiedSDEData()
        let standardFit = TestHelpers.getStandardRifterFit()
        
        // Test Rifter with just Damage Control II
        let modules = [
            EsfModule(typeID: standardFit.lowSlot1TypeID, slot: EsfSlot(type: .low, index: 0), state: .active, charge: nil), // Damage Control II
        ]
        let fit = EsfFit(shipTypeID: standardFit.rifterTypeID, modules: modules, drones: [])
        let info = SimpleInfo(data: data, fit: fit, skills: [:])
        let ship = calculate(info: info)
        
        print("\n=== RIFTER WITH DAMAGE CONTROL II ===")
        
        // Check if module is present and active
        print("Number of modules: \(ship.items.count)")
        if ship.items.count > 0 {
            print("Module 0 type: \(ship.items[0].typeId)")
            print("Module 0 state: \(ship.items[0].state)")
            print("Module 0 maxState: \(ship.items[0].maxState)")
            print("Module 0 attributes count: \(ship.items[0].attributes.count)")
            
            // Check the effects on the module
            print("Module 0 effects count: \(ship.items[0].effects.count)")
            
            // Check if module has the resistance multiplier attributes
            if let dcII = ship.items.first {
                print("DC II attributes:")
                for (attrId, attr) in dcII.attributes {
                    if [267, 268, 269, 270, 271, 272, 273, 274, 974, 975, 976, 977].contains(attrId) {
                        print("  \(attrId): \(attr.value ?? attr.baseValue) (base: \(attr.baseValue))")
                    }
                }
                
                // Check dogma effects for this module
                let dogmaEffects = data.typeDogma[2048]?.dogmaEffects ?? []
                print("DC II has \(dogmaEffects.count) dogma effects:")
                for dogmaEffect in dogmaEffects {
                    if let effectData = data.dogmaEffects[dogmaEffect.effectID] {
                        let modifierCount = effectData.modifierInfo?.count ?? 0
                        print("  Effect \(dogmaEffect.effectID): \(effectData.effectName ?? "unnamed"), category: \(effectData.effectCategory ?? 0), modifiers: \(modifierCount)")
                        if let modifiers = effectData.modifierInfo {
                            for (idx, modifier) in modifiers.enumerated() {
                                print("    Modifier \(idx): domain=\(modifier.domain), func=\(modifier.func), operation=\(modifier.operation ?? -999), modifiedAttr=\(modifier.modifiedAttributeID ?? -1), modifyingAttr=\(modifier.modifyingAttributeID ?? -1)")
                            }
                        }
                    }
                }
            }
        }
        
        // Shield
        let shieldEmResonance = ship.hull.attributes[271]?.value ?? 1.0
        let shieldThermalResonance = ship.hull.attributes[274]?.value ?? 1.0  
        let shieldKineticResonance = ship.hull.attributes[273]?.value ?? 1.0
        let shieldExplosiveResonance = ship.hull.attributes[272]?.value ?? 1.0
        
        print("Shield resonances: EM=\(shieldEmResonance), Thermal=\(shieldThermalResonance), Kinetic=\(shieldKineticResonance), Explosive=\(shieldExplosiveResonance)")
        print("Shield resistances: EM=\((1-shieldEmResonance)*100)%, Thermal=\((1-shieldThermalResonance)*100)%, Kinetic=\((1-shieldKineticResonance)*100)%, Explosive=\((1-shieldExplosiveResonance)*100)%")
        
        // Armor
        let armorEmResonance = ship.hull.attributes[267]?.value ?? 1.0
        let armorThermalResonance = ship.hull.attributes[270]?.value ?? 1.0
        let armorKineticResonance = ship.hull.attributes[269]?.value ?? 1.0
        let armorExplosiveResonance = ship.hull.attributes[268]?.value ?? 1.0
        
        print("Armor resonances: EM=\(armorEmResonance), Thermal=\(armorThermalResonance), Kinetic=\(armorKineticResonance), Explosive=\(armorExplosiveResonance)")
        print("Armor resistances: EM=\((1-armorEmResonance)*100)%, Thermal=\((1-armorThermalResonance)*100)%, Kinetic=\((1-armorKineticResonance)*100)%, Explosive=\((1-armorExplosiveResonance)*100)%")
        
        // Hull
        let hullEmResonance = ship.hull.attributes[113]?.value ?? 1.0
        let hullThermalResonance = ship.hull.attributes[110]?.value ?? 1.0
        let hullKineticResonance = ship.hull.attributes[109]?.value ?? 1.0
        let hullExplosiveResonance = ship.hull.attributes[111]?.value ?? 1.0
        
        print("Hull resonances: EM=\(hullEmResonance), Thermal=\(hullThermalResonance), Kinetic=\(hullKineticResonance), Explosive=\(hullExplosiveResonance)")
        print("Hull resistances: EM=\((1-hullEmResonance)*100)%, Thermal=\((1-hullThermalResonance)*100)%, Kinetic=\((1-hullKineticResonance)*100)%, Explosive=\((1-hullExplosiveResonance)*100)%")
        
        // Check effects on hull attributes
        print("\n=== HULL ATTRIBUTE EFFECTS ===")
        let resistanceAttrIds = [267, 268, 269, 270, 271, 272, 273, 274, 109, 110, 111, 113]
        for attrId in resistanceAttrIds {
            if let attr = ship.hull.attributes[attrId] {
                print("Hull attr \(attrId): base=\(attr.baseValue), final=\(attr.value ?? attr.baseValue), value=\(String(describing: attr.value)), effects=\(attr.effects.count)")
                for (idx, effect) in attr.effects.enumerated() {
                    print("  Effect \(idx): op=\(effect.operator), source=\(effect.source), srcAttr=\(effect.sourceAttributeId)")
                }
            }
        }
    }
}
