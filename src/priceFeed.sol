// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OracleLib, AggregatorV3Interface} from "./libraries/OracleLib.sol";

contract PriceFeed {
    using OracleLib for AggregatorV3Interface;

    AggregatorV3Interface internal dataFeed1;
    AggregatorV3Interface internal dataFeed2;

    constructor(address _priceFeedAddress, address _priceFeedAddress2) {
        dataFeed1 = AggregatorV3Interface(_priceFeedAddress);
        dataFeed2 = AggregatorV3Interface(_priceFeedAddress2);
    }

    function INRtoUSD() public view returns (int256) {
        // prettier-ignore
        (
            /* uint80 roundID */
            ,
            int256 answer,
            /*uint startedAt*/
            ,
            /*uint timeStamp*/
            ,
            /*uint80 answeredInRound*/
        ) = dataFeed1.staleCheckLatestRoundData();
        return answer;
    }

    function ETHtoUSD() public view returns (int256) {
        // prettier-ignore
        (
            /* uint80 roundID */
            ,
            int256 answer2,
            /*uint startedAt*/
            ,
            /*uint timeStamp*/
            ,
            /*uint80 answeredInRound*/
        ) = dataFeed2.staleCheckLatestRoundData();
        return answer2;
    }
}
