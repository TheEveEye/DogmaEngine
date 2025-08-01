//
//  TestHelpers.swift
//  DogmaEngine Tests
//
//  Created by GitHub Copilot on 7/28/25.
//

import Foundation
@testable import DogmaEngine

/// Common test utilities and helpers
enum TestHelpers {
    
    /// Get the SDE data directory from KiwiFitting project
    static func getSDEDataDirectory() throws -> URL {
        print("[TestHelpers] Checking SDE data directory locations...")
        // Try multiple possible paths to find the SDE data
        let possiblePaths = [
            // Direct path from project root
            "/Users/oskar/Desktop/KiwiFitting Workspace/KiwiFitting/KiwiFitting/Resources/sde",
            // Relative path calculation
            URL(fileURLWithPath: #file)
                .deletingLastPathComponent() // DogmaEngineTests
                .deletingLastPathComponent() // Tests
                .deletingLastPathComponent() // DogmaEngine
                .deletingLastPathComponent() // Root
                .appendingPathComponent("KiwiFitting")
                .appendingPathComponent("KiwiFitting")
                .appendingPathComponent("Resources")
                .appendingPathComponent("sde")
                .path
        ]
        
        for pathString in possiblePaths {
            print("[TestHelpers] Trying path: \(pathString)")
            let url = URL(fileURLWithPath: pathString)
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue {
                print("[TestHelpers] Found SDE directory at: \(url.path)")
                return url
            }
        }
        print("[TestHelpers] SDE directory not found in any of the expected locations:")
        for path in possiblePaths {
            print("  - \(path)")
        }
        throw TestError.missingSDEData("SDE directory not found in any of the expected locations")
    }
    
    /// Verify a type ID corresponds to the expected item name
    static func verifyTypeID(_ typeID: Int, expectedName: String, in data: DogmaEngine.Data) throws {
        guard let type = data.types[typeID] else {
            throw TestError.missingTestData("Type ID \(typeID) not found")
        }
        
        let actualName = type.name?["en"] ?? "Unknown"
        guard actualName == expectedName else {
            throw TestError.incorrectTestData("Type ID \(typeID) is '\(actualName)', expected '\(expectedName)'")
        }
        
        print("✅ Verified Type ID \(typeID): \(actualName)")
    }
    
    /// Load SDE data with verification
    static func loadVerifiedSDEData() throws -> DogmaEngine.Data {
        let sdeDirectory = try getSDEDataDirectory()
        let data = try DogmaEngine.Data.new(from: sdeDirectory)
        
        // Basic verification
        guard data.types.count > 0 else {
            throw TestError.missingTestData("No types loaded from SDE data")
        }
        
        return data
    }
    
    /// Generate all skills at level 5 for comprehensive skill testing
    static func getAllSkillsAtLevel5(from data: DogmaEngine.Data) -> [Int: Int] {
        var allSkills: [Int: Int] = [:]
        
        // Find all skill groups (category 16 is Skills)
        let skillGroups = Set(data.groups.compactMap { (groupID, group) in
            group.categoryID == 16 ? groupID : nil
        })
        
        // Find all published skill types
        for (typeID, type) in data.types {
            if skillGroups.contains(type.groupID) && (type.published ?? false) {
                allSkills[typeID] = 5
            }
        }
        
        print("✅ Generated \(allSkills.count) skills at level 5")
        return allSkills
    }
    
    /// Standard Rifter fit for consistent testing across all test suites
    static func getStandardRifterFit() -> StandardRifterFit {
        return StandardRifterFit()
    }
}

/// Standard Rifter fit configuration used across all tests
struct StandardRifterFit {
    // Ship
    let rifterTypeID: Int = 587 // Rifter
    
    // High slots (3x 200mm AutoCannon II)
    let highSlot1TypeID: Int = 2889 // 200mm AutoCannon II
    let highSlot2TypeID: Int = 2889 // 200mm AutoCannon II  
    let highSlot3TypeID: Int = 2889 // 200mm AutoCannon II
    
    // Mid slots
    let midSlot1TypeID: Int = 440  // 5MN Microwarpdrive II
    let midSlot2TypeID: Int = 448  // Warp Scrambler II
    let midSlot3TypeID: Int = 527  // Stasis Webifier II
    
