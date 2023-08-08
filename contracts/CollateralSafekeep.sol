// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract CollateralSafekeep is AccessControl, KeeperCompatibleInterface {
    /*************VARIABLES****************/
    AggregatorV3Interface internal priceFeed_ETHtoUSD;
    AggregatorV3Interface internal priceFeed_INRtoUSD;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    uint256 private lastTimeStamp;
    uint256 private immutable timeInterval;
    uint256 public immutable CIP; //Indai to collateral ratio
    uint256 private UservaultArrayLength;
    uint256 internal vaultID;
    int internal currentCollateralBalance; // total collateral balance of the whole contract in inr

    /************STRUCTS******************/
    struct vault {
        uint256 vaultId;
        address userAddress;
        uint256 balance;
        uint256 indaiIssued;
    }
    /**************ARRAYS***************/
    vault[] userVaults;
    vault[] internal riskyVaults; //not sure if this array will pile up with each time interval

    /**************MAPPINGS***************/

    mapping(address => uint256) userIndexes;

    /***************MODIFIERS***********/
    //Checks if user has a vault or not
    modifier vaultOrNot() {
        require(
            userVaults[userIndexes[msg.sender]].balance > 0,
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

    /***************EVENTS***********/

    constructor(uint256 _timeInterval, uint256 _CIP) {
        _setupRole(ADMIN_ROLE, msg.sender); // Grant ADMIN_ROLE to the contract deployer
        priceFeed_ETHtoUSD = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 //ETH to USD price feed(for eth mainnet)
        );
        priceFeed_INRtoUSD = AggregatorV3Interface(
            0x605D5c2fBCeDb217D7987FC0951B5753069bC360 //INR to USD price feed(for eth mainnet)
        );
        lastTimeStamp = block.timestamp;
        timeInterval = _timeInterval;
        CIP = _CIP;
        vaultID == 0;
    }

    /*************PUBLIC FUNCTIONS************/

    function grantModeratorRole(address account) public {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "Must have ADMIN_ROLE to grant MODERATOR_ROLE"
        );
        grantRole(MODERATOR_ROLE, account);
    }

    //Create a new vault for a user
    function createVault() public payable {
        require(
            userVaults[userIndexes[msg.sender]].balance == 0, // only one vault allowed for one address
            "you already have a vault"
        );

        require(msg.value > 0, "eth amount must be greater than 0");

        userVaults[userIndexes[msg.sender]].balance == msg.value;

        userVaults[userIndexes[msg.sender]].userAddress == msg.sender;

        userVaults[userIndexes[msg.sender]].vaultId == vaultID;

        vaultID == vaultID + 1;
    }

    function updateVault() public payable vaultOrNot {
        require(msg.value > 0, "eth amount must be greater than 0");
        userVaults[userIndexes[msg.sender]].balance += msg.value;
    }

    function withdrawFromVault(uint256 amount) public payable vaultOrNot {
        require(amount > 0, "Withdraw amount should be greater than 0");
        require(
            userVaults[userIndexes[msg.sender]].balance >= amount,
            "insufficient balance in vault"
        ); //To add logic to withdraw amount after cutting the ratio(indai to collateral in vault)
        payable(msg.sender).transfer(amount);
        userVaults[userIndexes[msg.sender]].balance -= amount;
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
    ) public view override returns (bool upkeepNeeded, bytes memory) {
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
                /* uint80 roundID */ int answer1 /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
                ,
                ,

            ) = priceFeed_ETHtoUSD.latestRoundData();

            (
                ,
                /* uint80 roundID */ int answer2 /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
                ,
                ,

            ) = priceFeed_INRtoUSD.latestRoundData();

            currentCollateralBalance =
                (int(address(this).balance) * answer1) /
                (answer2);

            //function to scan each user vault for ratio (returned my enternal oracle)
            scanVaults();
        }
    }

    // Function to check if collateral to indai ratio is satisfied for a user
    function isCollateralRatioSatisfied(
        address _user
    ) internal view returns (bool) {
        uint256 collateral = userVaults[userIndexes[_user]].balance;
        uint256 indaiIssued = userVaults[userIndexes[_user]].indaiIssued;
        uint256 requiredCollateral = (indaiIssued * CIP) / 100; // 150 percent of indai issued
        return collateral >= requiredCollateral;
    }

    function scanVaults() internal returns (uint256) {
        uint256 userVaultArrayLength = userVaults.length;

        for (uint256 i = 0; i <= userVaultArrayLength; i++) {
            bool yesOrNo = isCollateralRatioSatisfied(
                userVaults[i].userAddress
            );
            if (yesOrNo = false) {
                vault memory riskyVault = vault(
                    i,
                    userVaults[i].userAddress,
                    userVaults[i].balance,
                    userVaults[i].indaiIssued
                );
                riskyVaults.push(riskyVault);
            }
        }
    }

    /*************MOD ONLY FUNCTIONS*************/

    function liquidateVault(address _vaultAddress) public onlyModerator {}

    /*************GETTER FUNCTIONS*************/

    function getCIP()
        public
        view
        //returns collateral to indai percentage
        onlyModerator
        returns (uint256)
    {
        return CIP;
    }

    /*************MOD ONLY GETTER FUNCTIONS*************/
    function getUserCollateralBalance(
        address _address
    ) public view onlyModerator returns (uint256) {
        return userVaults[userIndexes[_address]].balance;
    }

    function getTotalCollateralPrice()
        public
        view
        //returns total collateral balance of the whole system in inr
        onlyModerator
        returns (int256)
    {
        return currentCollateralBalance;
    }

    //returns total database of vaults in array of structs
    function getTotalVaultDetails()
        public
        view
        onlyModerator
        returns (vault[] memory)
    {
        return userVaults;
    }

    //is collateral ratio satified for a specific user
    function isCollateralRatioSatifiedForUser(
        address _user
    ) public view onlyModerator returns (bool) {
        isCollateralRatioSatisfied(_user);
    }
}

//to implement a new contract for  oracle (kind of for loop)
