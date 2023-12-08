// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "@api3/contracts/v0.8/interfaces/IProxy.sol";

contract PriceFeed {
    address public proxyAddress = 0x26690F9f17FdC26D419371315bc17950a0FC90eD;

    constructor() {}

    // Updating the proxy contract address is a security-critical
    // action. In this example, only the owner is allowed to do so.
    // Get your pricefeed at https://market.api3.org/dapis

    function readDataFeed() public view returns (uint256, uint256) {
        (int224 value, uint256 timestamp) = IProxy(proxyAddress).read();
        //convert price to UINT256
        uint256 price = uint224(value);
        return (price, timestamp);
    }
}
