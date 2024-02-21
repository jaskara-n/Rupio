// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/**************Interfaces***************/
interface i_Indai {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IPriceFeed {
    function EthToUsd() external view returns (uint256, uint256);

    function InrToUsd() external view returns (uint256, uint256);
}

///@title Indai algorithmic stablecoin
///@author Jaskaran Singh
///@notice
///@dev

import "@openzeppelin/contracts/access/AccessControl.sol";

// import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract CollateralSafekeep is AccessControl {
    /*************VARIABLES****************/

    i_Indai internal token; //For ERC20 functions of the system
    IPriceFeed internal priceContract;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    uint256 private lastTimeStamp;
    // uint256 private immutable timeInterval;
    uint256 public immutable CIP; //Indai to collateral ratio
    uint256 public immutable baseRiskRate; //Base rate debt on a vault
    uint256 public immutable riskPremiumRate; //Currently only for ethereum, the rate associated with debt in a vault, with increasing time
    uint256 internal vault_ID;
    int256 internal currentCollateralBalance; // total collateral balance of the whole contract in inr

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

    mapping(address => uint256) public userIndexes;

    /***************MODIFIERS***********/

    //The user should have a vault
    modifier yesVault() {
        require(
            userIndexes[msg.sender] == 1,
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

    /***************EVENTS***********/

    constructor(
        // uint256 _timeInterval,
        uint256 _CIP,
        uint256 _baseRiskRate,
        uint256 _riskPremiumRate,
        address _indai,
        address _priceContract
    ) {
        _grantRole(ADMIN_ROLE, msg.sender); // Grant ADMIN_ROLE to the contract deployer
        _grantRole(MODERATOR_ROLE, msg.sender);
        token = i_Indai(_indai);
        priceContract = IPriceFeed(_priceContract);
        lastTimeStamp = block.timestamp;
        /* timeInterval= timeInterval;*/
        CIP = _CIP;
        baseRiskRate = _baseRiskRate;
        riskPremiumRate = _riskPremiumRate;
        vault_ID = 1;
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

    function grantModeratorRole(address account) public onlyModerator {
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
        newVault.vaultHealth = 100; //Full health for new vault
        newVault.balanceInINR = userBalanceInInr(msg.sender);
        userVaults.push(newVault);
        userIndexes[msg.sender] = vault_ID;
        vault_ID = vault_ID + 1;
    }

    /**
        @notice creates a new vault for a user
    */

    function mintIndai(uint256 amount) public yesVault {
        require(amount > 0, "enter valid amount");
        require(
            userVaults[userIndexes[msg.sender]].vaultHealth > CIP,
            "you are in debt!"
        );
        uint256 max = calculateMaxMintableDai(msg.sender);
        require(amount < max, "enter amount less than CIP cross");
        token.mint(msg.sender, amount);
        userVaults[userIndexes[msg.sender]].indaiIssued = amount;
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
        userVaults[userIndexes[msg.sender]].balanceInINR = userBalanceInInr(
            msg.sender
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
        require(
            liquidationCondition(msg.sender) == true,
            "Clear your debt in the vault!"
        );
        uint256 max = calculateMaxWithdrawableCollateral(msg.sender);
        require(amount < max, "you will go into debt!");
        payable(msg.sender).transfer(amount);
        userVaults[userIndexes[msg.sender]].vaultHealth = calculateVaultHealth(
            msg.sender
        );
        userVaults[userIndexes[msg.sender]].balance -= amount;
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
        userVaults[userIndexes[msg.sender]].balanceInINR += amount;
        calculateVaultHealth(msg.sender);
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

    function calculateVaultHealth(address _user) internal returns (uint256) {
        uint256 collateral = userVaults[userIndexes[_user]].balance;
        uint256 indaiIssued = userVaults[userIndexes[_user]].indaiIssued;
        uint256 vaultHealth = (collateral / indaiIssued) * 100;
        userVaults[userIndexes[_user]].vaultHealth = vaultHealth;
        return vaultHealth;
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

    /*************MOD ONLY FUNCTIONS*************/

    function liquidateVault(address _vaultAddress) public onlyModerator {}

    /** @notice liquidates vaults that get too risky.
        @dev this function is public in case we need to manually liquidate a vault
        @return 
    */

    /*************GETTER FUNCTIONS*************/

    function getCIP() public view returns (uint256) {
        return CIP;
    }

    /** @notice collateral to indai percentage defined by the DAO.
        @dev public getter function.
        @return uint256
    */

    function getBaseRiskRate() public view returns (uint256) {
        return baseRiskRate;
    }

    /** @notice base risk rate on all collateral types defined by the DAO.
        @dev public getter function.
        @return uint256
    */

    function getRiskPremiumRate() public view returns (uint256) {
        return riskPremiumRate;
    }

    /** @notice risk premium rate on specific collateral type defined by the DAO.
        @dev public getter function.
        @return uint256
    */

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

    /*************MOD OR CONTRACT ONLY GETTER FUNCTIONS*************/

    function userBalanceInInr(
        address _address
    ) internal view returns (uint256) {
        uint256 bal = userVaults[userIndexes[_address]].balance;

        (
            ,
            /* uint256 time stamp */
            uint256 a /*uint256 answer*/
        ) = priceContract.EthToUsd();

        (
            ,
            /* uint256 time stamp */
            uint256 b /*uint256 answer*/
        ) = priceContract.InrToUsd();
        uint256 c = (bal * uint256(a)) / uint256(b);
        return c;
    }

    /**
        @notice returns current vault balance of a user in inr
        @dev returns only the current balance that is stored in eth, by converting it to inr
        @return uint256 type price in inr
    */

    function calculateMaxMintableDai(
        address user
    ) internal view returns (uint256) {
        uint256 _userBalanceInInr = userBalanceInInr(user);
        uint256 indaiIssued = userVaults[userIndexes[user]].indaiIssued;
        uint256 collateralToDebtRatio = (_userBalanceInInr) / indaiIssued;
        uint256 maxMintableDai = 0;

        if ((collateralToDebtRatio) * 100 < CIP) {
            maxMintableDai = (CIP - collateralToDebtRatio) * _userBalanceInInr;
        } else {
            revert collateralSafekeep__userInDebt();
        }

        return maxMintableDai;
    }

    function calculateMaxWithdrawableCollateral(
        address user
    ) internal view yesVault returns (uint256) {
        uint256 collateral = userVaults[userIndexes[user]].balanceInINR;
        require(
            userVaults[userIndexes[user]].indaiIssued <
                userVaults[userIndexes[user]].balanceInINR,
            "you are in debt!"
        );
        require(
            userVaults[userIndexes[user]].vaultHealth > CIP,
            "you are in debt"
        );
        uint256 max = (collateral * (100 - CIP)) / 100;
        return max;
    }

    /**
        @notice calculates max amount of indai that can be minted by user at given vault state
        @return uint256 type max mintable indai
    */

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
        return vault_ID;
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
