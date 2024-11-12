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
        rupio = Rupio(0x42fb975a20DCF4Ba06B0c41615dc1bd94036F6DE);
        // rupio.setPeer(
        //     helperconfig.getBaseSepoliaConfig().chainEid,
        //     addressToBytes32(0x62E5634044c1B823995d1f0fA5d9B7Dc3E671904)
        // );
        // console.log(
        //     "Is-peer",
        //     rupio.isPeer(
        //         helperconfig.getBaseSepoliaConfig().chainEid,
        //         addressToBytes32(0x62E5634044c1B823995d1f0fA5d9B7Dc3E671904)
        //     )
        // );
        console.log(rupio.owner());
        vm.stopBroadcast();
    }

    function addressToBytes32(address _addr) public pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}
