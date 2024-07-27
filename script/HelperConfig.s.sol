//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address priceFeed;
        address priceFeed2;
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
        console.log("forking optimism mainnet now....");
        NetworkConfig memory mainnetConfig = NetworkConfig({
            priceFeed: vm.envAddress(
                "OPTIMISM_MAINNET_INRUSD_PRICEFEED_ADDRESS"
            ),
            priceFeed2: vm.envAddress(
                "OPTIMISM_MAINNET_ETHUSD_PRICEFEED_ADDRESS"
            )
        });
        return mainnetConfig;
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        console.log("local network detected, deploying mocks!!");
        MockV3Aggregator mock = new MockV3Aggregator(uint8(8), int256(1200000));
        MockV3Aggregator mock2 = new MockV3Aggregator(
            uint8(8),
            int256(325834000000)
        );
        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mock),
            priceFeed2: address(mock2)
        });
        return anvilConfig;
    }

    function getActiveConfig() public view returns (NetworkConfig memory) {
        return ActiveConfig;
    }
}
