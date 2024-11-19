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

        rupio = Rupio(0x0f16525440EefC7C1d10AF8171EC2618A7B134bb);
        // console.log(rupio.owner());

        // rupio.setPeer(
        //     helperconfig.getBaseSepoliaConfig().chainEid,
        //     addressToBytes32(0x0f16525440EefC7C1d10AF8171EC2618A7B134bb)
        // );
        console.log(
            "Is-peer",
            rupio.isPeer(
                helperconfig.getEthSepoliaConfig().chainEid,
                addressToBytes32(0xbb9ac7b4973eC691bE01DD4b0B7659a77A53fe23)
            )
        );
        vm.stopBroadcast();
    }

    function addressToBytes32(address _addr) public pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}
