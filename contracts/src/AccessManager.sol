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
    bytes32 public constant OWNER = keccak256("OWNER");
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() {
        _setRoleAdmin(MODERATOR_ROLE, OWNER);
        _setRoleAdmin(MINTER_ROLE, MODERATOR_ROLE);
        _grantRole(OWNER, msg.sender);
        _grantRole(MODERATOR_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    modifier onlyModerator() {
        require(
            hasRole(MODERATOR_ROLE, msg.sender),
            "Must have MODERATOR_ROLE"
        );
        _;
    }

    function grantModeratorRole(address account) public onlyModerator {
        grantRole(MODERATOR_ROLE, account);
    }

    function grantMinterRole(address account) public onlyModerator {
        grantRole(MINTER_ROLE, account);
    }
}
