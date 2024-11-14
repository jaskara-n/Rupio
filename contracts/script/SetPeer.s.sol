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

        rupio = Rupio(0xd47BDd29C984722B229141dE99C80c210de04E02);
        console.log(rupio.owner());

        rupio.setPeer(
            helperconfig.getBaseSepoliaConfig().chainEid,
            addressToBytes32(0xC07D0290997f5053923e17B03ab871e9575E5e36)
        );
        console.log(
            "Is-peer",
            rupio.isPeer(
                helperconfig.getBaseSepoliaConfig().chainEid,
                addressToBytes32(0xC07D0290997f5053923e17B03ab871e9575E5e36)
            )
        );
        vm.stopBroadcast();
    }

    function addressToBytes32(address _addr) public pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}
