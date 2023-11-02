// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./indai.sol";

contract ISR {
    struct User {
        uint userBalance;
        uint userDepositedAt;
        uint userWithdrawn;
        bool isUserWithdrawn;
        uint rewardAmount;
        uint lastWithdrawnAmount;
        uint lastClaimedReward;
        uint currentRewardAmount;
        uint lastRewardClaimedAt;
    }

    Indai public indaiToken;
    uint256 lockPeriod;
    uint256 savingsRate; //Indai savings rate
    address public admin;
    uint256 public totalDeposited;
    uint256 public totalInvestersCount;

    constructor(uint256 _savingsRate, address _indaiToken) {
        admin = msg.sender;
        indaiToken = Indai(_indaiToken);
        savingsRate = _savingsRate;
    }

    mapping(address => User) users;

    modifier ownable() {
        require(msg.sender == admin, "Owner of this can call this function");
        _;
    }

    function updateLockPeriod(uint value) public ownable {
        lockPeriod = value;
    }

    function updateSavingsRate(uint value) public ownable {
        savingsRate = value;
    }

    function lockIndai(uint256 _amount) public {
        require(
            indaiToken.balanceOf(msg.sender) >= _amount,
            "You dont Have a balance"
        );
        require(
            indaiToken.allowance(msg.sender, address(this)) >= _amount,
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
        indaiToken.transferFrom(msg.sender, address(this), _amount);
    }

    function withdrawIndai(uint256 _amount) public {
        User memory user = users[msg.sender];
        require(user.isUserWithdrawn == false, "Your balance is zero");
        uint userLockPeriod = user.userDepositedAt + lockPeriod;
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
        indaiToken.transfer(msg.sender, _amount);
    }

    function calculateInterest(address user) internal returns (uint) {
        User memory currentUser = users[user];
        uint duration = (block.timestamp - currentUser.userDepositedAt) / 86400;
        uint value = (currentUser.userBalance * savingsRate * duration) / 100;
        currentUser.rewardAmount = value / 365;
        return currentUser.rewardAmount;
    }

    function claimReward() public {
        User memory user = users[msg.sender];

        calculateInterest(msg.sender);
        user.userCurrentReward = user.rewardAmount - user.lastClaimedReward;
        user.lastClaimedReward = user.userCurrentReward;
        user.rewardClaimedAt = block.timestamp;
        users[msg.sender] = user;
        indaiToken.mint(msg.sender, user.userCurrentReward);
    }
}
