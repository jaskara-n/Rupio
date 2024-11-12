//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {AccessManager} from "../src/AccessManager.sol";
import {PriceFeed} from "../src/priceFeed.sol";
import {Rupio} from "../src/Rupio.sol";
import {CollateralSafekeep} from "../src/CollateralSafekeep.sol";
import {RupioSavingsContract} from "../src/RupioSavingsContract.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";

contract DeployHomeChain is Script {
    HelperConfig helperconfig;
    AccessManager accessmanager;
    PriceFeed pricefeed;
    Rupio rupio;
    CollateralSafekeep csk;
    RupioSavingsContract isr;

    function run() external {
        helperconfig = new HelperConfig();
        vm.startBroadcast();
        MockV3Aggregator inrToUsdMock = new MockV3Aggregator(
            uint8(8),
            int256(1200000)
        );
        accessmanager = new AccessManager();
        pricefeed = new PriceFeed(
            address(inrToUsdMock),
            helperconfig.getBaseSepoliaConfig().ethToUsdFeed
        );
        rupio = new Rupio(
            helperconfig.getBaseSepoliaConfig().lzEndpoint,
            address(accessmanager),
            helperconfig.getBaseSepoliaConfig().chainEid
        );
        csk = new CollateralSafekeep(
            helperconfig.getBaseSepoliaConfig().cip,
            helperconfig.getBaseSepoliaConfig().baseRiskRate,
            helperconfig.getBaseSepoliaConfig().riskPremiumRate,
            address(accessmanager),
            address(rupio),
            address(pricefeed)
        );
        vm.stopBroadcast();
        console.log("price feed mock", address(rupio));
        console.log("access manager", address(accessmanager));
        console.log("rupio", address(rupio));
        console.log("price feed", address(pricefeed));
        console.log("collateral safe keep", address(csk));
    }
}
