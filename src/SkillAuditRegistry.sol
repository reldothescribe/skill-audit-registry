// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SkillAuditRegistry
 * @author ReldoTheScribe
 * @notice On-chain registry for agent skill security audits
 * @dev Stores audit results with skill content hash, risk score, and metadata
 */
contract SkillAuditRegistry {
    
    enum RiskLevel { CLEAN, LOW, MEDIUM, HIGH, CRITICAL }
    
    struct Audit {
        bytes32 skillHash;      // keccak256 of skill content
        RiskLevel riskLevel;    // 0-4 risk classification
        uint256 riskScore;      // Numeric score (0-1000+)
        string scannerVersion;  // e.g. "1.0.0"
        address auditor;        // Who submitted the audit
        uint256 timestamp;      // When audit was submitted
        string notes;           // Optional notes/findings
    }
    
    // All audits for a skill hash
    mapping(bytes32 => Audit[]) public skillAudits;
    
    // All skill hashes that have been audited
    bytes32[] public auditedSkills;
    mapping(bytes32 => bool) private skillExists;
    
    // Auditor stats
    mapping(address => uint256) public auditorCount;
    
    // Events
    event AuditSubmitted(
        bytes32 indexed skillHash,
        RiskLevel riskLevel,
        uint256 riskScore,
        address indexed auditor,
        uint256 timestamp
    );
    
    /**
     * @notice Submit a new skill audit
     * @param skillHash keccak256 hash of the skill.md content
     * @param riskLevel Risk classification (0=CLEAN to 4=CRITICAL)
     * @param riskScore Numeric risk score
     * @param scannerVersion Version of scanner used
     * @param notes Optional findings or notes
     */
    function submitAudit(
        bytes32 skillHash,
        RiskLevel riskLevel,
        uint256 riskScore,
        string calldata scannerVersion,
        string calldata notes
    ) external {
        require(skillHash != bytes32(0), "Invalid skill hash");
        
        // Track new skills
        if (!skillExists[skillHash]) {
            auditedSkills.push(skillHash);
            skillExists[skillHash] = true;
        }
        
        // Store audit
        skillAudits[skillHash].push(Audit({
            skillHash: skillHash,
            riskLevel: riskLevel,
            riskScore: riskScore,
            scannerVersion: scannerVersion,
            auditor: msg.sender,
            timestamp: block.timestamp,
            notes: notes
        }));
        
        auditorCount[msg.sender]++;
        
        emit AuditSubmitted(skillHash, riskLevel, riskScore, msg.sender, block.timestamp);
    }
    
    /**
     * @notice Get the latest audit for a skill
     * @param skillHash The skill's content hash
     * @return The most recent audit, or empty if none exists
     */
    function getLatestAudit(bytes32 skillHash) external view returns (Audit memory) {
        Audit[] storage audits = skillAudits[skillHash];
        require(audits.length > 0, "No audits found");
        return audits[audits.length - 1];
    }
    
    /**
     * @notice Get all audits for a skill
     * @param skillHash The skill's content hash
     * @return Array of all audits
     */
    function getAudits(bytes32 skillHash) external view returns (Audit[] memory) {
        return skillAudits[skillHash];
    }
    
    /**
     * @notice Get count of audits for a skill
     * @param skillHash The skill's content hash
     * @return Number of audits
     */
    function getAuditCount(bytes32 skillHash) external view returns (uint256) {
        return skillAudits[skillHash].length;
    }
    
    /**
     * @notice Get total number of unique skills audited
     * @return Count of unique skills
     */
    function getTotalSkillsAudited() external view returns (uint256) {
        return auditedSkills.length;
    }
    
    /**
     * @notice Check if a skill has been flagged (MEDIUM or higher)
     * @param skillHash The skill's content hash
     * @return True if any audit flagged it as risky
     */
    function isFlagged(bytes32 skillHash) external view returns (bool) {
        Audit[] storage audits = skillAudits[skillHash];
        for (uint i = 0; i < audits.length; i++) {
            if (audits[i].riskLevel >= RiskLevel.MEDIUM) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * @notice Helper to compute skill hash off-chain matching
     * @param content The skill.md content
     * @return The keccak256 hash
     */
    function computeSkillHash(string calldata content) external pure returns (bytes32) {
        return keccak256(bytes(content));
    }
}
