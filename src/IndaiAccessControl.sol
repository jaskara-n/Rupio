//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract IndaiAccessControl is AccessControl {
    constructor() {
        grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    bytes32 public constant MODERATOR_ROLE = keccak256("MINTER_ROLE");
}
