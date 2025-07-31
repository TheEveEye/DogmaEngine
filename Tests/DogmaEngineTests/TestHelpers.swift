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
}

enum TestError: Error {
    case missingSDEData(String)
    case missingTestData(String)
    case incorrectTestData(String)
}
