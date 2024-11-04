//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title AccessManager.
 * @author Jaskaran Singh.
 * @notice Contract for managing access to the protocol.
 * @notice Integrated with openzeppelin access control to manage access between different contracts of this protocol.
 */
contract AccessManager is AccessControl {
    /**
     * @notice Owner Role Identifier.
     */
    bytes32 public constant OWNER = keccak256("OWNER");
    /**
     * @notice Moderator Role Identifier.
     */
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    /**
     * @notice Minter Role Identifier.
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @notice Constructor.
     * @dev Grants moderator, minter and owner role to the deployer.
     * @dev Sets Owner as the admin for Mod role and for Minter, Mod role.
     */
    constructor() {
        _setRoleAdmin(MODERATOR_ROLE, OWNER);
        _setRoleAdmin(MINTER_ROLE, MODERATOR_ROLE);
        _grantRole(OWNER, msg.sender);
        _grantRole(MODERATOR_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    /**
     * @notice Modifier to check if the msg.sender has Moderator role.
     */
    modifier onlyModerator() {
        require(
            hasRole(MODERATOR_ROLE, msg.sender),
            "Must have MODERATOR_ROLE"
        );
        _;
    }

    /**
     * @notice Grant moderator role to an account.
     * @notice Only callable by another moderator.
     * @param account Address of the account
     */
    function grantModeratorRole(address account) public onlyModerator {
        grantRole(MODERATOR_ROLE, account);
    }

    /**
     * @notice Grant minter role to an account.
     * @notice Only callable by another moderator.
     * @param account Address of the account.
     */
    function grantMinterRole(address account) public onlyModerator {
        grantRole(MINTER_ROLE, account);
    }
}
