// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SkillAuditRegistry.sol";

contract SkillAuditRegistryTest is Test {
    SkillAuditRegistry public registry;
    address public auditor1 = address(0x1);
    address public auditor2 = address(0x2);
    
    bytes32 public skillHash1 = keccak256("skill content 1");
    bytes32 public skillHash2 = keccak256("skill content 2");
    
    function setUp() public {
        registry = new SkillAuditRegistry();
    }
    
    function test_SubmitAudit() public {
        vm.prank(auditor1);
        registry.submitAudit(
            skillHash1,
            SkillAuditRegistry.RiskLevel.LOW,
            100,
            "1.0.0",
            "Minor issues"
        );
        
        assertEq(registry.getAuditCount(skillHash1), 1);
        assertEq(registry.getTotalSkillsAudited(), 1);
        assertEq(registry.auditorCount(auditor1), 1);
    }
    
    function test_GetLatestAudit() public {
        vm.prank(auditor1);
        registry.submitAudit(
            skillHash1,
            SkillAuditRegistry.RiskLevel.LOW,
            100,
            "1.0.0",
            "First audit"
        );
        
        vm.prank(auditor2);
        registry.submitAudit(
            skillHash1,
            SkillAuditRegistry.RiskLevel.HIGH,
            800,
            "1.0.1",
            "Found critical issues"
        );
        
        SkillAuditRegistry.Audit memory latest = registry.getLatestAudit(skillHash1);
        assertEq(uint(latest.riskLevel), uint(SkillAuditRegistry.RiskLevel.HIGH));
        assertEq(latest.riskScore, 800);
        assertEq(latest.auditor, auditor2);
    }
    
    function test_IsFlagged() public {
        vm.prank(auditor1);
        registry.submitAudit(
            skillHash1,
            SkillAuditRegistry.RiskLevel.CLEAN,
            0,
            "1.0.0",
            ""
        );
        
        assertFalse(registry.isFlagged(skillHash1));
        
        vm.prank(auditor2);
        registry.submitAudit(
            skillHash1,
            SkillAuditRegistry.RiskLevel.CRITICAL,
            1000,
            "1.0.0",
            "Credential exfil detected"
        );
        
        assertTrue(registry.isFlagged(skillHash1));
    }
    
    function test_MultipleSkills() public {
        vm.startPrank(auditor1);
        
        registry.submitAudit(skillHash1, SkillAuditRegistry.RiskLevel.CLEAN, 0, "1.0.0", "");
        registry.submitAudit(skillHash2, SkillAuditRegistry.RiskLevel.LOW, 50, "1.0.0", "");
        
        vm.stopPrank();
        
        assertEq(registry.getTotalSkillsAudited(), 2);
        assertEq(registry.auditorCount(auditor1), 2);
    }
    
    function test_RevertOnZeroHash() public {
        vm.expectRevert("Invalid skill hash");
        registry.submitAudit(bytes32(0), SkillAuditRegistry.RiskLevel.CLEAN, 0, "1.0.0", "");
    }
    
    function test_RevertOnNoAudits() public {
        vm.expectRevert("No audits found");
        registry.getLatestAudit(skillHash1);
    }
    
    function test_ComputeSkillHash() public view {
        string memory content = "test skill content";
        bytes32 expected = keccak256(bytes(content));
        bytes32 computed = registry.computeSkillHash(content);
        assertEq(computed, expected);
    }
}
