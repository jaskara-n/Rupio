// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./Indai.sol";

contract ISR {
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

    mapping(address => uint256) userBalance;
    mapping(address => uint256) userDepositedAt;

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
        userBalance[msg.sender] += _amount;
        totalDeposited += _amount;
        userDepositedAt[msg.sender] = block.timestamp;
        totalInvestersCount++;
        indaiToken.transfer(address(this), _amount);
    }

    function withdrawIndai(uint256 _amount) public {
        uint256 userClaimedAt = block.timestamp;
        require(
            userClaimedAt - userDepositedAt[msg.sender] > lockPeriod,
            "withdraw the funds after the time reached"
        );
        require(
            totalDeposited >= _amount && userBalance[msg.sender] >= _amount,
            "Your account doesn't have enough balance"
        );
        totalDeposited -= _amount;
        userBalance[msg.sender] -= _amount;
        indaiToken.transferFrom(address(this), msg.sender, _amount);
    }

    function claimIntrest() public {
        require(
            userBalance[msg.sender] > 0,
            "You doesn't have balance in your account"
        );
        uint duration = block.timestamp - userDepositedAt[msg.sender];
        uint interest = (userBalance[msg.sender] * savingsRate * duration) /
            100;
        uint value = interest / 31536000;
        userBalance[msg.sender] += value;
        totalDeposited += value;
        indaiToken.mint(msg.sender, value);
    }
}
