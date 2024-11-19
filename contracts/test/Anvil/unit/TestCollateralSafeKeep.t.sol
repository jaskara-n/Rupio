// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Script} from "forge-std/Script.sol";
import {PriceFeed} from "../../../src/PriceFeed.sol";
import {HelperConfig} from "../../../script/HelperConfig.s.sol";
import {Rupio} from "../Mocks/Rupio.sol";
import {CollateralSafekeep} from "../../../src/CollateralSafekeep.sol";
import {AccessManager} from "../../../src/AccessManager.sol";

contract CollateralSafekeepTest is StdCheats, Test, Script {
    AccessManager accessManager;
    PriceFeed priceFeed;
    HelperConfig helperConfig;
    CollateralSafekeep csk;
    Rupio indai;
    address user = address(124);
    address user2 = address(125);
    address user3 = address(123);
    address user4 = address(126);
    address user5 = address(127);
    address user6 = address(128);

    function setUp() public {
        vm.deal(user2, 5 ether);
        vm.deal(user3, 5 ether);
        vm.deal(user4, 5 ether);
        vm.deal(user5, 5 ether);

        helperConfig = new HelperConfig();

        priceFeed = new PriceFeed(
            helperConfig.getAnvilConfig().inrToUsdFeed,
            helperConfig.getAnvilConfig().ethToUsdFeed
        );

        vm.startPrank(user);
        accessManager = new AccessManager();
        console.log("accessmanager", address(accessManager));
        indai = new Rupio(address(accessManager));
        console.log("indai", address(indai));

        csk = new CollateralSafekeep(
            helperConfig.getAnvilConfig().cip,
            helperConfig.getAnvilConfig().baseRiskRate,
            helperConfig.getAnvilConfig().riskPremiumRate,
            address(accessManager),
            address(indai),
            address(priceFeed)
        );

        vm.stopPrank();
    }

    function testCreateOrUpdateVault() public {
        vm.startPrank(user2);
        csk.createOrUpdateVault{value: 0.5 ether}();
        CollateralSafekeep.vault memory tempVault = csk
            .getVaultDetailsForTheUser();
        assertEq(tempVault.vaultId, 1);
        assertEq(tempVault.balance, 0.5 ether);
        assertEq(tempVault.rupioIssued, 0);
        assertEq(tempVault.balanceInINR, 135764.16666666 * 1e8);

        vm.stopPrank();
        vm.startPrank(user3);
        csk.createOrUpdateVault{value: 1 ether}();
        csk.mintRupioOnHomeChain(5000);
        csk.createOrUpdateVault{value: 1 ether}();
        CollateralSafekeep.vault memory tempVault2 = csk
            .getVaultDetailsForTheUser();
        assertEq(tempVault2.balance, 2 * 1e18);
        assertGt(tempVault2.balanceInINR, 500000 * 1e8);
        assertLt(tempVault2.balanceInINR, 600000 * 1e8);
        vm.stopPrank();
    }

    function testCreateOrUpdateVaultMicro() public {
        vm.startPrank(user2);
        csk.createOrUpdateVault{value: 1 * 1e15}();
        CollateralSafekeep.vault memory tempVault = csk
            .getVaultDetailsForTheUser();
        console.log(tempVault.balanceInINR);
        vm.stopPrank();
    }

    function testUserBalanceInInr() public {
        vm.startPrank(user3);
        csk.createOrUpdateVault{value: 1 ether}();
        CollateralSafekeep.vault memory tempVault = csk
            .getVaultDetailsForTheUser();
        assertEq(tempVault.vaultId, 1);
        vm.stopPrank();

        vm.startPrank(user4);
        csk.createOrUpdateVault{value: 1.5 ether}();
        CollateralSafekeep.vault memory tempVault2 = csk
            .getVaultDetailsForTheUser();
        assertEq(tempVault2.vaultId, 2);
        vm.stopPrank();

        vm.startPrank(user);
        uint256 value = csk.getUserBalanceInINR(user3);
        uint256 value2 = csk.getUserBalanceInINR(user4);
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
        uint256 health = csk.getVaultHealth(user5);
        assertGt(health, 200000 * 1e8 * 100);
        assertLt(health, 300000 * 1e8 * 100);
    }

    function testCalculateMaxMintableDai() public {
        vm.prank(user5);
        csk.createOrUpdateVault{value: 1 ether}();
        vm.prank(user);
        uint256 max = csk.getMaxMintableRupio(user5);
        assertGt(max, 100000 * 1e8);
        assertLt(max, 200000 * 1e8);
        vm.prank(user5);
        csk.mintRupioOnHomeChain(10000);
        vm.prank(user);
        uint256 max2 = csk.getMaxMintableRupio(user5);
        assertGt(max2, 0);
        assertLt(max2, max);
        vm.prank(user5);
        csk.mintRupioOnHomeChain(15000);
        vm.prank(user);
        uint256 max3 = csk.getMaxMintableRupio(user5);
        assertGt(max3, 0);
        assertLt(max3, max2);
        //withdraw collateral and mint
        //update vault collateral and mint
    }

    function testMintIndai() public {
        vm.startPrank(user3);
        csk.createOrUpdateVault{value: 1 ether}();
        vm.expectRevert(bytes("enter amount less than CRP cross"));
        csk.mintRupioOnHomeChain(275513 * 1e8);
        CollateralSafekeep.vault memory tempVault2 = csk
            .getVaultDetailsForTheUser();
        uint256 max = csk.mintRupioOnHomeChain(3000 * 1e8);
        assertGt(max, 0);
        CollateralSafekeep.vault memory tempVault = csk
            .getVaultDetailsForTheUser();
        assertEq(tempVault.rupioIssued, 3000 * 1e8);
        assertLt(tempVault.vaultHealth, tempVault2.vaultHealth);
        assertEq(indai.balanceOf(user3), 3000 * 1e8);
        uint256 max2 = csk.mintRupioOnHomeChain(10000 * 1e8);
        assertGt(max2, 0);
        CollateralSafekeep.vault memory tempVault3 = csk
            .getVaultDetailsForTheUser();
        assertGt(tempVault3.rupioIssued, tempVault.rupioIssued);
        vm.stopPrank();
    }

    function testAmountInrToEth() public {
        vm.prank(user);
        uint256 amount = csk.getAmountINRToETH(300 * 1e8);
        console.log("amount", amount);

        assertGt(amount, 0.0009 * 1e18);
        assertLt(amount, 0.01 * 1e18);
    }

    function testCalculateMaxWithdrawableCollateral() public {
        vm.prank(user2);
        csk.createOrUpdateVault{value: 1 ether}();
        vm.prank(user);
        uint256 max = csk.getMaxWithdrawableCollateral(user2);
        assertGt(max, 0.9 ether);
        assertLt(max, 1.1 ether);
        vm.prank(user2);
        csk.mintRupioOnHomeChain(5000 * 1e8);
        vm.prank(user);
        uint256 max2 = csk.getMaxWithdrawableCollateral(user2);
        assertGt(max2, 0);
        assertLt(max2, max);
        vm.prank(user2);
        csk.mintRupioOnHomeChain(10000 * 1e8);
        vm.prank(user);
        uint256 max3 = csk.getMaxWithdrawableCollateral(user2);
        assertGt(max3, 0);
        assertLt(max3, max2);
    }

    function testWithdrawFromVault() public {
        vm.startPrank(user3);
        csk.createOrUpdateVault{value: 1 ether}();
        uint256 balbefore = address(csk).balance;
        CollateralSafekeep.vault memory tempVault = csk
            .getVaultDetailsForTheUser();
        csk.withdrawFromVault(0.5 ether);
        uint256 balafter = address(csk).balance;

        CollateralSafekeep.vault memory tempVault2 = csk
            .getVaultDetailsForTheUser();
        csk.mintRupioOnHomeChain(10000);
        CollateralSafekeep.vault memory tempVault3 = csk
            .getVaultDetailsForTheUser();
        assertLt(tempVault2.balance, tempVault.balance);
        assertLt(tempVault2.vaultHealth, tempVault.vaultHealth);
        assertLt(tempVault3.vaultHealth, tempVault2.vaultHealth);
        assertLt(balafter, balbefore);
    }

    function testBurnIndaiAndRelieveCollateral() public {
        vm.startPrank(user3);
        csk.createOrUpdateVault{value: 0.5 ether}();
        csk.mintRupioOnHomeChain(5000 * 1e8);
        assertEq(indai.balanceOf(user3), 5000 * 1e8);
        csk.burnRupioAndRelieveCollateral(5000 * 1e8);
        assertEq(indai.balanceOf(user3), 0);
        uint256 balbefore = address(csk).balance;
        csk.withdrawFromVault(0.49 ether);
        uint256 balafter = address(csk).balance;
        assertLt(balafter, balbefore);
        vm.stopPrank();
    }

    function testScanVaults() public {}
}
