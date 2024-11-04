// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OracleLib, AggregatorV3Interface} from "./libraries/OracleLib.sol";

/**
 * @title PriceFeed.
 * @author Jaskaran Singh.
 * @notice Contract for fetching INR to USD and ETH to USD prices for the RupioDao CollateralSafekeep contract.
 * @notice This contract is integrated with chainlink price feeds to fetch the latest prices.
 * @dev Uses OracleLib to check if the price feed is stale.
 */
contract PriceFeed {
    using OracleLib for AggregatorV3Interface;
    AggregatorV3Interface internal INRtoUSDFeed;
    AggregatorV3Interface internal ETHtoUSDFeed;

    constructor(address _INRToUSDFeed, address _ETHToUSDFeed) {
        INRtoUSDFeed = AggregatorV3Interface(_INRToUSDFeed);
        ETHtoUSDFeed = AggregatorV3Interface(_ETHToUSDFeed);
    }

    /**
     * @notice Fetches the latest INR to USD price from the Chainlink Price Feed.
     */
    function INRtoUSD() public view returns (int256 oneINRinUSD) {
        // prettier-ignore
        (
            /* uint80 roundID */
            ,
             oneINRinUSD,
            /*uint startedAt*/
            ,
            /*uint timeStamp*/
            ,
            /*uint80 answeredInRound*/
        ) = INRtoUSDFeed.staleCheckLatestRoundData();
    }

    /**
     * @notice Fetches the latest ETH to USD price from the Chainlink Price Feed.
     */
    function ETHtoUSD() public view returns (int256 oneETHinUSD) {
        // prettier-ignore
        (
            /* uint80 roundID */
            ,
             oneETHinUSD,
            /*uint startedAt*/
            ,
            /*uint timeStamp*/
            ,
            /*uint80 answeredInRound*/
        ) = ETHtoUSDFeed.staleCheckLatestRoundData();
    }
}
