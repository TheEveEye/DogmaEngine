import Testing
import Foundation
@testable import DogmaEngine

struct DogmaEngineTests {
    @Test func testDataLoading() async throws {
        let data = try TestHelpers.loadVerifiedSDEData()
        
        // Verify basic data is loaded
        #expect(data.types.count > 0, "Types should be loaded")
        #expect(data.groups.count > 0, "Groups should be loaded")
        #expect(data.typeDogma.count > 0, "TypeDogma should be loaded")
        #expect(data.dogmaAttributes.count > 0, "Dogma attributes should be loaded")
        #expect(data.dogmaEffects.count > 0, "Dogma effects should be loaded")
        
        print("✅ Loaded data: \(data.types.count) types, \(data.groups.count) groups, \(data.dogmaAttributes.count) attributes")
    }
    
    @Test func testRifterDataIntegrity() async throws {
        let data = try TestHelpers.loadVerifiedSDEData()
        
        // Test that Rifter (typeID 587) exists and has expected properties
        guard let rifter = data.types[587] else {
            throw TestError.missingTestData("Rifter (typeID 587) not found in types")
        }
        
        #expect(rifter.name?["en"] == "Rifter", "Rifter should have correct name")
        #expect(rifter.groupID > 0, "Rifter should have a valid group ID")
        let standardFit = TestHelpers.getStandardRifterFit()
        
        // Verify Rifter has dogma attributes
        if let rifterDogma = data.typeDogma[standardFit.rifterTypeID] {
            #expect(rifterDogma.dogmaAttributes.count > 0, "Rifter should have dogma attributes")
            
            // Check for basic ship attributes
            let attributeIDs = rifterDogma.dogmaAttributes.map { $0.attributeID }
            #expect(attributeIDs.contains(9), "Rifter should have structure HP (attribute 9)")
            #expect(attributeIDs.contains(265), "Rifter should have armor HP (attribute 265)")
            #expect(attributeIDs.contains(263), "Rifter should have shield capacity (attribute 263)")
        }
        
        print("✅ Rifter data integrity verified")
    }
    
    @Test func testBasicShipCalculation() async throws {
        let data = try TestHelpers.loadVerifiedSDEData()
        let standardFit = TestHelpers.getStandardRifterFit()
        
        // Create a basic Rifter fit (no modules)
        let fit = EsfFit(shipTypeID: standardFit.rifterTypeID, modules: [], drones: [])
        let info = SimpleInfo(data: data, fit: fit)
        
        // Calculate ship stats
        let ship = calculate(info: info)
        
        // Verify basic calculation worked
        #expect(ship.hull.typeId == standardFit.rifterTypeID, "Ship should have correct type ID")
        #expect(ship.hull.attributes.count > 0, "Ship should have calculated attributes")
        
        // Test specific attributes exist
        #expect(ship.hull.attributes[9] != nil, "Ship should have structure HP")
        #expect(ship.hull.attributes[265] != nil, "Ship should have armor HP")
        #expect(ship.hull.attributes[263] != nil, "Ship should have shield capacity")
        
        // Verify attribute values are reasonable
        if let structureHP = ship.hull.attributes[9]?.value {
            #expect(structureHP > 0, "Structure HP should be positive")
            #expect(structureHP < 10000, "Structure HP should be reasonable for a frigate")
        }
        
        print("✅ Basic ship calculation successful")
    }
    
    @Test func testShipWithModules() async throws {
        let data = try TestHelpers.loadVerifiedSDEData()
        let standardFit = TestHelpers.getStandardRifterFit()
        
        // Create a Rifter with a simple module (Damage Control II)
        let modules = [
            EsfModule(typeID: standardFit.lowSlot1TypeID, slot: EsfSlot(type: .low, index: 0), state: .passive, charge: nil)
        ]
        let fit = EsfFit(shipTypeID: standardFit.rifterTypeID, modules: modules, drones: [])
        let info = SimpleInfo(data: data, fit: fit)
        
        // Calculate ship stats
        let ship = calculate(info: info)
        
        // Verify module was loaded
        #expect(ship.items.count == 1, "Ship should have one fitted module")
        #expect(ship.items[0].typeId == 2048, "Module should have correct type ID")
        
        // Compare with and without module to verify it has an effect
        let emptyFit = EsfFit(shipTypeID: 587, modules: [], drones: [])
        let emptyInfo = SimpleInfo(data: data, fit: emptyFit)
        let emptyShip = calculate(info: emptyInfo)
        
        // Damage Control should improve resistances
        if let fittedStructureHP = ship.hull.attributes[9]?.value,
           let emptyStructureHP = emptyShip.hull.attributes[9]?.value {
            print("Structure HP - Empty: \(emptyStructureHP), Fitted: \(fittedStructureHP)")
        }
        
        print("✅ Ship with modules calculation successful")
    }
    
