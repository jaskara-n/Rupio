///@title Indai algorithmic stablecoin
///@author Jaskaran Singh
///@notice Algorithmic Stablecoin Pegged to INR
///@dev Integrated with Chainlink Pricefeeds, Openzeppelin contracts

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PriceFeed} from "./PriceFeed.sol";
import {Indai} from "./indai.sol";

// import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract CollateralSafekeep is AccessControl {
    /*************VARIABLES****************/

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    uint256 public immutable CIP; //Indai to collateral ratio
    uint256 public immutable BASE_RISK_RATE; //Base rate debt on a vault
    uint256 public immutable RISK_PREMIUM_RATE; //Currently only for ethereum, the rate associated with debt in a vault, with increasing time
    uint256 private lastTimeStamp;
    Indai internal token; //For ERC20 functions of the system
    PriceFeed internal priceContract;
    int256 internal currentCollateralBalance; // total collateral balance of the whole contract in inr
    uint256 internal VAULT_ID;

    /************STRUCTS******************/
    struct vault {
        uint256 vaultId;
        address userAddress;
        uint256 balance; // In eth
        uint256 balanceInINR; // In inr
        uint256 indaiIssued;
        uint256 vaultHealth; // vault health should be greater than 150 to avoid liquidation
    }

    /**************ARRAYS***************/
    vault[] internal userVaults;

    /************EVENTS******************/
    event thisIsARiskyVault(
        uint256 vaultId,
        address userAddress,
        uint256 balance,
        uint256 balanceInINR,
        uint256 indaiIssued,
        uint256 vaultHealth
    );

    /************MAPPINGS******************/
    mapping(address => uint256) public userIndexes;

    /***************MODIFIERS***********/

    //The user should have a vault
    modifier yesVault() {
        require(
            userIndexes[msg.sender] > 0,
            "You dont have a Vault, create a vault first!"
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
    error collateralSafekeep__userInDebt();

    constructor(
        // uint256 _timeInterval,
        uint256 _CIP,
        uint256 _BASE_RISK_RATE,
        uint256 _RISK_PREMIUM_RATE,
        address _indai,
        address _priceContract
    ) {
        VAULT_ID = 1;
        _grantRole(ADMIN_ROLE, msg.sender); // Grant ADMIN_ROLE to the contract deployer
        _grantRole(MODERATOR_ROLE, msg.sender);
        token = Indai(_indai);
        priceContract = PriceFeed(_priceContract);
        lastTimeStamp = block.timestamp;
        /* timeInterval= timeInterval;*/
        CIP = _CIP;
        BASE_RISK_RATE = _BASE_RISK_RATE;
        RISK_PREMIUM_RATE = _RISK_PREMIUM_RATE;
        vault memory initialVault = vault({
            indaiIssued: 0,
            userAddress: address(0),
            vaultId: 0,
            balance: 0,
            balanceInINR: 0,
            vaultHealth: 0
        });
        userVaults.push(initialVault);
    }

    /*************PUBLIC FUNCTIONS************/
    function createVault() public payable noVault {
        require(msg.value > 0, "ETH amount must be greater than 0");
        vault memory newVault;
        newVault.balance = msg.value;
        newVault.userAddress = msg.sender;
        newVault.vaultId = VAULT_ID;
        newVault.indaiIssued = 0; //Initially it will be 0 for a new vault
        newVault.vaultHealth = collateralToInr(msg.value) * 100; //Full health for new vault
        newVault.balanceInINR = collateralToInr(msg.value);
        userVaults.push(newVault);

        userIndexes[msg.sender] = VAULT_ID;
        VAULT_ID = VAULT_ID + 1;
    }

    /**
        @notice creates a new vault for a user
    */

    function mintIndai(uint256 amount) public yesVault returns (uint256) {
        require(amount > 0, "enter valid amount");
        require(
            userVaults[userIndexes[msg.sender]].vaultHealth > CIP,
            "you are in debt!"
        );
        uint256 max = _calculateMaxMintableDai(msg.sender);
        require(amount < max, "enter amount less than CIP cross");
        token.mint(msg.sender, amount);
        userVaults[userIndexes[msg.sender]].indaiIssued += amount;
        userVaults[userIndexes[msg.sender]].vaultHealth = _calculateVaultHealth(
            msg.sender
        );
        return max;
    }

    /**
        @notice This allows user to mint indai based on their collateral in the vault
        @notice User cannot mint if vault health is lower than 150 percent
        @notice One indai is issued for every ruppee of collateral(in eth, converted to inr)
        @dev This function is the algorithmic minting of indai, one indai is minted for every rupee of collateral
        @dev Updates the token amount in the user's vault
        @custom:misc User can use this function to mint dai after depositing the collateral in vault
    */

    function updateVault() public payable yesVault {
        require(msg.value > 0, "eth amount must be greater than 0");
        userVaults[userIndexes[msg.sender]].balance += msg.value;
        userVaults[userIndexes[msg.sender]].balanceInINR = collateralToInr(
            userVaults[userIndexes[msg.sender]].balance
        );
    }

    /**
        @notice This adds nore collateral in eth to the user's existing vault
    */

    function withdrawFromVault(uint256 amount) public payable yesVault {
        require(amount > 0, "Withdraw amount should be greater than 0");
        require(
            userVaults[userIndexes[msg.sender]].balance >= amount,
            "insufficient balance in vault"
        );
        require(_calculateVaultHealth(msg.sender) > 150, "Clear your debt!");
        // require(
        //     liquidationCondition(msg.sender) == true,
        //     "Clear your debt in the vault!"
        // );
        uint256 max = _calculateMaxWithdrawableCollateral(msg.sender);
        require(amount <= max, "you will go into debt!");
        payable(msg.sender).transfer(amount);
        userVaults[userIndexes[msg.sender]].balance -= amount;
        userVaults[userIndexes[msg.sender]].balanceInINR = collateralToInr(
            userVaults[userIndexes[msg.sender]].balance
        );
        userVaults[userIndexes[msg.sender]].vaultHealth = _calculateVaultHealth(
            msg.sender
        );
    }

    /**
        @notice User can withdraw if any excess collateral than 150 percent of indai issued
        @dev only allow user to withdraw if no debt in vault    
    */

    function burnIndaiAndRelieveCollateral(uint256 amount) public yesVault {
        require(userVaults[userIndexes[msg.sender]].indaiIssued > 0);
        require(userVaults[userIndexes[msg.sender]].indaiIssued >= amount);
        token.burnFrom(msg.sender, amount);
        userVaults[userIndexes[msg.sender]].indaiIssued -= amount;
        _calculateVaultHealth(msg.sender);
    }

    /*************PUBLIC GETTER FUNCTIONS*************/

    function getCIP() public view returns (uint256) {
        return CIP;
    }

    /** @notice collateral to indai percentage defined by the DAO.
        @dev public getter function.
        @return uint256
    */

    function getBASE_RISK_RATE() public view returns (uint256) {
        return BASE_RISK_RATE;
    }

    /** @notice base risk rate on all collateral types defined by the DAO.
        @dev public getter function.
        @return uint256
    */

    function getRISK_PREMIUM_RATE() public view returns (uint256) {
        return RISK_PREMIUM_RATE;
    }

    /** @notice risk premium rate on specific collateral type defined by the DAO.
        @dev public getter function.
        @return uint256
    */

    function vaultDetailsForTheUser()
        public
        view
        yesVault
        returns (
            // yesVault
            vault memory
        )
    {
        // vault memory tempVault;
        // tempVault.vaultId = userVaults[userIndexes[msg.sender]].vaultId;
        // tempVault.userAddress = msg.sender;
        // tempVault.balance = userVaults[userIndexes[msg.sender]].balance;
        // tempVault.balanceInINR = userVaults[userIndexes[msg.sender]]
        //     .balanceInINR;
        // tempVault.indaiIssued = userVaults[userIndexes[msg.sender]].indaiIssued;
        // tempVault.vaultHealth = userVaults[userIndexes[msg.sender]].vaultHealth;
        // return tempVault;
        return userVaults[userIndexes[msg.sender]];
    }

    /*************MOD ONLY FUNCTIONS*************/

    function grantModeratorRole(address account) public onlyModerator {
        grantRole(MODERATOR_ROLE, account);
    }

    function calculateVaultHealth(
        address _user
    ) public onlyModerator returns (uint256) {
        uint256 vaultHealth = _calculateVaultHealth(_user);
        return vaultHealth;
    }

    function liquidateVault(address _vaultAddress) public onlyModerator {}

    /** @notice liquidates vaults that get too risky.
        @dev this function is public in case we need to manually liquidate a vault
        @return 
    */

    /*************MOD ONLY GETTER FUNCTIONS*************/
    function getUserCollateralBalance(
        address _address
    ) public view onlyModerator returns (uint256) {
        return userVaults[userIndexes[_address]].balance;
    }

    /**
        @return Returns the user's balance in eth
    */

    function getCurrentVaultId() public view onlyModerator returns (uint256) {
        //can be used to get total no of vaults
        //vault id starts from 1
        return VAULT_ID;
    }

    function getTotalCollateralPrice()
        public
        view
        onlyModerator
        returns (int256)
    {
        return currentCollateralBalance;
    }

    /**
        @return  total collateral balance of the whole contract in eth
    */

    //returns total database of vaults in array of structs
    function getTotalVaultDetails()
        public
        view
        onlyModerator
        returns (vault[] memory)
    {
        return userVaults;
    }

    function userBalanceInInr(
        address _address
    ) public view onlyModerator returns (uint256) {
        uint256 bal = userVaults[userIndexes[_address]].balance; // in 18 decimals cuz eth

        return collateralToInr(bal);
    }

    function amountInrToEth(
        uint256 amountINR
    ) public view onlyModerator returns (uint256) {
        return _amountInrToEth(amountINR);
    }

    function calculateMaxWithdrawableCollateral(
        address user
    ) public view onlyModerator returns (uint256) {
        return _calculateMaxWithdrawableCollateral(user);
    }

    function calculateMaxMintableDai(
        address user
    ) public view onlyModerator returns (uint256 max) {
        return _calculateMaxMintableDai(user);
    }

    /**
        @notice User can burn their indai tokens to repay their debt 
        @dev only allow user to withdraw if no debt in vault    
    */

    // function checkUpkeep(
    //     bytes memory /*performData*/
    // ) public view override returns (bool upkeepNeeded, bytes memory) {
    //     bool isTimePassed = (block.timestamp - lastTimeStamp) > timeInterval;
    //     bool hasBalance = address(this).balance > 0;
    //     upkeepNeeded = (isTimePassed && hasBalance);
    // }

    // /**
    //     @notice Chainlink function that checks if time interval has passed so that contract can perform the perform upkeep function
    //     @dev conditions for upkeepNeeded to be true:
    //     1. time interval has to be passed
    //     2. there should be atleast someone deposited some eth into the vault
    //     3. our keepers subscription should be funded with link
    // */

    // function performUpkeep(bytes memory /*performData*/) external override {
    //     (bool upkeepNeeded, ) = checkUpkeep("");
    //     if (!upkeepNeeded) {
    //         revert upkeepNotNeeded();
    //     } else {
    //         (
    //             ,
    //             /* uint80 roundID */
    //             int256 answer1 /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
    //             ,
    //             ,

    //         ) = priceFeed_ETHtoUSD.latestRoundData();

    //         (
    //             ,
    //             /* uint80 roundID */
    //             int256 answer2 /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
    //             ,
    //             ,

    //         ) = priceFeed_INRtoUSD.latestRoundData();

    //         currentCollateralBalance =
    //             (int256(address(this).balance) * answer1) /
    //             (answer2);

    //         //function to scan each user vault for ratio (returned by enternal oracle)
    //         scanVaults();
    //     }
    // }

    // /**
    //     @notice This function runs periodically and scans through every vault to check vault health.
    //     @dev Chainlink keeper function that looks for upkeepNeeded to return true and then perform the performUpkeep
    //     function to get price feed for vaults at regular intervals of time, and liquidated vaults.
    //     @dev Calls scanVaults() directly and other functions indirectly.
    // */

    /*************INTERNAL FUNCTIONS*************/
    function _calculateVaultHealth(address _user) internal returns (uint256) {
        uint256 collateral = userVaults[userIndexes[_user]].balanceInINR; //in inr, 8 decimals

        uint256 indaiIssued = userVaults[userIndexes[_user]].indaiIssued; //in uint256 token quantity,can say 1 token = 1 inr
        if (indaiIssued == 0) {
            return collateral * 100;
        } else {
            uint256 _vaultHealth = ((collateral / (indaiIssued * 1e8)) * 100);
            userVaults[userIndexes[_user]].vaultHealth = _vaultHealth;
            return _vaultHealth;
        }
    }

    /**
        @notice calculates vault health of a users vault at a particular state
        @dev emits an event if vault health is less than 150
        @dev Vault health in the array of user data is updated in this function 
        @dev this function is called by scanvaults time to time
        @dev this function can be used both as a getter(to check vault health of user) and setter(update vault health of user in array)
        @dev this function is only for the contract, public getter function is the another one.
    */

    function liquidationCondition(address user) internal returns (bool) {
        uint256 current = calculateVaultHealth(user);
        if (current > CIP) {
            return false;
        } else {
            return true;
        }
    }

    function scanVaults() internal {
        uint256 userVaultArrayLength = userVaults.length;
        for (uint256 i = 0; i <= userVaultArrayLength; i++) {
            userVaults[i].balanceInINR = userBalanceInInr(
                userVaults[i].userAddress
            );
            userVaults[i].vaultHealth = calculateVaultHealth(
                userVaults[i].userAddress
            );
            bool yesOrNo = liquidationCondition(userVaults[i].userAddress);
            if (yesOrNo = true) {
                liquidateVault(userVaults[i].userAddress);
                emit thisIsARiskyVault(
                    i,
                    userVaults[i].userAddress,
                    userVaults[i].balance,
                    userVaults[i].balanceInINR,
                    userVaults[i].indaiIssued,
                    userVaults[i].vaultHealth
                );
            }
        }
    }

    /**
        @notice This function liquidates vaults that get too risky
        @dev emits event of the risky vaults 
        @dev this function is periodically called by chainlink keepers
        @dev this function updates the user's collateral balance in inr in the vault periodically
    */

    /*************INTERNAL GETTER FUNCTIONS*************/
    function collateralToInr(uint256 balance) internal view returns (uint256) {
        int256 a = priceContract.ETHtoUSD(); // in 8 decimals cuz usd

        int256 b = priceContract.INRtoUSD(); // in 8 decimals cuz usd
        uint256 c = (balance * uint256(a)) / uint256(b);

        uint256 d = (c / 1e10);
        return d;
    }

    function _amountInrToEth(
        uint256 amountINR
    ) internal view returns (uint256) {
        int256 a = priceContract.ETHtoUSD();
        int256 b = priceContract.INRtoUSD();
        uint256 c = (uint256(b) * amountINR) / uint256(a);
        uint256 d = c * 1e10;
        return d;
    }

    /**
        @notice returns current vault balance of a user in inr
        @dev returns only the current balance that is stored in eth, by converting it to inr
        @return max type uint256 price in inr
    */

    function _calculateMaxMintableDai(
        address user
    ) internal view returns (uint256) {
        require(
            userVaults[userIndexes[user]].vaultHealth > 150,
            "you are in debt!"
        );
        uint256 bal = userVaults[userIndexes[user]].balance; //amount, can say 1 token = 1 inr
        uint256 _userBalanceInInr = collateralToInr(bal); // in 8 decimals
        uint256 indaiIssued = userVaults[userIndexes[user]].indaiIssued; //amount, can say 1 token = 1 inr
        uint256 totalAval = (_userBalanceInInr * 2) / (3 * 1e8);
        uint256 grand = totalAval - indaiIssued;
        return grand;
    }

    function _calculateMaxWithdrawableCollateral(
        address user
    ) internal view returns (uint256) {
        uint256 collateral = userVaults[userIndexes[user]].balanceInINR;
        uint256 indaiIssued = userVaults[userIndexes[user]].indaiIssued;
        require(
            (userVaults[userIndexes[user]].indaiIssued) * 1e8 <
                userVaults[userIndexes[user]].balanceInINR,
            "you are in debt!"
        );
        require(
            userVaults[userIndexes[user]].vaultHealth > CIP,
            "you are in debt"
        );
        if (indaiIssued == 0) {
            return _amountInrToEth(collateral);
        } else {
            uint256 a = (indaiIssued * 3) / 2;
            uint256 b = a * 1e8;
            uint256 c = collateral - b;

            uint256 d = _amountInrToEth(c);
            return d;
        }
    }

    /**
        @notice calculates max amount of indai that can be minted by user at given vault state
        @return uint256 type max mintable indai
    */
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

//To add logic to withdraw amount after cutting the fee
//Or to let repay indai+fee(stability fee)

/** */
