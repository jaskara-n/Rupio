//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/Test.sol";

contract HelperConfig is Script {
    // struct PriceFeedAddress {

    // }

    constructor() {
        if (block.chainid == 11155111) {}
    }
}
