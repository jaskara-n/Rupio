//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

import {Rupio} from "../src/Rupio.sol";

contract DeployRupio is Script {
    HelperConfig helperconfig;
    Rupio rupio;

    function run() external {
        helperconfig = new HelperConfig();
        vm.startBroadcast();

        address accessManager = address(0);
        rupio = new Rupio(
            helperconfig.getEthSepoliaConfig().lzEndpoint,
            accessManager,
            helperconfig.getEthSepoliaConfig().chainEid
        );
        vm.stopBroadcast();

        console.log("rupio", address(rupio));
    }
}
