// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CollateralSafekeep is
    AccessControl,
    AggregatorV3Interface,
    KeeperCompatibleInterface
{
    /*************VARIABLES****************/
    AggregatorV3Interface internal priceFeed;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    uint256 private lastTimeStamp;
    uint256 private immutable timeInterval;
    int public currentCollateralBalance;

    /************STRUCTS******************/
    struct vault {
        uint256 balance;
    }

    /**************MAPPINGS***************/
    mapping(address => vault) public userVaults;

    /***************MODIFIERS***********/
    //Checks if user has a vault or not
    modifier vaultOrNot() {
        require(
            userVaults[msg.sender].balance > 0,
            "user does not have a vault"
        );
        _;
    }
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Must have ADMIN_ROLE");
        _;
    }

    modifier onlyModerator() {
        require(
            hasRole(MODERATOR_ROLE, msg.sender),
            "Must have MODERATOR_ROLE"
        );
        _;
    }

    /***************ERRORS***********/
    error upkeepNotNeeded();

    constructor(uint256 _timeInterval) {
        _setupRole(ADMIN_ROLE, msg.sender); // Grant ADMIN_ROLE to the contract deployer
        priceFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306 //ETH to USD price feed(for sepolia testnet)
        );
        lastTimeStamp = block.timestamp;
        timeInterval = _timeInterval;
    }

    /*************PUBLIC FUNCTIONS************/

    function grantModeratorRole(address account) public {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "Must have ADMIN_ROLE to grant MODERATOR_ROLE"
        );
        grantRole(MODERATOR_ROLE, account);
    }

    //Create a new vault for a user or add more eth to the vault
    function createOrUpdateVault() public payable {
        require(msg.value > 0, "eth amount must be greater than 0");
        userVaults[msg.sender].balance += msg.value;
    }

    function withdrawFromVault(uint256 amount) public payable vaultOrNot {
        require(amount > 0, "Withdraw amount should be greater than 0");
        require(
            userVaults[msg.sender].balance >= amount,
            "insufficient balance in vault"
        ); //To add logic to withdraw amount after cutting the ratio(indai to collateral in vault)
        payable(msg.sender).transfer(amount);
        userVaults[msg.sender].balance -= amount;
    }

    /*Chainlink keeper function that looks for upkeepNeeded to return true and then perform the performUpkeep 
    function to get price feed for vaults at regular intervals of time*/
    /*
    conditions for upkeepNeeded to be true:
    1. time interval has to be passed
    2. there should be atleast someone deposited some eth into the vault
    3. our keepers subscription should be funded with link
    */
    function checkUpkeep(
        bytes memory /*performData*/
    ) public override returns (bool upkeepNeeded, bytes memory) {
        bool isTimePassed = (block.timestamp - lastTimeStamp) > timeInterval;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isTimePassed && hasBalance);
    }

    function performUpkeep(bytes memory /*performData*/) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert upkeepNotNeeded();
        } else {
            (
                ,
                /* uint80 roundID */ int answer /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
                ,
                ,

            ) = priceFeed.latestRoundData();
            currentCollateralBalance = int(address(this).balance) * answer;
        }
    }

    /*************MOD ONLY FUNCTIONS*************/
    function liquidateVault(address _vaultAddress) public onlyModerator {}

    /*************GETTER FUNCTIONS*************/
    function getVaultDetails() public view returns (uint256) {
        return userVaults[msg.sender].balance;
    }

    //Getter functions only accessible by admin addresses
    function getUserVaultDetails(
        address _address
    ) public view onlyModerator returns (uint256) {
        return userVaults[_address].balance;
    }
}
