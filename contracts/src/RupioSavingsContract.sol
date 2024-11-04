// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Rupio.sol";
import {AccessManager} from "./AccessManager.sol";

/**
 * @title RupioSavingsContract.
 * @author RupioDao.
 * @notice A simple Savings Contract that incentivizes users to hold Rupio in this contract.
 * @notice Savings rate is determined by governance in RupioDao.
 * @notice This contract acts as a part of RupioDao stability mechanism.
 */

contract RupioSavingsContract {
    /**
     * @notice User Struct showing user investment details.
     */
    struct User {
        uint256 userBalance;
        uint256 userDepositedAt;
        uint256 userWithdrawn;
        bool isUserWithdrawn;
        uint256 rewardAmount;
        uint256 lastWithdrawnAmount;
        uint256 lastClaimedReward;
        uint256 currentRewardAmount;
        uint256 lastRewardClaimedAt;
    }
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    Rupio public token;
    AccessManager public accessManager;
    uint256 lockPeriod;
    uint256 savingsRate; //Rupio savings rate
    uint256 public totalDeposited;
    uint256 public totalInvestersCount;

    /**
     * @dev Mapping of investor address to their details struct.
     */
    mapping(address => User) users;

    /**
     * @param _savingsRate Rupio savings rate determined by RupioDao governance.
     * @param _token Address of rupio token.
     * @param _accessManager Address of RupioDao access manager.
     */
    constructor(uint256 _savingsRate, address _token, address _accessManager) {
        token = Rupio(_token);
        savingsRate = _savingsRate;
        accessManager = AccessManager(_accessManager);
    }

    /**
     * @notice Modifier that calls the access manager to check if the caller is a moderator in RupioDao.
     */
    modifier onlyModerator() {
        require(
            accessManager.hasRole(MODERATOR_ROLE, msg.sender),
            "Owner of this can call this function"
        );
        _;
    }

    /**
     * @notice Update lock period.
     * @dev OnlyModerator can call this function.
     * @param value New lock period.
     */
    function updateLockPeriod(uint256 value) public onlyModerator {
        lockPeriod = value;
    }

    /**
     * @notice Update savings rate.
     * @dev OnlyModerator can call this function.
     * @param value New savings rate.
     */
    function updateSavingsRate(uint256 value) public onlyModerator {
        savingsRate = value;
    }

    /**
     * @notice Lock Rupio to earn interest, Rupio Savings Rate.
     * @param _amount Amount of Rupio to be locked.
     */
    function lockRupio(uint256 _amount) public {
        require(
            token.balanceOf(msg.sender) >= _amount,
            "You dont Have a balance"
        );
        require(
            token.allowance(msg.sender, address(this)) >= _amount,
            "Not sufficient allowance"
        );
        User memory user = User(
            _amount,
            block.timestamp,
            0,
            false,
            0,
            0,
            0,
            0,
            0
        );
        totalDeposited += _amount;
        totalInvestersCount++;
        users[msg.sender] = user;
        token.transferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @notice Withdraw Rupio from the contract plus returns if any.
     * @param _amount Amount of Rupio to be withdrawn.
     */
    function withdrawRupio(uint256 _amount) public {
        User memory user = users[msg.sender];
        require(user.isUserWithdrawn == false, "Your balance is zero");
        uint256 userLockPeriod = user.userDepositedAt + lockPeriod;
        require(
            block.timestamp >= userLockPeriod,
            "withdraw your token after the lock period ends"
        );
        user.userBalance = user.userBalance - _amount;
        user.userWithdrawn = block.timestamp;
        user.lastWithdrawnAmount = _amount;
        if (user.userBalance == 0) {
            user.isUserWithdrawn = true;
        }
        users[msg.sender] = user;
        token.transfer(msg.sender, _amount);
    }

    /**
     * @notice Internal function to calculate interest of a user investment.
     * @param user Address of the user.
     */
    function calculateInterest(address user) internal view returns (uint256) {
        User memory currentUser = users[user];
        uint256 duration = (block.timestamp - currentUser.userDepositedAt) /
            86400;
        uint256 value = (currentUser.userBalance * savingsRate * duration) /
            100;
        currentUser.rewardAmount = value / 365;
        return currentUser.rewardAmount;
    }

    /**
     * @notice Claim Rupio rewards incurred on the investment.
     */
    function claimReward() public {
        User memory user = users[msg.sender];

        calculateInterest(msg.sender);
        user.currentRewardAmount = user.rewardAmount - user.lastClaimedReward;
        user.lastClaimedReward = user.currentRewardAmount;
        user.lastRewardClaimedAt = block.timestamp;
        users[msg.sender] = user;
        token.mint(msg.sender, user.currentRewardAmount);
    }
}
