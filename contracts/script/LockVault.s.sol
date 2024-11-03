//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {AccessManager} from "../src/AccessManager.sol";
import {PriceFeed} from "../src/priceFeed.sol";
import {Rupio} from "../src/Rupio.sol";
import {CollateralSafekeep} from "../src/CollateralSafekeep.sol";
import {ISR} from "../src/ISR.sol";

contract LockVault is Script {
    HelperConfig helperconfig;
    AccessManager accessmanager;
    PriceFeed pricefeed;
    Rupio indai;
    CollateralSafekeep csk;
    ISR isr;

    function run() external {
        helperconfig = new HelperConfig();
        vm.startBroadcast();
        csk = CollateralSafekeep(0x55c3e164E357756Bf22fB3aA475bf0D0D458e131);
        csk.createOrUpdateVault{value: 0.0002 ether}();
        csk.scanVaults();
        vm.stopBroadcast();
    }
}
