// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Script} from "forge-std/Script.sol";
import {PriceFeed} from "../../../src/PriceFeed.sol";
import {HelperConfig} from "../../../script/HelperConfig.s.sol";
import {Indai} from "../../../src/indai.sol";
import{CollateralSafekeep} from "../../../src/ColalteralSafekeep.sol";



contract PriceFeedTest is StdCheats, Test, Script {
    PriceFeed priceFeed;
    HelperConfig helperConfig;
    CollateralSafekeep csk;
    user=address(124);

    function setUp() public {
        helperConfig = new HelperConfig();
        priceFeed = new PriceFeed(
            helperConfig.getAnvilConfig().priceFeed,
            helperConfig.getAnvilConfig().priceFeed2
        );
        indai = new Indai();
        csk=new CollateralSafekeep();
    }
}
