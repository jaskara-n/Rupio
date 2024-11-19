// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {CollateralSafekeep} from "../../../../src/CollateralSafekeep.sol";
import {Rupio} from "../../../../src/Rupio.sol";
import {HelperConfig} from "../../../../script/HelperConfig.s.sol";

//narrows down the way we do function calls in fuzz invariant testing
contract Handler is Test {
    address owner;
    CollateralSafekeep csk;
    Rupio indai;
    address[] usersWithVault;

    constructor(address _csk, address _indai, address _owner) {
        csk = CollateralSafekeep(_csk);
        indai = Rupio(_indai);
        owner = _owner;
    }

    function createVault(uint256 _val) public {
        _val = bound(_val, 1 * 1e18, 3000 * 1e18);
        vm.deal(msg.sender, _val);
        vm.startPrank(msg.sender);
        csk.createOrUpdateVault{value: _val}();
        vm.stopPrank();
        //can have duplicates
        usersWithVault.push(msg.sender);
    }

    function mintIndai(uint256 _amount, uint256 _addressSeed) public {
        if (usersWithVault.length == 0) {
            return;
        }
        address sender = usersWithVault[_addressSeed % usersWithVault.length];
        vm.prank(owner);
        uint256 max = csk.getMaxMintableRupio(sender);
        if (max == 0) {
            return;
        }
        _amount = bound(_amount, 1, max - 1);
        vm.prank(sender);
        csk.mintRupioOnHomeChain(_amount);
    }
}
