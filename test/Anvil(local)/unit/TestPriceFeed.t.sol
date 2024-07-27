import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Script} from "forge-std/Script.sol";
import {PriceFeed} from "../../../src/PriceFeed.sol";
import {HelperConfig} from "../../../script/HelperConfig.s.sol";

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract PriceFeedTest is StdCheats, Test, Script {
    PriceFeed priceFeed;
    HelperConfig helperConfig;

    function setUp() public {
        helperConfig = new HelperConfig();
        priceFeed = new PriceFeed(
            helperConfig.getAnvilConfig().priceFeed,
            helperConfig.getAnvilConfig().priceFeed2
        );
    }

    function testGetPrice() public {
        int answer = priceFeed.INRtoUSD();
        int answer2 = priceFeed.ETHtoUSD();
        assertEq(answer, 0.012 * 1e8);
        assertEq(answer2, 3258.34 * 1e8);
    }
}