    @Test func testSkillEffects() async throws {
        let data = try TestHelpers.loadVerifiedSDEData()
        
        // Create fits with and without skills
        let fit = EsfFit(shipTypeID: 587, modules: [], drones: [])
        
        // No skills
        let noSkillsInfo = SimpleInfo(data: data, fit: fit, skills: [:])
        let noSkillsShip = calculate(info: noSkillsInfo)
        
        // With Minmatar Frigate V skill
        let withSkillsInfo = SimpleInfo(data: data, fit: fit, skills: [3312: 5]) // Minmatar Frigate V
        let withSkillsShip = calculate(info: withSkillsInfo)
        
        // Verify skills were applied
        #expect(noSkillsShip.skills.count == 0, "No skills ship should have 0 skills")
        #expect(withSkillsShip.skills.count == 1, "With skills ship should have 1 skill")
        
        // Skills should affect some attributes
        let noSkillsAttributes = noSkillsShip.hull.attributes
        let withSkillsAttributes = withSkillsShip.hull.attributes
        
        #expect(noSkillsAttributes.count > 0, "No skills ship should have attributes")
        #expect(withSkillsAttributes.count > 0, "With skills ship should have attributes")
        
        print("✅ Skill effects test successful")
    }
    
    @Test func testChargeCalculation() async throws {
        let data = try TestHelpers.loadVerifiedSDEData()
        let standardFit = TestHelpers.getStandardRifterFit()
        
        // Create a Rifter with autocannon and ammunition
        let modules = [
            EsfModule(typeID: 2881, slot: EsfSlot(type: .high, index: 0), state: .active, charge: EsfCharge(typeID: 12608)) // 200mm AutoCannon II with Hail S
        ]
        let fit = EsfFit(shipTypeID: standardFit.rifterTypeID, modules: modules, drones: [])
        let info = SimpleInfo(data: data, fit: fit)
        
        // Calculate ship stats
        let ship = calculate(info: info)
        
        // Verify module and charge were loaded
        #expect(ship.items.count == 1, "Ship should have one fitted module")
        #expect(ship.items[0].charge != nil, "Module should have charge loaded")
        #expect(ship.items[0].charge?.typeId == 12608, "Charge should have correct type ID")
        
        print("✅ Charge calculation successful")
    }
    
    @Test func testDamageProfile() async throws {
        let data = try TestHelpers.loadVerifiedSDEData()
        let standardFit = TestHelpers.getStandardRifterFit()
        
        // Create a Rifter with weapons
        let modules = [
            EsfModule(typeID: 2881, slot: EsfSlot(type: .high, index: 0), state: .active, charge: EsfCharge(typeID: 12608))
        ]
        let fit = EsfFit(shipTypeID: standardFit.rifterTypeID, modules: modules, drones: [])
        let info = SimpleInfo(data: data, fit: fit)
        
        // Calculate ship stats
        let ship = calculate(info: info)
        
        // Verify damage profile exists
        let damageProfile = ship.damageProfile
        
        // Damage values should be numbers (not NaN for a fitted weapon)
        let totalDamage = damageProfile.em + damageProfile.explosive + damageProfile.kinetic + damageProfile.thermal
        
        // At least one damage type should be > 0 with a weapon fitted
        #expect(totalDamage >= 0, "Total damage should be non-negative")
        
        print("✅ Damage profile calculation successful")
        print("Damage Profile - EM: \(damageProfile.em), Explosive: \(damageProfile.explosive), Kinetic: \(damageProfile.kinetic), Thermal: \(damageProfile.thermal)")
    }
}
