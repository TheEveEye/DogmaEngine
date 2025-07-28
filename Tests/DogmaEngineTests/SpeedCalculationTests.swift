//
//  SpeedCalculationTests.swift
//  DogmaEngine Tests
//
//  Created by GitHub Copilot on 7/28/25.
//

import Testing
import Foundation
@testable import DogmaEngine

/// Tests for ship speed and propulsion module calculations
struct SpeedCalculationTests {
    
    @Test func testRifterWith5MNMicrowarpdriveMaxSpeed() async throws {
        // Load and verify SDE data
        let data = try TestHelpers.loadVerifiedSDEData()
        
        // Define and verify the items we're testing
        let rifterTypeID = 587
        let mwd1TypeID = 434 // 5MN Microwarpdrive I
        
        try TestHelpers.verifyTypeID(rifterTypeID, expectedName: "Rifter", in: data)
        try TestHelpers.verifyTypeID(mwd1TypeID, expectedName: "5MN Microwarpdrive I", in: data)
        
        // Create Rifter fit with 5MN Microwarpdrive I
        let modules = [
            EsfModule(typeID: mwd1TypeID, slot: EsfSlot(type: .medium, index: 0), state: .active, charge: nil)
        ]
        let fit = EsfFit(shipTypeID: rifterTypeID, modules: modules, drones: [])
        
        // Test with all skills at level 0 (empty skills dictionary) 
        let info = SimpleInfo(data: data, fit: fit, skills: [:])
        
        // Calculate ship stats
        let ship = calculate(info: info)
        
                // Debug velocity and mass attributes
        print("=== VELOCITY DEBUG INFO ===")
        for (attributeID, attribute) in ship.hull.attributes {
            if let dogmaAttr = data.dogmaAttributes[attributeID],
               let name = dogmaAttr.name,
               name.lowercased().contains("velocity") || name.lowercased().contains("speed") || name.lowercased().contains("warp") || name.lowercased().contains("mass") {
                let baseValue = attribute.baseValue
                let finalValue = attribute.value ?? baseValue
                print("[\(attributeID)] \(name): base=\(baseValue), final=\(finalValue)")
            }
        }
        
        // Check if MWD is fitted and active
        #expect(ship.items.count == 1, "Ship should have one fitted module")
        #expect(ship.items[0].typeId == mwd1TypeID, "Module should be 5MN Microwarpdrive I")
        #expect(ship.items[0].state >= .active, "MWD should be in active state or higher")
        
        // Get max velocity (attribute ID 37)
        guard let maxVelocity = ship.hull.attributes[37]?.value else {
            throw TestError.missingTestData("Max velocity attribute (37) not found")
        }
        
        print("Current calculated max velocity: \(maxVelocity) m/s")
        
        // The test expectation
        let expectedVelocity: Double = 2112.0
        let tolerance = 1.0 // Allow 1 m/s tolerance
        
        print("Expected max velocity: \(expectedVelocity) m/s")
        
        #expect(abs(maxVelocity - expectedVelocity) <= tolerance, 
                "Max velocity should be \(expectedVelocity) m/s (±\(tolerance)), but got \(maxVelocity) m/s")
        
        // Debug: Let's also check the MWD's attributes to understand the calculation
        print("=== MWD MODULE DEBUG INFO ===")
        if let mwdItem = ship.items.first {
            for (attributeID, attribute) in mwdItem.attributes.sorted(by: { $0.key < $1.key }) {
                if let attrInfo = data.dogmaAttributes[attributeID] {
                    let attrName = attrInfo.name ?? attrInfo.displayNameID?["en"] ?? "Unknown"
                    print("MWD [\(attributeID)] \(attrName): base=\(attribute.baseValue), final=\(attribute.value ?? 0)")
                }
            }
        }
        
