// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract PriceFeed {
    AggregatorV3Interface internal dataFeed1;
    AggregatorV3Interface internal dataFeed2;

    constructor(address _priceFeedAddress, address _priceFeedAddress2) {
        dataFeed1 = AggregatorV3Interface(_priceFeedAddress);
        dataFeed2 = AggregatorV3Interface(_priceFeedAddress2);
    }

    function INRtoUSD() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed1.latestRoundData();
        return answer;
    }

    function ETHtoUSD() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int answer2,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed2.latestRoundData();
        return answer2;
    }
}
