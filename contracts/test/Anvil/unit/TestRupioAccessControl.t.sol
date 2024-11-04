// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Script} from "forge-std/Script.sol";
import {AccessManager} from "../../../src/AccessManager.sol";

contract RupioAccessControlTest is StdCheats, Test, Script {
    bytes32 public constant OWNER = keccak256("OWNER");
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address owner = address(123);
    address moderator1 = address(124);
    address minter1 = address(125);
    AccessManager accesscontrol;

    function setUp() external {
        vm.startPrank(owner);
        accesscontrol = new AccessManager();
        accesscontrol.grantRole(MODERATOR_ROLE, moderator1);
        vm.stopPrank();
    }

    function testOwnerRoleGranted() public view {
        bool mybool = accesscontrol.hasRole(OWNER, owner);
        bool mybool2 = accesscontrol.hasRole(MODERATOR_ROLE, owner);
        bool mybool3 = accesscontrol.hasRole(MINTER_ROLE, owner);
        assertTrue(mybool);
        assertTrue(mybool2);
        assertTrue(mybool3);
        assertEq(accesscontrol.getRoleAdmin(MODERATOR_ROLE), OWNER);
        assertEq(accesscontrol.getRoleAdmin(MINTER_ROLE), MODERATOR_ROLE);
    }

    function testOwnerGrantsModRole() public view {
        bool mybool = accesscontrol.hasRole(MODERATOR_ROLE, moderator1);
        assertEq(mybool, true);
    }

    function testModGrantsMinterRole() public {
        vm.prank(moderator1);
        accesscontrol.grantRole(MINTER_ROLE, minter1);
        bool mybool = accesscontrol.hasRole(MINTER_ROLE, minter1);
        assertEq(mybool, true);
    }

    function testCskGrantsMinterRole() public {}
}
