//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {AccessManager} from "../src/AccessManager.sol";
import {PriceFeed} from "../src/priceFeed.sol";
import {Indai} from "../src/indai.sol";
import {CollateralSafekeep} from "../src/CollateralSafekeep.sol";
import {ISR} from "../src/ISR.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";

contract Deploy is Script {
    HelperConfig helperconfig;
    AccessManager accessmanager;
    PriceFeed pricefeed;
    Indai indai;
    CollateralSafekeep csk;
    ISR isr;

    function run() external {
        helperconfig = new HelperConfig();
        vm.startBroadcast();
        MockV3Aggregator mock = new MockV3Aggregator(uint8(8), int256(1200000));
        accessmanager = new AccessManager();
        pricefeed = new PriceFeed(
            address(mock),
            helperconfig.getOptimismSepoliaConfig().priceFeed2
        );
        indai = new Indai(address(accessmanager));
        csk = new CollateralSafekeep(
            helperconfig.getOptimismSepoliaConfig().cip,
            helperconfig.getOptimismSepoliaConfig().baseRiskRate,
            helperconfig.getOptimismSepoliaConfig().riskPremiumRate,
            address(accessmanager),
            address(indai),
            address(pricefeed)
        );
        vm.stopBroadcast();
        console.log("price feed mock", address(mock));
        console.log("access manager", address(accessmanager));
        console.log("indai", address(indai));
        console.log("price feed", address(pricefeed));
        console.log("collateral safe keep", address(csk));
    }
}