    // Low slots
    let lowSlot1TypeID: Int = 2048  // Damage Control II
    let lowSlot2TypeID: Int = 1306  // Multispectrum Coating II
    let lowSlot3TypeID: Int = 33076 // Small Ancillary Armor Repairer
    let lowSlot4TypeID: Int = 20347 // 200mm Steel Plates II
    
    // Rig slots
    let rigSlot1TypeID: Int = 31668 // Small Projectile Burst Aerator I
    let rigSlot2TypeID: Int = 31656 // Small Projectile Ambit Extension I
    let rigSlot3TypeID: Int = 31406 // Small Semiconductor Memory Cell I
    
    /// Get all high slot modules as an array
    var highSlotModules: [Int] {
        return [highSlot1TypeID, highSlot2TypeID, highSlot3TypeID]
    }
    
    /// Get all mid slot modules as an array
    var midSlotModules: [Int] {
        return [midSlot1TypeID, midSlot2TypeID, midSlot3TypeID]
    }
    
    /// Get all low slot modules as an array
    var lowSlotModules: [Int] {
        return [lowSlot1TypeID, lowSlot2TypeID, lowSlot3TypeID, lowSlot4TypeID]
    }
    
    /// Get all rig slot modules as an array
    var rigSlotModules: [Int] {
        return [rigSlot1TypeID, rigSlot2TypeID, rigSlot3TypeID]
    }
    
    /// Get all modules as a flat array
    var allModules: [Int] {
        return highSlotModules + midSlotModules + lowSlotModules + rigSlotModules
    }
    
    /// Create the complete EsfModule array for the standard fit
    func createModules() -> [EsfModule] {
        var modules: [EsfModule] = []
        
        // High slots - 3x 200mm AutoCannon II
        for (index, typeID) in highSlotModules.enumerated() {
            modules.append(EsfModule(typeID: typeID, slot: EsfSlot(type: .high, index: index), state: .active, charge: nil))
        }
        
        // Mid slots
        for (index, typeID) in midSlotModules.enumerated() {
            modules.append(EsfModule(typeID: typeID, slot: EsfSlot(type: .medium, index: index), state: .active, charge: nil))
        }
        
        // Low slots
        for (index, typeID) in lowSlotModules.enumerated() {
            modules.append(EsfModule(typeID: typeID, slot: EsfSlot(type: .low, index: index), state: .active, charge: nil))
        }
        
        // Rig slots
        for (index, typeID) in rigSlotModules.enumerated() {
            modules.append(EsfModule(typeID: typeID, slot: EsfSlot(type: .rig, index: index), state: .active, charge: nil))
        }
        
        return modules
    }
    
    /// Create a complete EsfFit with all modules
    func createFit() -> EsfFit {
        return EsfFit(shipTypeID: rifterTypeID, modules: createModules(), drones: [])
    }
    
    /// Verify all modules exist in the provided data
    func verifyAllModules(in data: DogmaEngine.Data) throws {
        let moduleNames = [
            (rifterTypeID, "Rifter"),
            (highSlot1TypeID, "200mm AutoCannon II"),
            (midSlot1TypeID, "5MN Microwarpdrive II"),
            (midSlot2TypeID, "Warp Scrambler II"),
            (midSlot3TypeID, "Stasis Webifier II"),
            (lowSlot1TypeID, "Damage Control II"),
            (lowSlot2TypeID, "Multispectrum Coating II"),
            (lowSlot3TypeID, "Small Ancillary Armor Repairer"),
            (lowSlot4TypeID, "200mm Steel Plates II"),
            (rigSlot1TypeID, "Small Projectile Burst Aerator I"),
            (rigSlot2TypeID, "Small Projectile Ambit Extension I"),
            (rigSlot3TypeID, "Small Semiconductor Memory Cell I")
        ]
        
        for (typeID, expectedName) in moduleNames {
            try TestHelpers.verifyTypeID(typeID, expectedName: expectedName, in: data)
        }
        
        print("✅ All standard Rifter fit modules verified")
    }
}

enum TestError: Error {
    case missingSDEData(String)
    case missingTestData(String)
    case incorrectTestData(String)
}
