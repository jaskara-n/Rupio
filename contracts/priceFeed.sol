// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "@api3/contracts/v0.8/interfaces/IProxy.sol";

contract PriceFeed {
    address public _EthToUsd = 0x26690F9f17FdC26D419371315bc17950a0FC90eD;
    address public _InrToUsd = 0x3c2f376c7A559617842E3298c35E0cE42EFCDEc1;

    constructor() {}

    function EthToUsd() public view returns (uint256, uint256) {
        (int224 value, uint256 timestamp) = IProxy(_EthToUsd).read();
        //convert price to UINT256
        uint256 price = uint224(value);
        return (price, timestamp);
    }

    function InrToUsd() public view returns (uint256, uint256) {
        (int224 value, uint256 timestamp) = IProxy(_InrToUsd).read();
        //convert price to UINT256
        uint256 price = uint224(value);
        return (price, timestamp);
    }
}
