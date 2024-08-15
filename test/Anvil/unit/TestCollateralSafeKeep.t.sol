// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Script} from "forge-std/Script.sol";
import {PriceFeed} from "../../../src/PriceFeed.sol";
import {HelperConfig} from "../../../script/HelperConfig.s.sol";
import {Indai} from "../../../src/indai.sol";
import {CollateralSafekeep} from "../../../src/CollateralSafekeep.sol";

contract PriceFeedTest is StdCheats, Test, Script {
    PriceFeed priceFeed;
    HelperConfig helperConfig;
    CollateralSafekeep csk;
    Indai indai;
    address user = address(124);
    address user2 = address(125);
    address user3 = address(123);
    address user4 = address(126);
    address user5 = address(127);

    function setUp() public {
        vm.deal(user2, 5 ether);
        vm.deal(user3, 5 ether);
        vm.deal(user4, 5 ether);
        vm.deal(user5, 5 ether);

        helperConfig = new HelperConfig();

        priceFeed = new PriceFeed(
            helperConfig.getAnvilConfig().priceFeed,
            helperConfig.getAnvilConfig().priceFeed2
        );

        vm.startPrank(user);

        indai = new Indai();

        csk = new CollateralSafekeep(
            helperConfig.getAnvilConfig().cip,
            helperConfig.getAnvilConfig().baseRiskRate,
            helperConfig.getAnvilConfig().riskPremiumRate,
            address(indai),
            address(priceFeed)
        );

        vm.stopPrank();
    }

    function testCreateOrUpdateVault() public {
        vm.startPrank(user2);
        csk.createOrUpdateVault{value: 0.5 ether}();
        CollateralSafekeep.vault memory tempVault = csk
            .vaultDetailsForTheUser();
        assertEq(tempVault.vaultId, 1);
        assertEq(tempVault.balance, 0.5 ether);
        assertEq(tempVault.indaiIssued, 0);
        assertEq(tempVault.balanceInINR, 135764.16666666 * 1e8);

        vm.stopPrank();
        vm.startPrank(user3);
        csk.createOrUpdateVault{value: 1 ether}();
        csk.mintIndai(5000);
        csk.createOrUpdateVault{value: 1 ether}();
        CollateralSafekeep.vault memory tempVault2 = csk
            .vaultDetailsForTheUser();
        assertEq(tempVault2.balance, 2 * 1e18);
        assertGt(tempVault2.balanceInINR, 500000 * 1e8);
        assertLt(tempVault2.balanceInINR, 600000 * 1e8);
        vm.stopPrank();
    }

    function testUserBalanceInInr() public {
        vm.startPrank(user3);
        csk.createOrUpdateVault{value: 1 ether}();
        CollateralSafekeep.vault memory tempVault = csk
            .vaultDetailsForTheUser();
        assertEq(tempVault.vaultId, 1);
        vm.stopPrank();

        vm.startPrank(user4);
        csk.createOrUpdateVault{value: 1.5 ether}();
        CollateralSafekeep.vault memory tempVault2 = csk
            .vaultDetailsForTheUser();
        assertEq(tempVault2.vaultId, 2);
        vm.stopPrank();

        vm.startPrank(user);
        uint256 value = csk.userBalanceInInr(user3);
        uint256 value2 = csk.userBalanceInInr(user4);
        assertGt(value, 250000 * 1e8);
        assertLt(value, 300000 * 1e8);
        assertGt(value2, 405000 * 1e8);
        assertLt(value2, 500000 * 1e8);
        vm.stopPrank();
    }

    function testCalcualteVaultHealth() public {
        vm.prank(user5);
        csk.createOrUpdateVault{value: 1 ether}();
        vm.prank(user);
        uint256 health = csk.calculateVaultHealth(user5);
        assertGt(health, 200000 * 1e8 * 100);
        assertLt(health, 300000 * 1e8 * 100);
    }

    function testCalculateMaxMintableDai() public {
        vm.prank(user5);
        csk.createOrUpdateVault{value: 1 ether}();
        vm.prank(user);
        uint256 max = csk.calculateMaxMintableDai(user5);
        assertGt(max, 100000);
        assertLt(max, 200000);
        vm.prank(user5);
        csk.mintIndai(10000);
        vm.prank(user);
        uint256 max2 = csk.calculateMaxMintableDai(user5);
        assertGt(max2, 0);
        assertLt(max2, max);
        vm.prank(user5);
        csk.mintIndai(15000);
        vm.prank(user);
        uint256 max3 = csk.calculateMaxMintableDai(user5);
        assertGt(max3, 0);
        assertLt(max3, max2);
        //withdraw collateral and mint
        //update vault collateral and mint
    }

    function testMintIndai() public {
        vm.startPrank(user3);
        csk.createOrUpdateVault{value: 1 ether}();
        vm.expectRevert(bytes("enter amount less than CIP cross"));
        csk.mintIndai(275513);
        CollateralSafekeep.vault memory tempVault2 = csk
            .vaultDetailsForTheUser();
        uint256 max = csk.mintIndai(3000);
        assertGt(max, 0);
        CollateralSafekeep.vault memory tempVault = csk
            .vaultDetailsForTheUser();
        assertEq(tempVault.indaiIssued, 3000);
        assertLt(tempVault.vaultHealth, tempVault2.vaultHealth);
        assertEq(indai.balanceOf(user3), 3000);
        uint256 max2 = csk.mintIndai(10000);
        assertGt(max2, 0);
        CollateralSafekeep.vault memory tempVault3 = csk
            .vaultDetailsForTheUser();
        assertGt(tempVault3.indaiIssued, tempVault.indaiIssued);
        vm.stopPrank();
    }

    function testAmountInrToEth() public {
        vm.prank(user);
        uint256 amount = csk.amountInrToEth(300 * 1e8);
        console.log("amount", amount);

        assertGt(amount, 0.0009 * 1e18);
        assertLt(amount, 0.01 * 1e18);
    }

    function testCalculateMaxWithdrawableCollateral() public {
        vm.prank(user2);
        csk.createOrUpdateVault{value: 1 ether}();
        vm.prank(user);
        uint256 max = csk.calculateMaxWithdrawableCollateral(user2);
        assertGt(max, 0.9 ether);
        assertLt(max, 1.1 ether);
        vm.prank(user2);
        csk.mintIndai(5000);
        vm.prank(user);
        uint256 max2 = csk.calculateMaxWithdrawableCollateral(user2);
        assertGt(max2, 0);
        assertLt(max2, max);
        vm.prank(user2);
        csk.mintIndai(10000);
        vm.prank(user);
        uint256 max3 = csk.calculateMaxWithdrawableCollateral(user2);
        assertGt(max3, 0);
        assertLt(max3, max2);
    }

    function testWithdrawFromVault() public {
        vm.startPrank(user3);
        csk.createOrUpdateVault{value: 1 ether}();
        uint256 balbefore = address(csk).balance;
        CollateralSafekeep.vault memory tempVault = csk
            .vaultDetailsForTheUser();
        csk.withdrawFromVault(0.5 ether);
        uint256 balafter = address(csk).balance;

        CollateralSafekeep.vault memory tempVault2 = csk
            .vaultDetailsForTheUser();
        csk.mintIndai(10000);
        CollateralSafekeep.vault memory tempVault3 = csk
            .vaultDetailsForTheUser();
        assertLt(tempVault2.balance, tempVault.balance);
        assertLt(tempVault2.vaultHealth, tempVault.vaultHealth);
        assertLt(tempVault3.vaultHealth, tempVault2.vaultHealth);
        assertLt(balafter, balbefore);
    }

    function testBurnIndaiAndRelieveCollateral() public {
        vm.startPrank(user3);
        csk.createOrUpdateVault{value: 0.5 ether}();
        csk.mintIndai(5000);
        assertEq(indai.balanceOf(user3), 5000);
        csk.burnIndaiAndRelieveCollateral(5000);
        assertEq(indai.balanceOf(user3), 0);
        uint256 balbefore = address(csk).balance;
        csk.withdrawFromVault(0.49 ether);
        uint256 balafter = address(csk).balance;
        assertLt(balafter, balbefore);
        vm.stopPrank();
    }
}
