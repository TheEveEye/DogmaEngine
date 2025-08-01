//
//  ResistanceHPTests.swift
//  DogmaEngine Tests
//
//  Created on August 1, 2025.
//

import Testing
@testable import DogmaEngine

/// Tests to check resistance and HP calculations for fitted ships
struct ResistanceHPTests {
    
    @Test func testRifterResistancesAndHPWithNoSkills() async throws {
        let data = try TestHelpers.loadVerifiedSDEData()
        let standardFit = TestHelpers.getStandardRifterFit()
        
        // Verify all modules exist in the data
        try standardFit.verifyAllModules(in: data)
        
        // Create a complete fitting with all 13 modules
        let modules = [
            // High slots - 3x 200mm AutoCannon II
            EsfModule(typeID: standardFit.highSlot1TypeID, slot: EsfSlot(type: .high, index: 0), state: .active, charge: nil),
            EsfModule(typeID: standardFit.highSlot2TypeID, slot: EsfSlot(type: .high, index: 1), state: .active, charge: nil),
            EsfModule(typeID: standardFit.highSlot3TypeID, slot: EsfSlot(type: .high, index: 2), state: .active, charge: nil),
            
            // Mid slots
            EsfModule(typeID: standardFit.midSlot1TypeID, slot: EsfSlot(type: .medium, index: 0), state: .active, charge: nil), // 5MN Microwarpdrive II
            EsfModule(typeID: standardFit.midSlot2TypeID, slot: EsfSlot(type: .medium, index: 1), state: .active, charge: nil), // Warp Scrambler II
            EsfModule(typeID: standardFit.midSlot3TypeID, slot: EsfSlot(type: .medium, index: 2), state: .active, charge: nil), // Stasis Webifier II
            
            // Low slots
            EsfModule(typeID: standardFit.lowSlot1TypeID, slot: EsfSlot(type: .low, index: 0), state: .active, charge: nil), // Damage Control II
            EsfModule(typeID: standardFit.lowSlot2TypeID, slot: EsfSlot(type: .low, index: 1), state: .active, charge: nil), // Multispectrum Coating II
            EsfModule(typeID: standardFit.lowSlot3TypeID, slot: EsfSlot(type: .low, index: 2), state: .active, charge: nil), // Small Ancillary Armor Repairer
            EsfModule(typeID: standardFit.lowSlot4TypeID, slot: EsfSlot(type: .low, index: 3), state: .active, charge: nil), // 200mm Steel Plates II
            
            // Rig slots
            EsfModule(typeID: standardFit.rigSlot1TypeID, slot: EsfSlot(type: .rig, index: 0), state: .active, charge: nil), // Small Projectile Burst Aerator I
            EsfModule(typeID: standardFit.rigSlot2TypeID, slot: EsfSlot(type: .rig, index: 1), state: .active, charge: nil), // Small Projectile Ambit Extension I
            EsfModule(typeID: standardFit.rigSlot3TypeID, slot: EsfSlot(type: .rig, index: 2), state: .active, charge: nil), // Small Semiconductor Memory Cell I
        ]
        
        let fit = EsfFit(shipTypeID: standardFit.rifterTypeID, modules: modules, drones: [])
        
        // Test with no skills
        let info = SimpleInfo(data: data, fit: fit, skills: [:])
        let ship = calculate(info: info)
        
        // Shield attributes (resonance values, where 1.0 = 0% resist, 0.5 = 50% resist)
        let shieldEmResonance = ship.hull.attributes[271]?.value ?? 1.0
        let shieldThermalResonance = ship.hull.attributes[274]?.value ?? 1.0  
        let shieldKineticResonance = ship.hull.attributes[273]?.value ?? 1.0
        let shieldExplosiveResonance = ship.hull.attributes[272]?.value ?? 1.0
        let shieldHP = ship.hull.attributes[263]?.value ?? 0
        
        // Armor attributes
        let armorEmResonance = ship.hull.attributes[267]?.value ?? 1.0
        let armorThermalResonance = ship.hull.attributes[270]?.value ?? 1.0
        let armorKineticResonance = ship.hull.attributes[269]?.value ?? 1.0
        let armorExplosiveResonance = ship.hull.attributes[268]?.value ?? 1.0
        let armorHP = ship.hull.attributes[265]?.value ?? 0
        
        // Hull/Structure attributes
        let hullEmResonance = ship.hull.attributes[113]?.value ?? 1.0
        let hullThermalResonance = ship.hull.attributes[110]?.value ?? 1.0
        let hullKineticResonance = ship.hull.attributes[109]?.value ?? 1.0
        let hullExplosiveResonance = ship.hull.attributes[111]?.value ?? 1.0
        let hullHP = ship.hull.attributes[9]?.value ?? 0
        
        // Convert resonance to resistance percentages (resistance = (1 - resonance) * 100)
        let shieldEmResist = (1.0 - shieldEmResonance) * 100.0
        let shieldThermalResist = (1.0 - shieldThermalResonance) * 100.0
        let shieldKineticResist = (1.0 - shieldKineticResonance) * 100.0
        let shieldExplosiveResist = (1.0 - shieldExplosiveResonance) * 100.0
        
        let armorEmResist = (1.0 - armorEmResonance) * 100.0
        let armorThermalResist = (1.0 - armorThermalResonance) * 100.0
        let armorKineticResist = (1.0 - armorKineticResonance) * 100.0
        let armorExplosiveResist = (1.0 - armorExplosiveResonance) * 100.0
        
        let hullEmResist = (1.0 - hullEmResonance) * 100.0
        let hullThermalResist = (1.0 - hullThermalResonance) * 100.0
        let hullKineticResist = (1.0 - hullKineticResonance) * 100.0
        let hullExplosiveResist = (1.0 - hullExplosiveResonance) * 100.0
        
        print("=== SHIELD RESISTANCES AND HP ===")
        print("Shield EM: \(String(format: "%.1f", shieldEmResist))%")
        print("Shield Thermal: \(String(format: "%.1f", shieldThermalResist))%")
        print("Shield Kinetic: \(String(format: "%.1f", shieldKineticResist))%")
        print("Shield Explosive: \(String(format: "%.1f", shieldExplosiveResist))%")
        print("Shield HP: \(Int(shieldHP))")
        
        print("=== ARMOR RESISTANCES AND HP ===")
        print("Armor EM: \(String(format: "%.1f", armorEmResist))%")
        print("Armor Thermal: \(String(format: "%.1f", armorThermalResist))%")
        print("Armor Kinetic: \(String(format: "%.1f", armorKineticResist))%")
        print("Armor Explosive: \(String(format: "%.1f", armorExplosiveResist))%")
        print("Armor HP: \(String(format: "%.2f", armorHP))k")
        
        print("=== HULL RESISTANCES AND HP ===")
        print("Hull EM: \(String(format: "%.1f", hullEmResist))%")
        print("Hull Thermal: \(String(format: "%.1f", hullThermalResist))%")
        print("Hull Kinetic: \(String(format: "%.1f", hullKineticResist))%")
        print("Hull Explosive: \(String(format: "%.1f", hullExplosiveResist))%")
        print("Hull HP: \(Int(hullHP))")
        
        // Expected values with no skills:
        // Shield: 12.5% EM, 30.0% Thermal, 47.5% Kinetic, 56.2% Explosive, 450 HP
        // Armor: 71.2% EM, 53.2% Thermal, 46.0% Kinetic, 35.3% Explosive, 1.05k HP  
        // Structure: 59.8% resists across the board, 350 HP
        
        let tolerance = 0.5 // Allow small tolerance for rounding
        
        // Shield expectations
        #expect(abs(shieldEmResist - 12.5) < tolerance, "Shield EM should be ~12.5%, got \(String(format: "%.1f", shieldEmResist))%")
        #expect(abs(shieldThermalResist - 30.0) < tolerance, "Shield Thermal should be ~30.0%, got \(String(format: "%.1f", shieldThermalResist))%")
        #expect(abs(shieldKineticResist - 47.5) < tolerance, "Shield Kinetic should be ~47.5%, got \(String(format: "%.1f", shieldKineticResist))%")
        #expect(abs(shieldExplosiveResist - 56.2) < tolerance, "Shield Explosive should be ~56.2%, got \(String(format: "%.1f", shieldExplosiveResist))%")
        #expect(abs(shieldHP - 450) < 1, "Shield HP should be ~450, got \(Int(shieldHP))")
        
        // Armor expectations  
        #expect(abs(armorEmResist - 71.2) < tolerance, "Armor EM should be ~71.2%, got \(String(format: "%.1f", armorEmResist))%")
        #expect(abs(armorThermalResist - 53.2) < tolerance, "Armor Thermal should be ~53.2%, got \(String(format: "%.1f", armorThermalResist))%")
        #expect(abs(armorKineticResist - 46.0) < tolerance, "Armor Kinetic should be ~46.0%, got \(String(format: "%.1f", armorKineticResist))%")
        #expect(abs(armorExplosiveResist - 35.3) < tolerance, "Armor Explosive should be ~35.3%, got \(String(format: "%.1f", armorExplosiveResist))%")
        #expect(abs(armorHP - 1050) < 50, "Armor HP should be ~1.05k, got \(String(format: "%.2f", armorHP))k")
        
        // Hull expectations
        #expect(abs(hullEmResist - 59.8) < tolerance, "Hull EM should be ~59.8%, got \(String(format: "%.1f", hullEmResist))%")
        #expect(abs(hullThermalResist - 59.8) < tolerance, "Hull Thermal should be ~59.8%, got \(String(format: "%.1f", hullThermalResist))%")
        #expect(abs(hullKineticResist - 59.8) < tolerance, "Hull Kinetic should be ~59.8%, got \(String(format: "%.1f", hullKineticResist))%")
        #expect(abs(hullExplosiveResist - 59.8) < tolerance, "Hull Explosive should be ~59.8%, got \(String(format: "%.1f", hullExplosiveResist))%")
        #expect(abs(hullHP - 350) < 10, "Hull HP should be ~350, got \(Int(hullHP))")
    }
    
