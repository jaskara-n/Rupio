// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Handler} from "./Handler.t.sol";
import {HelperConfig} from "../../../../script/HelperConfig.s.sol";
import {CollateralSafekeep} from "../../../../src/CollateralSafekeep.sol";
import {Rupio} from "../../Mocks/Rupio.sol";
import {PriceFeed} from "../../../../src/PriceFeed.sol";
import {AccessManager} from "../../../../src/AccessManager.sol";

//getter view functions must never revert
// value of minted indai must be always less than
// price feed must always work
contract InvariantsTest is StdInvariant, Test {
    address owner = address(124);
    Handler handler;
    HelperConfig helperconfig;
    CollateralSafekeep csk;
    AccessManager accessManager;
    Rupio indai;
    PriceFeed pricefeed;

    function setUp() external {
        helperconfig = new HelperConfig();
        vm.startPrank(owner);
        accessManager = new AccessManager();
        indai = new Rupio(address(accessManager));
        pricefeed = new PriceFeed(
            helperconfig.getAnvilConfig().inrToUsdFeed,
            helperconfig.getAnvilConfig().ethToUsdFeed
        );
        csk = new CollateralSafekeep(
            helperconfig.getAnvilConfig().cip,
            helperconfig.getAnvilConfig().baseRiskRate,
            helperconfig.getAnvilConfig().riskPremiumRate,
            address(accessManager),
            address(indai),
            address(pricefeed)
        );
        vm.stopPrank();
        handler = new Handler(address(csk), address(indai), owner);
        targetContract(address(handler));
    }

    function invariant_cskETHBalShouldBeGreaterThanTotalIndai() public view {
        uint256 totalSupply = indai.totalSupply();
        assert(address(csk).balance >= totalSupply);
    }
}
