//
//  CPUPowerSkillTests.swift
//  DogmaEngine Tests
//
//  Created on July 31, 2025.
//

import Testing
@testable import DogmaEngine

/// Tests to check if CPU and Power calculations account for skills
struct CPUPowerSkillTests {
    
    @Test func testCPUAndPowerWithSkillsVsWithoutSkills() async throws {
        let data = try TestHelpers.loadVerifiedSDEData()
        let standardFit = TestHelpers.getStandardRifterFit()
        
        // Verify all modules exist in the data
        try standardFit.verifyAllModules(in: data)
        
        // Create fit with standard modules
        let fit = standardFit.createFit()
        
        // Test 1: No skills
        let infoNoSkills = SimpleInfo(data: data, fit: fit, skills: [:])
        let shipNoSkills = calculate(info: infoNoSkills)
        
        // Test 2: With all skills at level 5 (includes all Rigging and fitting skills)
        let allSkillsAtLevel5 = TestHelpers.getAllSkillsAtLevel5(from: data)
        let infoWithSkills = SimpleInfo(data: data, fit: fit, skills: allSkillsAtLevel5)
        let shipWithSkills = calculate(info: infoWithSkills)
        
        // Get CPU values
        let cpuOutputNoSkills = shipNoSkills.hull.attributes[48]?.value ?? 0  // cpuOutput
        let cpuLoadNoSkills = shipNoSkills.hull.attributes[49]?.value ?? 0    // cpuLoad
        let cpuOutputWithSkills = shipWithSkills.hull.attributes[48]?.value ?? 0
        let cpuLoadWithSkills = shipWithSkills.hull.attributes[49]?.value ?? 0
        
        // Get Power values  
        let powerOutputNoSkills = shipNoSkills.hull.attributes[11]?.value ?? 0  // powerOutput
        let powerLoadNoSkills = shipNoSkills.hull.attributes[15]?.value ?? 0    // powerLoad
        let powerOutputWithSkills = shipWithSkills.hull.attributes[11]?.value ?? 0
        let powerLoadWithSkills = shipWithSkills.hull.attributes[15]?.value ?? 0
        
        print("=== MODULE CONSUMPTION DETAILS ===")
        print("Without Skills:")
        for (index, item) in shipNoSkills.items.enumerated() {
            let cpuUsage = item.attributes[50]?.value ?? 0
            let powerUsage = item.attributes[30]?.value ?? 0
            print("  Module \(index): CPU=\(cpuUsage), Power=\(powerUsage)")
            
            // Check skill requirements for this module
            let skillReqs = [182, 183, 184, 1285, 1289, 1290]
            for skillAttr in skillReqs {
                if let skillValue = item.attributes[skillAttr]?.baseValue {
                    print("    Skill req attr \(skillAttr): \(Int(skillValue))")
                }
            }
        }
        
        print("With Skills:")
        for (index, item) in shipWithSkills.items.enumerated() {
            let cpuUsage = item.attributes[50]?.value ?? 0
            let powerUsage = item.attributes[30]?.value ?? 0
            print("  Module \(index): CPU=\(cpuUsage), Power=\(powerUsage)")
        }
        
        print("=== CPU COMPARISON ===")
        print("No Skills - CPU: \(cpuLoadNoSkills)/\(cpuOutputNoSkills)")
        print("With Skills - CPU: \(cpuLoadWithSkills)/\(cpuOutputWithSkills)")
        print("CPU Output increase: \(cpuOutputWithSkills - cpuOutputNoSkills)")
        
        print("=== POWER COMPARISON ===")
        print("No Skills - Power: \(powerLoadNoSkills)/\(powerOutputNoSkills)")
        print("With Skills - Power: \(powerLoadWithSkills)/\(powerOutputWithSkills)")
        print("Power Output increase: \(powerOutputWithSkills - powerOutputNoSkills)")
        
        print("=== MODULE COUNT ===")
        print("Total modules fitted: \(fit.modules.count)")
        
        // CPU Management level 5 should increase CPU output by 25% (5% per level)
        let expectedCpuIncrease = cpuOutputNoSkills * 0.25
        let actualCpuIncrease = cpuOutputWithSkills - cpuOutputNoSkills
        
        // Power Grid Management level 5 should increase power output by 25%
        let expectedPowerIncrease = powerOutputNoSkills * 0.25
        let actualPowerIncrease = powerOutputWithSkills - powerOutputNoSkills
        
        print("Expected CPU increase: \(expectedCpuIncrease), Actual: \(actualCpuIncrease)")
        print("Expected Power increase: \(expectedPowerIncrease), Actual: \(actualPowerIncrease)")
        
        // Update expected values based on actual results with proper skill implementation
        // User specified expected values: CPU 162.2/162.5, Power 49.91/51.25
        let expectedCpuLoad = 162.2    // User's expected CPU load value
        let expectedCpuOutput = 162.5
        let expectedPowerLoad = 49.91  // User's expected power load value  
        let expectedPowerOutput = 51.25
        
        // Check if skills are affecting CPU output
        #expect(actualCpuIncrease > 0, "CPU output should increase with CPU Management skill")
        #expect(abs(cpuLoadWithSkills - expectedCpuLoad) < 0.1, 
                "CPU load should be ~\(expectedCpuLoad), got \(cpuLoadWithSkills)")
        #expect(abs(cpuOutputWithSkills - expectedCpuOutput) < 0.1, 
                "CPU output should be ~\(expectedCpuOutput), got \(cpuOutputWithSkills)")
        
        // Check if skills are affecting power output
        #expect(actualPowerIncrease > 0, "Power output should increase with Power Grid Management skill")
        #expect(abs(powerLoadWithSkills - expectedPowerLoad) < 0.1, 
                "Power load should be ~\(expectedPowerLoad), got \(powerLoadWithSkills)")
        #expect(abs(powerOutputWithSkills - expectedPowerOutput) < 0.1, 
                "Power output should be ~\(expectedPowerOutput), got \(powerOutputWithSkills)")
    }
}