        print("✅ Rifter with 5MN Microwarpdrive I max speed test completed")
    }
    
    @Test func testRifterBaseSpeed() async throws {
        // Test baseline: Rifter without any propulsion modules
        let data = try TestHelpers.loadVerifiedSDEData()
        
        let rifterTypeID = 587
        try TestHelpers.verifyTypeID(rifterTypeID, expectedName: "Rifter", in: data)
        
        // Create unfitted Rifter
        let fit = EsfFit(shipTypeID: rifterTypeID, modules: [], drones: [])
        let info = SimpleInfo(data: data, fit: fit, skills: [:])
        let ship = calculate(info: info)
        
        guard let baseVelocity = ship.hull.attributes[37]?.value else {
            throw TestError.missingTestData("Max velocity attribute (37) not found")
        }
        
        print("Rifter base max velocity: \(baseVelocity) m/s")
        
        // Rifter base speed should be around 350-400 m/s
        #expect(baseVelocity > 300 && baseVelocity < 500, 
                "Rifter base velocity should be reasonable for a frigate, got \(baseVelocity) m/s")
        
        print("✅ Rifter base speed test completed")
    }
    
    @Test func testRifterWithMWDAndOverdriveInjector() async throws {
        // Test Rifter with 5MN Microwarpdrive I + Overdrive Injector System I
        let data = try TestHelpers.loadVerifiedSDEData()
        
        // Define and verify the items we're testing
        let rifterTypeID = 587
        let mwd1TypeID = 434 // 5MN Microwarpdrive I
        let overdriveTypeID = 1244 // Overdrive Injector System I
        
        try TestHelpers.verifyTypeID(rifterTypeID, expectedName: "Rifter", in: data)
        try TestHelpers.verifyTypeID(mwd1TypeID, expectedName: "5MN Microwarpdrive I", in: data)
        try TestHelpers.verifyTypeID(overdriveTypeID, expectedName: "Overdrive Injector System I", in: data)
        
        // Create Rifter fit with MWD in medium slot and Overdrive in low slot
        let modules = [
            EsfModule(typeID: mwd1TypeID, slot: EsfSlot(type: .medium, index: 0), state: .active, charge: nil),
            EsfModule(typeID: overdriveTypeID, slot: EsfSlot(type: .low, index: 0), state: .online, charge: nil)
        ]
        let fit = EsfFit(shipTypeID: rifterTypeID, modules: modules, drones: [])
        
        // Test with all skills at level 0 (empty skills dictionary) 
        let info = SimpleInfo(data: data, fit: fit, skills: [:])
        
        // Calculate ship stats
        let ship = calculate(info: info)
        
        // Debug velocity and mass attributes
        print("=== VELOCITY DEBUG INFO ===")
        for (attributeID, attribute) in ship.hull.attributes {
            if let dogmaAttr = data.dogmaAttributes[attributeID],
               let name = dogmaAttr.name,
               name.lowercased().contains("velocity") || name.lowercased().contains("speed") || name.lowercased().contains("warp") || name.lowercased().contains("mass") {
                let baseValue = attribute.baseValue
                let finalValue = attribute.value ?? baseValue
                print("[\(attributeID)] \(name): base=\(baseValue), final=\(finalValue)")
            }
        }
        
        // Check if modules are fitted correctly
        #expect(ship.items.count == 2, "Ship should have two fitted modules")
        
        // Verify MWD is present and active
        let mwdModule = ship.items.first { $0.typeId == mwd1TypeID }
        #expect(mwdModule != nil, "MWD should be fitted")
        #expect(mwdModule?.state.rawValue ?? -1 >= EffectCategory.active.rawValue, "MWD should be in active state or higher")
        
        // Verify Overdrive is present and online
        let overdriveModule = ship.items.first { $0.typeId == overdriveTypeID }
        #expect(overdriveModule != nil, "Overdrive Injector should be fitted")
        #expect(overdriveModule?.state.rawValue ?? -1 >= EffectCategory.online.rawValue, "Overdrive Injector should be online or higher")
        
        // Get max velocity (attribute ID 37)
        guard let maxVelocity = ship.hull.attributes[37]?.value else {
            throw TestError.missingTestData("Max velocity attribute (37) not found")
        }
        
        print("Current calculated max velocity: \(maxVelocity) m/s")
        
        // The test expectation
        let expectedVelocity: Double = 2334.0
        let tolerance = 1.0 // Allow 1 m/s tolerance
        
        print("Expected max velocity: \(expectedVelocity) m/s")
        
        #expect(abs(maxVelocity - expectedVelocity) <= tolerance, 
                "Max velocity should be \(expectedVelocity) m/s (±\(tolerance)), but got \(maxVelocity) m/s")
        
        // Debug: Check both modules' attributes
        print("=== MODULE DEBUG INFO ===")
        for (index, module) in ship.items.enumerated() {
            let moduleName = data.types[module.typeId]?.name?["en"] ?? "Unknown"
            print("Module \(index + 1): \(moduleName) (ID: \(module.typeId))")
            
            for (attributeID, attribute) in module.attributes.sorted(by: { $0.key < $1.key }) {
                if let attrInfo = data.dogmaAttributes[attributeID] {
                    let attrName = attrInfo.name ?? attrInfo.displayNameID?["en"] ?? "Unknown"
                    if attrName.lowercased().contains("velocity") || attrName.lowercased().contains("speed") || attrName.lowercased().contains("max") {
                        print("  [\(attributeID)] \(attrName): base=\(attribute.baseValue), final=\(attribute.value ?? 0)")
                    }
                }
            }
        }
        
        print("✅ Rifter with MWD and Overdrive Injector speed test completed")
    }
    
    @Test func testRifterWithMWDAndOverdriveInjectorAllSkillsLevel5() async throws {
        // Test Rifter with 5MN Microwarpdrive I + Overdrive Injector System I with all skills at level 5
        let data = try TestHelpers.loadVerifiedSDEData()
        
        // Define and verify the items we're testing
        let rifterTypeID = 587
        let mwd1TypeID = 434 // 5MN Microwarpdrive I
        let overdriveTypeID = 1244 // Overdrive Injector System I
        
        try TestHelpers.verifyTypeID(rifterTypeID, expectedName: "Rifter", in: data)
        try TestHelpers.verifyTypeID(mwd1TypeID, expectedName: "5MN Microwarpdrive I", in: data)
        try TestHelpers.verifyTypeID(overdriveTypeID, expectedName: "Overdrive Injector System I", in: data)
        
        // Create Rifter fit with MWD in medium slot and Overdrive in low slot
        let modules = [
            EsfModule(typeID: mwd1TypeID, slot: EsfSlot(type: .medium, index: 0), state: .active, charge: nil),
            EsfModule(typeID: overdriveTypeID, slot: EsfSlot(type: .low, index: 0), state: .online, charge: nil)
        ]
        let fit = EsfFit(shipTypeID: rifterTypeID, modules: modules, drones: [])
        
        // Test with ALL skills at level 5
        let allSkillsLevel5 = TestHelpers.getAllSkillsAtLevel5(from: data)
        let info = SimpleInfo(data: data, fit: fit, skills: allSkillsLevel5)
        
        // Calculate ship stats
        let ship = calculate(info: info)
        
        // Debug velocity and mass attributes
        print("=== VELOCITY DEBUG INFO (ALL SKILLS LEVEL 5) ===")
        for (attributeID, attribute) in ship.hull.attributes {
            if let dogmaAttr = data.dogmaAttributes[attributeID],
               let name = dogmaAttr.name,
               name.lowercased().contains("velocity") || name.lowercased().contains("speed") || name.lowercased().contains("warp") || name.lowercased().contains("mass") {
                let baseValue = attribute.baseValue
                let finalValue = attribute.value ?? baseValue
                print("[\(attributeID)] \(name): base=\(baseValue), final=\(finalValue)")
            }
        }
        
        // Check if modules are fitted correctly
        #expect(ship.items.count == 2, "Ship should have two fitted modules")
        #expect(ship.skills.count == allSkillsLevel5.count, "All skills should be loaded")
        
        // Verify MWD is present and active
        let mwdModule = ship.items.first { $0.typeId == mwd1TypeID }
        #expect(mwdModule != nil, "MWD should be fitted")
        #expect(mwdModule?.state.rawValue ?? -1 >= EffectCategory.active.rawValue, "MWD should be in active state or higher")
        
        // Verify Overdrive is present and online
        let overdriveModule = ship.items.first { $0.typeId == overdriveTypeID }
        #expect(overdriveModule != nil, "Overdrive Injector should be fitted")
        #expect(overdriveModule?.state.rawValue ?? -1 >= EffectCategory.online.rawValue, "Overdrive Injector should be online or higher")
        
        // Get max velocity (attribute ID 37)
        guard let maxVelocity = ship.hull.attributes[37]?.value else {
            throw TestError.missingTestData("Max velocity attribute (37) not found")
        }
        
        print("Current calculated max velocity: \(maxVelocity) m/s")
        
        // The test expectation
        let expectedVelocity: Double = 3520.0
        let tolerance = 1.0 // Allow 1 m/s tolerance
        
        print("Expected max velocity: \(expectedVelocity) m/s")
        
        #expect(abs(maxVelocity - expectedVelocity) <= tolerance, 
                "Max velocity should be \(expectedVelocity) m/s (±\(tolerance)), but got \(maxVelocity) m/s")
        
        // Debug: Show some key skills that affect speed
        print("=== KEY SKILL DEBUG INFO ===")
        let speedRelatedSkills = [
            (3300, "Acceleration Control"),
            (3184, "Navigation"),
            (3453, "Evasive Maneuvering"),
            (3454, "High Speed Maneuvering")
        ]
        
        for (skillID, skillName) in speedRelatedSkills {
            if let skillItem = ship.skills.first(where: { $0.typeId == skillID }) {
                print("Skill: \(skillName) (ID: \(skillID)) - Level: \(skillItem.attributes[280]?.value ?? 0)")
            }
        }
        
        // Debug: Check both modules' attributes with skills applied
        print("=== MODULE DEBUG INFO (WITH SKILLS) ===")
        for (index, module) in ship.items.enumerated() {
            let moduleName = data.types[module.typeId]?.name?["en"] ?? "Unknown"
            print("Module \(index + 1): \(moduleName) (ID: \(module.typeId))")
            
            for (attributeID, attribute) in module.attributes.sorted(by: { $0.key < $1.key }) {
                if let attrInfo = data.dogmaAttributes[attributeID] {
                    let attrName = attrInfo.name ?? attrInfo.displayNameID?["en"] ?? "Unknown"
                    if attrName.lowercased().contains("velocity") || attrName.lowercased().contains("speed") || attrName.lowercased().contains("max") {
                        print("  [\(attributeID)] \(attrName): base=\(attribute.baseValue), final=\(attribute.value ?? 0)")
                    }
                }
            }
        }
        
        print("✅ Rifter with MWD and Overdrive Injector (all skills level 5) speed test completed")
    }
}
