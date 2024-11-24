//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

import {Rupio} from "../src/Rupio.sol";

contract SetPeer is Script {
    HelperConfig helperconfig;
    Rupio rupio;

    function run() external {
        helperconfig = new HelperConfig();
        vm.startBroadcast();

        rupio = Rupio(0x9BD90ac5435a793333C2F1e59A6e7e5dBAd0AFEa);
        // console.log(rupio.owner());

        rupio.setPeer(
            helperconfig.getOptimismSepoliaConfig().chainEid,
            addressToBytes32(0xDDd2e2A0434cb9B11bC778908bc9335f616f6362)
        );
        console.log(
            "Is-peer",
            rupio.isPeer(
                helperconfig.getOptimismSepoliaConfig().chainEid,
                addressToBytes32(0xDDd2e2A0434cb9B11bC778908bc9335f616f6362)
            )
        );
        vm.stopBroadcast();
    }

    function addressToBytes32(address _addr) public pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}
