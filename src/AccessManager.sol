//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract AccessManager is AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    bytes32 public constant OWNER = keccak256("OWNER");

    constructor() {
        _setRoleAdmin(MODERATOR_ROLE, OWNER);
        _setRoleAdmin(MINTER_ROLE, MODERATOR_ROLE);
        _grantRole(OWNER, msg.sender);
        _grantRole(MODERATOR_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }
}
