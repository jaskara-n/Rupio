// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title OracleLib.
 * @author Jaskaran Singh.
 * @notice This library is used to check the PriceFeed.sol for stale data.
 * If a price is stale, functions will revert, and render the CollateralSafeKeep unusable - this is by design.
 * So if the Chainlink network explodes and you have a lot of money locked in the protocol... too bad.
 */
library OracleLib {
    /**
     * @dev Error thrown if the price is stale.
     */
    error OracleLib__StalePrice();

    /**
     * @dev Time in seconds after which a price is considered stale.
     */
    uint256 private constant TIMEOUT = 24 hours;

    /**
     * @notice Called by RupioDao contracts for getting price data, through PriceFeed.sol
     * @notice This function is a wrapper to check if the price is stale.
     * @param chainlinkFeed Address of the Chainlink Feed
     */
    function staleCheckLatestRoundData(
        AggregatorV3Interface chainlinkFeed
    ) public view returns (uint80, int256, uint256, uint256, uint80) {
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = chainlinkFeed.latestRoundData();

        if (updatedAt == 0 || answeredInRound < roundId) {
            revert OracleLib__StalePrice();
        }
        uint256 secondsSince = block.timestamp - updatedAt;
        if (secondsSince > TIMEOUT) revert OracleLib__StalePrice();

        return (roundId, answer, startedAt, updatedAt, answeredInRound);
    }

    /**
     * @dev Returns time in seconds after which a price is considered stale.
     */
    function getTimeout() public pure returns (uint256) {
        return TIMEOUT;
    }
}
