//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";

contract HelperConfig is Script {
    uint256 BASE_RISK_RATE = 150;
    uint256 RISK_PREMIUM_RATE = 130;
    uint256 CIP = 150;

    struct NetworkConfig {
        address inrToUsdFeed;
        address ethToUsdFeed;
        uint256 cip;
        uint256 baseRiskRate;
        uint256 riskPremiumRate;
        uint32 chainEid;
        address lzEndpoint;
    }

    NetworkConfig public ActiveConfig;

    constructor() {
        // if (block.chainid == 10) {
        //     ActiveConfig = getOptimismMainnetConfig();
        // } else {
        //     ActiveConfig = getAnvilConfig();
        // }
    }

    function getOptimismMainnetConfig()
        public
        view
        returns (NetworkConfig memory)
    {
        console.log("Wotking on optimism mainnet now....");
        NetworkConfig memory mainnetConfig = NetworkConfig({
            inrToUsdFeed: 0x5535e67d8f99c8ebe961E1Fc1F6DDAE96FEC82C9,
            ethToUsdFeed: 0x13e3Ee699D1909E989722E753853AE30b17e08c5,
            baseRiskRate: BASE_RISK_RATE,
            riskPremiumRate: RISK_PREMIUM_RATE,
            cip: CIP,
            chainEid: 0,
            lzEndpoint: address(0)
        });
        return mainnetConfig;
    }

    function getOptimismSepoliaConfig()
        public
        view
        returns (NetworkConfig memory)
    {
        console.log("Working on optimism sepolia now....");
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            inrToUsdFeed: address(0),
            ethToUsdFeed: 0x61Ec26aA57019C486B10502285c5A3D4A4750AD7,
            baseRiskRate: BASE_RISK_RATE,
            riskPremiumRate: RISK_PREMIUM_RATE,
            cip: CIP,
            chainEid: uint32(10232),
            lzEndpoint: 0x55370E0fBB5f5b8dAeD978BA1c075a499eB107B8
        });
        return sepoliaConfig;
    }

    function getBaseSepoliaConfig() public view returns (NetworkConfig memory) {
        console.log("Working on base sepolia now....");
        NetworkConfig memory baseConfig = NetworkConfig({
            inrToUsdFeed: address(0),
            ethToUsdFeed: 0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1,
            baseRiskRate: BASE_RISK_RATE,
            riskPremiumRate: RISK_PREMIUM_RATE,
            cip: CIP,
            chainEid: uint32(10245),
            lzEndpoint: 0x55370E0fBB5f5b8dAeD978BA1c075a499eB107B8
        });
        return baseConfig;
    }

    function getEthSepoliaConfig() public view returns (NetworkConfig memory) {
        console.log("Working on eth sepolia now....");
        NetworkConfig memory ethConfig = NetworkConfig({
            inrToUsdFeed: address(0),
            ethToUsdFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            baseRiskRate: BASE_RISK_RATE,
            riskPremiumRate: RISK_PREMIUM_RATE,
            cip: CIP,
            chainEid: uint32(10161),
            lzEndpoint: 0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1
        });
        return ethConfig;
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        console.log("local network detected, deploying mocks!!");
        MockV3Aggregator inrToUsdMock = new MockV3Aggregator(
            uint8(8),
            int256(1200000)
        );
        MockV3Aggregator ethToUsdMock = new MockV3Aggregator(
            uint8(8),
            int256(325834000000)
        );
        NetworkConfig memory anvilConfig = NetworkConfig({
            inrToUsdFeed: address(inrToUsdMock),
            ethToUsdFeed: address(ethToUsdMock),
            baseRiskRate: BASE_RISK_RATE,
            riskPremiumRate: RISK_PREMIUM_RATE,
            cip: CIP,
            chainEid: 123,
            lzEndpoint: address(123)
        });
        return anvilConfig;
    }

    function getActiveConfig() public view returns (NetworkConfig memory) {
        return ActiveConfig;
    }
}
