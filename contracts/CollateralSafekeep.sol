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
    uint256 public immutable baseRiskRate; //Base rate debt on a vault
    uint256 public immutable riskPremiumRate; //Currently only for ethereum, the rate associated with debt in a vault, with increasing time
    uint256 internal vault_ID;
    int256 internal currentCollateralBalance; // total collateral balance of the whole contract in inr

    /************STRUCTS******************/
    struct vault {
        uint256 vaultId;
        address userAddress;
        uint256 balance;
        uint256 indaiIssued;
    }

    /**************ARRAYS***************/
    vault[] internal userVaults;
    vault[] internal riskyVaults; //not sure if this array will pile up with each time interval

    /************EVENTS******************/

    /**************MAPPINGS***************/

    mapping(address => uint256) public userIndexes;

    /***************MODIFIERS***********/

    //The user should have a vault
    modifier yesVault() {
        require(
            userIndexes[msg.sender] == 1,
            "You dont have a vault, create a vault first!"
        );
        _;
    }

    //The user should have no vault
    modifier noVault() {
        require(userIndexes[msg.sender] == 0, "You already have a vault");
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

    constructor(
        uint256 _timeInterval,
        uint256 _CIP,
        uint256 _baseRiskRate,
        uint256 _riskPremiumRate
    ) {
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
        baseRiskRate = _baseRiskRate;
        riskPremiumRate = _riskPremiumRate;
        vault_ID = 1;
        vault memory initialVault = vault({
            indaiIssued: 0,
            userAddress: address(0),
            vaultId: 0,
            balance: 0
        });
        userVaults.push(initialVault);
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
    function createVault() public payable noVault {
        require(msg.value > 0, "ETH amount must be greater than 0");

        vault memory newVault;

        newVault.balance = msg.value;
        newVault.userAddress = msg.sender;
        newVault.vaultId = vault_ID;
        newVault.indaiIssued = 0; //Initially it will be 0 for a new vault

        userVaults.push(newVault);
        userIndexes[msg.sender] = vault_ID;
        vault_ID = vault_ID + 1;
    }

    function updateVault() public payable yesVault {
        require(msg.value > 0, "eth amount must be greater than 0");
        userVaults[userIndexes[msg.sender]].balance += msg.value;
    }

    function withdrawFromVault(uint256 amount) public payable yesVault {
        // only allow user to withdraw if no debt in vault
        require(amount > 0, "Withdraw amount should be greater than 0");
        require(
            userVaults[userIndexes[msg.sender]].balance >= amount,
            "insufficient balance in vault"
        ); //To add logic to withdraw amount after cutting the fee
        //Or to let repay indai+fee(stability fee)
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
                /* uint80 roundID */
                int256 answer1 /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
                ,
                ,

            ) = priceFeed_ETHtoUSD.latestRoundData();

            (
                ,
                /* uint80 roundID */
                int256 answer2 /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
                ,
                ,

            ) = priceFeed_INRtoUSD.latestRoundData();

            currentCollateralBalance =
                (int256(address(this).balance) * answer1) /
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

    function scanVaults() internal {
        uint256 userVaultArrayLength = userVaults.length;

        for (uint256 i = 0; i <= userVaultArrayLength; i++) {
            bool yesOrNo = isCollateralRatioSatisfied(
                userVaults[i].userAddress
            );
            if (yesOrNo == false) {
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

    function liquidateVault(address _vaultAddress) public onlyModerator {
        //liquidate vaults that get too risky
    }

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

    function vaultDetailsForTheUser()
        public
        view
        yesVault
        returns (vault memory)
    {
        vault memory tempVault;
        tempVault.vaultId = userVaults[userIndexes[msg.sender]].vaultId;
        tempVault.userAddress = msg.sender;
        tempVault.balance = userVaults[userIndexes[msg.sender]].balance;
        tempVault.indaiIssued = userVaults[userIndexes[msg.sender]].indaiIssued;
        return tempVault;
    }

    /*************MOD ONLY GETTER FUNCTIONS*************/
    function getUserCollateralBalance(
        address _address
    ) public view onlyModerator returns (uint256) {
        return userVaults[userIndexes[_address]].balance;
    }

    function currentVaultID() public view onlyModerator returns (uint256) {
        //can be used to get total no of vaults
        //vault id starts from 1
        return vault_ID;
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
        return isCollateralRatioSatisfied(_user);
    }
}

//to implement a new contract for  oracle (kind of for loop)

// If MKR holders govern the Maker Protocol successfully, the Protocol
// will accrue Surplus Dai as Dai holders pay Stability Fees. On the other
// hand, if liquidations are inadequate, then the Protocol will accrue Bad
// Debt. Once this Surplus Dai / Bad Debt amount hits a threshold, as
// voted by MKR holders, then the Protocol will discharge Surplus Dai /
// Bad Debt through the Flapper / Flopper smart contract by buying and
// burning / minting and selling MKR, respectively.

// Risk Premium Rate - This rate is used to calculate the risk premium fee that accrues on debt in a Vault. A
// unique Risk Premium Rate is assigned to each collateral type. (e.g. 2.5%/year for Collateral A, 3.5%/year for
// Collateral B, etc)

/** */