    @Test func testRifterResistancesAndHPWithAllSkillsLevel5() async throws {
        let data = try TestHelpers.loadVerifiedSDEData()
        let standardFit = TestHelpers.getStandardRifterFit()
        
        // Verify all modules exist in the data
        try standardFit.verifyAllModules(in: data)
        
        // Create a complete fitting with all 13 modules
        let modules = [
            // High slots - 3x 200mm AutoCannon II
            EsfModule(typeID: standardFit.highSlot1TypeID, slot: EsfSlot(type: .high, index: 0), state: .active, charge: nil),
            EsfModule(typeID: standardFit.highSlot2TypeID, slot: EsfSlot(type: .high, index: 1), state: .active, charge: nil),
            EsfModule(typeID: standardFit.highSlot3TypeID, slot: EsfSlot(type: .high, index: 2), state: .active, charge: nil),
            
            // Mid slots
            EsfModule(typeID: standardFit.midSlot1TypeID, slot: EsfSlot(type: .medium, index: 0), state: .active, charge: nil), // 5MN Microwarpdrive II
            EsfModule(typeID: standardFit.midSlot2TypeID, slot: EsfSlot(type: .medium, index: 1), state: .active, charge: nil), // Warp Scrambler II
            EsfModule(typeID: standardFit.midSlot3TypeID, slot: EsfSlot(type: .medium, index: 2), state: .active, charge: nil), // Stasis Webifier II
            
            // Low slots
            EsfModule(typeID: standardFit.lowSlot1TypeID, slot: EsfSlot(type: .low, index: 0), state: .active, charge: nil), // Damage Control II
            EsfModule(typeID: standardFit.lowSlot2TypeID, slot: EsfSlot(type: .low, index: 1), state: .active, charge: nil), // Multispectrum Coating II
            EsfModule(typeID: standardFit.lowSlot3TypeID, slot: EsfSlot(type: .low, index: 2), state: .active, charge: nil), // Small Ancillary Armor Repairer
            EsfModule(typeID: standardFit.lowSlot4TypeID, slot: EsfSlot(type: .low, index: 3), state: .active, charge: nil), // 200mm Steel Plates II
            
            // Rig slots
            EsfModule(typeID: standardFit.rigSlot1TypeID, slot: EsfSlot(type: .rig, index: 0), state: .active, charge: nil), // Small Projectile Burst Aerator I
            EsfModule(typeID: standardFit.rigSlot2TypeID, slot: EsfSlot(type: .rig, index: 1), state: .active, charge: nil), // Small Projectile Ambit Extension I
            EsfModule(typeID: standardFit.rigSlot3TypeID, slot: EsfSlot(type: .rig, index: 2), state: .active, charge: nil), // Small Semiconductor Memory Cell I
        ]
        
        let fit = EsfFit(shipTypeID: standardFit.rifterTypeID, modules: modules, drones: [])
        
        // Test with all skills at level 5
        let allSkillsLevel5 = TestHelpers.getAllSkillsAtLevel5(from: data)
        let info = SimpleInfo(data: data, fit: fit, skills: allSkillsLevel5)
        let ship = calculate(info: info)
        
        // Shield attributes (resonance values, where 1.0 = 0% resist, 0.5 = 50% resist)
        let shieldEmResonance = ship.hull.attributes[271]?.value ?? 1.0
        let shieldThermalResonance = ship.hull.attributes[274]?.value ?? 1.0  
        let shieldKineticResonance = ship.hull.attributes[273]?.value ?? 1.0
        let shieldExplosiveResonance = ship.hull.attributes[272]?.value ?? 1.0
        let shieldHP = ship.hull.attributes[263]?.value ?? 0
        
        // Armor attributes
        let armorEmResonance = ship.hull.attributes[267]?.value ?? 1.0
        let armorThermalResonance = ship.hull.attributes[270]?.value ?? 1.0
        let armorKineticResonance = ship.hull.attributes[269]?.value ?? 1.0
        let armorExplosiveResonance = ship.hull.attributes[268]?.value ?? 1.0
        let armorHP = ship.hull.attributes[265]?.value ?? 0
        
        // Hull/Structure attributes
        let hullEmResonance = ship.hull.attributes[113]?.value ?? 1.0
        let hullThermalResonance = ship.hull.attributes[110]?.value ?? 1.0
        let hullKineticResonance = ship.hull.attributes[109]?.value ?? 1.0
        let hullExplosiveResonance = ship.hull.attributes[111]?.value ?? 1.0
        let hullHP = ship.hull.attributes[9]?.value ?? 0
        
        // Convert resonance to resistance percentages (resistance = (1 - resonance) * 100)
        let shieldEmResist = (1.0 - shieldEmResonance) * 100.0
        let shieldThermalResist = (1.0 - shieldThermalResonance) * 100.0
        let shieldKineticResist = (1.0 - shieldKineticResonance) * 100.0
        let shieldExplosiveResist = (1.0 - shieldExplosiveResonance) * 100.0
        
        let armorEmResist = (1.0 - armorEmResonance) * 100.0
        let armorThermalResist = (1.0 - armorThermalResonance) * 100.0
        let armorKineticResist = (1.0 - armorKineticResonance) * 100.0
        let armorExplosiveResist = (1.0 - armorExplosiveResonance) * 100.0
        
        let hullEmResist = (1.0 - hullEmResonance) * 100.0
        let hullThermalResist = (1.0 - hullThermalResonance) * 100.0
        let hullKineticResist = (1.0 - hullKineticResonance) * 100.0
        let hullExplosiveResist = (1.0 - hullExplosiveResonance) * 100.0
        
        print("=== SHIELD RESISTANCES AND HP (ALL SKILLS LEVEL 5) ===")
        print("Shield EM: \(String(format: "%.1f", shieldEmResist))%")
        print("Shield Thermal: \(String(format: "%.1f", shieldThermalResist))%")
        print("Shield Kinetic: \(String(format: "%.1f", shieldKineticResist))%")
        print("Shield Explosive: \(String(format: "%.1f", shieldExplosiveResist))%")
        print("Shield HP: \(Int(shieldHP))")
        
        print("=== ARMOR RESISTANCES AND HP (ALL SKILLS LEVEL 5) ===")
        print("Armor EM: \(String(format: "%.1f", armorEmResist))%")
        print("Armor Thermal: \(String(format: "%.1f", armorThermalResist))%")
        print("Armor Kinetic: \(String(format: "%.1f", armorKineticResist))%")
        print("Armor Explosive: \(String(format: "%.1f", armorExplosiveResist))%")
        print("Armor HP: \(String(format: "%.2f", armorHP))k")
        
        print("=== HULL RESISTANCES AND HP (ALL SKILLS LEVEL 5) ===")
        print("Hull EM: \(String(format: "%.1f", hullEmResist))%")
        print("Hull Thermal: \(String(format: "%.1f", hullThermalResist))%")
        print("Hull Kinetic: \(String(format: "%.1f", hullKineticResist))%")
        print("Hull Explosive: \(String(format: "%.1f", hullExplosiveResist))%")
        print("Hull HP: \(Int(hullHP))")
        
        // Expected values with all skills at level 5:
        // Shield: 12.5% EM, 30.0% Thermal, 47.5% Kinetic, 56.2% Explosive, 562 HP
        // Armor: 72.5% EM, 55.4% Thermal, 48.5% Kinetic, 38.2% Explosive, 1.31k HP  
        // Structure: 59.8% resists across the board, 438 HP
        
        let tolerance = 0.5 // Allow small tolerance for rounding
        
        // Shield expectations
        #expect(abs(shieldEmResist - 12.5) < tolerance, "Shield EM should be ~12.5%, got \(String(format: "%.1f", shieldEmResist))%")
        #expect(abs(shieldThermalResist - 30.0) < tolerance, "Shield Thermal should be ~30.0%, got \(String(format: "%.1f", shieldThermalResist))%")
        #expect(abs(shieldKineticResist - 47.5) < tolerance, "Shield Kinetic should be ~47.5%, got \(String(format: "%.1f", shieldKineticResist))%")
        #expect(abs(shieldExplosiveResist - 56.2) < tolerance, "Shield Explosive should be ~56.2%, got \(String(format: "%.1f", shieldExplosiveResist))%")
        #expect(abs(shieldHP - 562) < 5, "Shield HP should be ~562, got \(Int(shieldHP))")
        
        // Armor expectations  
        #expect(abs(armorEmResist - 72.5) < tolerance, "Armor EM should be ~72.5%, got \(String(format: "%.1f", armorEmResist))%")
        #expect(abs(armorThermalResist - 55.4) < tolerance, "Armor Thermal should be ~55.4%, got \(String(format: "%.1f", armorThermalResist))%")
        #expect(abs(armorKineticResist - 48.5) < tolerance, "Armor Kinetic should be ~48.5%, got \(String(format: "%.1f", armorKineticResist))%")
        #expect(abs(armorExplosiveResist - 38.2) < tolerance, "Armor Explosive should be ~38.2%, got \(String(format: "%.1f", armorExplosiveResist))%")
        #expect(abs(armorHP - 1310) < 50, "Armor HP should be ~1.31k, got \(String(format: "%.2f", armorHP))k")
        
        // Hull expectations
        #expect(abs(hullEmResist - 59.8) < tolerance, "Hull EM should be ~59.8%, got \(String(format: "%.1f", hullEmResist))%")
        #expect(abs(hullThermalResist - 59.8) < tolerance, "Hull Thermal should be ~59.8%, got \(String(format: "%.1f", hullThermalResist))%")
        #expect(abs(hullKineticResist - 59.8) < tolerance, "Hull Kinetic should be ~59.8%, got \(String(format: "%.1f", hullKineticResist))%")
        #expect(abs(hullExplosiveResist - 59.8) < tolerance, "Hull Explosive should be ~59.8%, got \(String(format: "%.1f", hullExplosiveResist))%")
        #expect(abs(hullHP - 438) < 10, "Hull HP should be ~438, got \(Int(hullHP))")
    }
}
