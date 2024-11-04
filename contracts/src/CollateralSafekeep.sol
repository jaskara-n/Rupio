// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AccessManager} from "./AccessManager.sol";
import {PriceFeed} from "./PriceFeed.sol";
import {Rupio} from "./Rupio.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

/**
 * @title CollateralSafekeep.
 * @author Jaskaran Singh.
 * @notice An algorithmic stablecoin just like DAI, but pegged to INR.
 * @notice This contract integrates with chainlink pricefeeds and automation, to fetch INR conversion
 * rates and to automate the process of checking the vault health for all users.
 * @notice This contract is integrated with RupioDao access manager to manage access.
 * @notice This contract is integrated with Rupio token contract to mint and burn tokens.
 * @notice This contract is integrated with RupioDao price feed to fetch INR conversion rates.
 * @dev This contract works in RupioDao core, integrating with RupioDao price feed, access manager and token contract.
 */
contract CollateralSafekeep is ReentrancyGuard, AutomationCompatibleInterface {
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    uint256 public immutable CRP;
    uint256 public immutable BASE_RISK_RATE;
    uint256 public immutable RISK_PREMIUM_RATE;
    uint256 private lastTimeStamp;
    int256 internal currentCollateralBalance; // Total collateral balance of the whole contract in inr.
    uint256 internal VAULT_ID;
    AccessManager internal accessManager;
    Rupio internal token;
    PriceFeed internal priceContract;

    /**
     * @notice A struct representing vault details for a user.
     */
    struct vault {
        uint256 vaultId;
        address userAddress;
        uint256 balance; //In ETH.
        uint256 balanceInINR; //In inr.
        uint256 rupioIssued;
        uint256 vaultHealth; //Vault health should be greater than 150 to avoid liquidation.
    }

    /**
     * @notice An array of user's vaults.
     */
    vault[] internal userVaults;

    event thisIsARiskyVault(
        uint256 vaultId,
        address userAddress,
        uint256 balance,
        uint256 balanceInINR,
        uint256 rupioIssued,
        uint256 vaultHealth
    );

    /**
     * @notice Mapping of user's address to their vault index.
     */
    mapping(address => uint256) public userIndexes;

    /**
     * @notice User should have a vault.
     */
    modifier yesVault() {
        require(
            userIndexes[msg.sender] > 0,
            "You dont have a Vault, create a vault first!"
        );
        _;
    }

    /**
     * @notice User should not have a vault.
     */
    modifier noVault() {
        require(userIndexes[msg.sender] == 0, "You already have a vault");
        _;
    }

    /**
     * @notice Msg.sender should be a moderator.
     */
    modifier onlyModerator() {
        require(
            accessManager.hasRole(MODERATOR_ROLE, msg.sender),
            "Must have MODERATOR_ROLE"
        );
        _;
    }

    error CollateralSafekeep__UpkeepNotNeeded();
    error CollateralSafekeep__UserInDebt();
    error CollateralSafeKeep__ETHAmountMustBeGreaterThanZero();

    /**
     * @param _CRP Initial collateral to Rupio token percentage (threshold).
     * @param _BASE_RISK_RATE Base rate debt on a vault.
     * @param _RISK_PREMIUM_RATE Currently only for ethereum, the rate associated with debt in a vault, with increasing time.
     * @param _accessManager Address of RupioDao AccessManager.
     * @param _rupio Address of Rupio token contract.
     * @param _priceContract Address of RupioDao PriceFeed.
     */
    constructor(
        // uint256 _timeInterval,
        uint256 _CRP,
        uint256 _BASE_RISK_RATE,
        uint256 _RISK_PREMIUM_RATE,
        address _accessManager,
        address _rupio,
        address _priceContract
    ) {
        VAULT_ID = 1;
        accessManager = AccessManager(_accessManager);
        token = Rupio(_rupio);
        priceContract = PriceFeed(_priceContract);
        lastTimeStamp = block.timestamp;
        /* timeInterval= timeInterval;*/
        CRP = _CRP;
        BASE_RISK_RATE = _BASE_RISK_RATE;
        RISK_PREMIUM_RATE = _RISK_PREMIUM_RATE;
        //Push an initial vault to the userVaults array.
        vault memory initialVault = vault({
            rupioIssued: 0,
            userAddress: address(0),
            vaultId: 0,
            balance: 0,
            balanceInINR: 0,
            vaultHealth: 0
        });
        userVaults.push(initialVault);
    }

    /**
     * @notice Create a new vault or add funds in an existing vault.
     * @notice Public function.
     * @notice User needs to send a msg.value with the functions, in ETH currently.
     * @dev Msg.value must be in native decimals, in this case 1e18.
     * @return vaultId Vault id of the user.
     */
    function createOrUpdateVault() public payable returns (uint256 vaultId) {
        require(
            msg.value > 0,
            CollateralSafeKeep__ETHAmountMustBeGreaterThanZero()
        );
        //If the user has no vault previously.
        if (userIndexes[msg.sender] == 0) {
            vault memory newVault;
            newVault.balance = msg.value;
            newVault.userAddress = msg.sender;
            newVault.vaultId = VAULT_ID;
            newVault.rupioIssued = 0; //Initially it will be 0 for a new vault
            newVault.vaultHealth = _getAmountETHToINR(msg.value) * 100; //Full health for new vault
            newVault.balanceInINR = _getAmountETHToINR(msg.value);
            //Push the new vault to the userVaults array.
            userVaults.push(newVault);
            //Update the mapping of address to vault id.
            userIndexes[msg.sender] = VAULT_ID;
            //Increment global vault id counter.
            VAULT_ID = VAULT_ID + 1;
        }
        //If the user has a vault previously.
        else {
            //Update user balance in ETH and INR.
            userVaults[userIndexes[msg.sender]].balance += msg.value;
            userVaults[userIndexes[msg.sender]]
                .balanceInINR = _getAmountETHToINR(
                userVaults[userIndexes[msg.sender]].balance
            );
            //Update user vault health.
            userVaults[userIndexes[msg.sender]].vaultHealth = _getVaultHealth(
                msg.sender
            );
        }
        return userVaults[userIndexes[msg.sender]].vaultId;
    }

    /**
     * @notice Mint rupio based on collateral provided.
     * @notice Public function.
     * @notice User needs to have a vault first.
     * @notice One rupio is issued for every ruppee of collateral(in ETH, converted to INR).
     * @notice User cannot mint if vault health is lower than 150 percent of CRP.
     * @param amount Amount of rupio to be minted, in no decimals, example 50, should be less than CRP cross.
     * @return max Max amount of rupio that can be minted.
     */
    function mintRupio(uint256 amount) public yesVault returns (uint256) {
        require(
            amount > 0,
            CollateralSafeKeep__ETHAmountMustBeGreaterThanZero()
        );
        //Update vault health first.
        userVaults[userIndexes[msg.sender]].vaultHealth = _getVaultHealth(
            msg.sender
        );
        require(
            userVaults[userIndexes[msg.sender]].vaultHealth > CRP,
            CollateralSafekeep__UserInDebt()
        );
        //Calculate the maximum number of rupio tokens that a user can mint based on vault health.
        uint256 max = _getMaxMintableRupio(msg.sender);
        require(amount < max, "enter amount less than CRP cross");
        //Mint rupio tokens to the user.
        token.mint(msg.sender, amount);
        //Update user's rupio issued and vault health in array UserVaults.
        userVaults[userIndexes[msg.sender]].rupioIssued += amount;
        userVaults[userIndexes[msg.sender]].vaultHealth = _getVaultHealth(
            msg.sender
        );
        return max;
    }

    /**
     * @notice User can withdraw if any excess collateral than 150 percent of rupio issued.
     * @notice Public function.
     * @param amount Amount of ETH to withdraw from vault.
     */
    function withdrawFromVault(uint256 amount) public payable yesVault {
        //Update vault health first.
        userVaults[userIndexes[msg.sender]].vaultHealth = _getVaultHealth(
            msg.sender
        );
        require(
            amount > 0,
            CollateralSafeKeep__ETHAmountMustBeGreaterThanZero()
        );
        require(
            userVaults[userIndexes[msg.sender]].balance >= amount,
            "insufficient balance in vault"
        );
        require(
            userVaults[userIndexes[msg.sender]].vaultHealth > 150,
            CollateralSafekeep__UserInDebt()
        );
        //Calculate the maximum amount of ETH that the user can withdraw from vault.
        uint256 max = _getMaxWithdrawableCollateral(msg.sender);
        require(amount <= max, CollateralSafekeep__UserInDebt());
        //Transfer the amount ETH into calling user's address.
        payable(msg.sender).transfer(amount);
        //Update balance in ETH and INR, and vault health in array UserVaults.
        userVaults[userIndexes[msg.sender]].balance -= amount;
        userVaults[userIndexes[msg.sender]].balanceInINR = _getAmountETHToINR(
            userVaults[userIndexes[msg.sender]].balance
        );
        userVaults[userIndexes[msg.sender]].vaultHealth = _getVaultHealth(
            msg.sender
        );
    }

    /**
     * @notice Burn Rupio and relieve collateral in ETH from the vault.
     * @notice Public function.
     * @notice User must have a vault first.
     * @param amount Amount of rupio to burn.
     */
    function burnRupioAndRelieveCollateral(uint256 amount) public yesVault {
        //Update vault health first.
        userVaults[userIndexes[msg.sender]].vaultHealth = _getVaultHealth(
            msg.sender
        );
        require(
            userVaults[userIndexes[msg.sender]].rupioIssued > 0,
            "No rupio issued yet."
        );
        require(
            userVaults[userIndexes[msg.sender]].rupioIssued >= amount,
            "Less amount of rupio issued"
        );
        //Burn rupio tokens from user's vault.
        token.burnFrom(msg.sender, amount);
        //Update user's rupio issued and vault health in array UserVaults.
        userVaults[userIndexes[msg.sender]].rupioIssued -= amount;
        userVaults[userIndexes[msg.sender]].vaultHealth = _getVaultHealth(
            msg.sender
        );
    }

    /**
     * @notice Chainlink automation function to check if the conditions are met to perform upkeep.
     * @notice Public function.
     * @return upkeepNeeded Bool indicating if upkeep is needed, based on specific conditions.
     */
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        upkeepNeeded = true;
    }

    /**
     * @notice Chainlink automation function to perform upkeep.
     * @notice Public function.
     * @dev In this case, it is scanning all the vaults in database and updating vault health for them.
     * @dev Needed because we cannot tranditionally loop over all the vaults to update vault health.
     */
    function performUpkeep(bytes calldata /* performData */) external override {
        scanVaults();
    }

    /**
     * @notice Scans all the vaults in database and updates vault health for them.
     * @notice Public function.
     * @dev Needed because we cannot tranditionally loop over all the vaults to update vault health due to gas costs.
     * @dev Called by chainlink automation or can be called by moderators or good keepers of this protocol.
     */
    function scanVaults() public {
        //Get userVaults array length.
        uint256 userVaultArrayLength = userVaults.length;
        //Start a for loop to update INR balances and vault health.
        for (uint256 i = 0; i < userVaultArrayLength; i++) {
            userVaults[i].balanceInINR = getUserBalanceInINR(
                userVaults[i].userAddress
            );
            userVaults[i].vaultHealth = getVaultHealth(
                userVaults[i].userAddress
            );
            bool yesOrNo = _getIsLiquidationCondition(
                userVaults[i].userAddress
            );
            if (yesOrNo = true) {
                liquidateVault(userVaults[i].userAddress);
                emit thisIsARiskyVault(
                    i,
                    userVaults[i].userAddress,
                    userVaults[i].balance,
                    userVaults[i].balanceInINR,
                    userVaults[i].rupioIssued,
                    userVaults[i].vaultHealth
                );
            }
        }
    }

    /**
     * @notice Liquidates vaults that get too risky.
     * @dev Moderator only funciton.
     */
    function liquidateVault(address _vaultAddress) public onlyModerator {}

    /**
     * @notice Public getter function.
     * @return uint256 Collateral to rupio percentage threshold defined by the DAO.
     */
    function getCRP() public view returns (uint256) {
        return CRP;
    }

    /**
     * @notice Public getter function.
     * @return uint256 Base Risk Rate on all collateral types defined by the DAO.
     */
    function getBASE_RISK_RATE() public view returns (uint256) {
        return BASE_RISK_RATE;
    }

    /**
     * @notice Public getter function.
     * @return uint256 Risk Premium Rate on specific collateral type defined by the DAO.
     */
    function getRISK_PREMIUM_RATE() public view returns (uint256) {
        return RISK_PREMIUM_RATE;
    }

    /**
     * @notice Public getter function.
     * @notice User must have a vault first.
     * @return vault Struct indicating user's vault details.
     */
    function getVaultDetailsForTheUser()
        public
        view
        yesVault
        returns (vault memory)
    {
        return userVaults[userIndexes[msg.sender]];
    }

    /**
     * @notice Calculates the vault health of an address based on current collateral and rupio issued.
     * @notice Moderator only getter function.
     * @param _user Address of user.
     * @return uint256 Vault health.
     */
    function getVaultHealth(
        address _user /*onlyModerator*/
    ) public view returns (uint256) {
        return _getVaultHealth(_user);
    }

    /**
     * @notice Moderator only getter function.
     * @param _address Address of the user
     * @return uint256 Collateral balance in ETH in native decimals, in this case 1e18.
     */
    function getUserCollateralBalance(
        address _address /*onlyModerator*/
    ) public view returns (uint256) {
        return userVaults[userIndexes[_address]].balance;
    }

    /**
     * @notice Moderator only getter function.
     * @dev Can be used to get total number of vaults in the system.
     * @dev Vault Id starts from 1.
     * @return uint256 Current global counter of vault ids.
     */
    function getCurrentVaultId()
        public
        view
        returns (/*onlyModerator*/ uint256)
    {
        return VAULT_ID;
    }

    /**
     * @notice Moderator only getter function.
     * @return int256 Total collateral balance of the whole contract in ETH in native decimals, in this case 1e18
     */
    function getTotalCollateralPrice()
        public
        view
        returns (
            /*onlyModerator*/
            int256
        )
    {
        return currentCollateralBalance;
    }

    /**
     * @notice Moderator only getter function.
     * @return vault[] Total database of vaults in array of structs userVaults.
     */
    function getTotalVaultDetails()
        public
        view
        returns (
            /*onlyModerator*/
            vault[] memory
        )
    {
        return userVaults;
    }

    /**
     * @notice Moderator only getter function.
     * @param _address Address of the user.
     * @return uint256 User's current collateral balance in INR in native decimals, in this case 1e8.
     */
    function getUserBalanceInINR(
        address _address /*onlyModerator*/
    ) public view returns (uint256) {
        uint256 bal = userVaults[userIndexes[_address]].balance; // In 18 decimals cuz ETH.

        return _getAmountETHToINR(bal);
    }

    /**
     * @notice Moderator only getter function.
     * @param amountINR Amount of INR to be converted to ETH, in native decimals in this case 1e8.
     * @return uint256 Amount of ETH converted to INR, in native decimals in this case 1e18.
     */
    function getAmountINRToETH(
        uint256 amountINR /*onlyModerator*/
    ) public view returns (uint256) {
        return _getAmountINRToETH(amountINR);
    }

    /**
     * @notice Moderator only getter function.
     * @param user Address of the user.
     * @return uint256 Max amount of collateral that can be withdrawn by a user at current state in native decimals, in this case 1e18.
     */
    function getMaxWithdrawableCollateral(
        address user /*onlyModerator*/
    ) public view returns (uint256) {
        return _getMaxWithdrawableCollateral(user);
    }

    /**
     * @notice Moderator only getter function.
     * @param user Address of the user.
     * @return uint256 Maximum amount of rupio that can be minted by a user at current state in no decimals.
     */
    function getMaxMintableRupio(
        address user /*onlyModerator*/
    ) public view returns (uint256) {
        return _getMaxMintableRupio(user);
    }

    /**
     * @notice Internal getter function.
     * @param _user Address of the user.
     * @return uint256 Vault health of the user at current state.
     */
    function _getVaultHealth(address _user) internal view returns (uint256) {
        uint256 collateral = userVaults[userIndexes[_user]].balanceInINR; //In INR, 8 decimals.
        uint256 rupioIssued = userVaults[userIndexes[_user]].rupioIssued; //In uint256 token quantity,can say 1 token = 1 inr.
        if (rupioIssued == 0) {
            return collateral * 100;
        } else {
            uint256 _vaultHealth = ((collateral / (rupioIssued * 1e8)) * 100);
            return _vaultHealth;
        }
    }

    /**
     * @notice Internal getter function.
     * @dev Liquidation condition is met when vault health is less than CRP.
     * @param user Address of the user.
     * @return bool Is liquidation condition met for the user.
     */
    function _getIsLiquidationCondition(
        address user
    ) internal view returns (bool) {
        uint256 current = getVaultHealth(user);
        if (current > CRP) {
            return false;
        } else {
            return true;
        }
    }

    /**
     * @notice Internal getter function.
     * @param amountETH Amount of ETH to be converted to INR, in native decimals in this case 1e18.
     * @return uint256 Amount ETH converted to INR, in native decimals in this case 1e8.
     */
    function _getAmountETHToINR(
        uint256 amountETH
    ) internal view returns (uint256) {
        int256 a = priceContract.ETHtoUSD(); // in 8 decimals cuz usd

        int256 b = priceContract.INRtoUSD(); // in 8 decimals cuz usd
        uint256 c = (amountETH * uint256(a)) / uint256(b);

        uint256 d = (c / 1e10);
        return d;
    }

    /**
     * @notice Internal getter function.
     * @param amountINR Amount of INR to be converted to ETH, in native decimals in this case 1e8.
     * @return uint256 Amount INR converted to ETH, in native decimals in this case 1e18.
     */
    function _getAmountINRToETH(
        uint256 amountINR
    ) internal view returns (uint256) {
        int256 a = priceContract.ETHtoUSD();
        int256 b = priceContract.INRtoUSD();
        uint256 c = (uint256(b) * amountINR) / uint256(a);
        uint256 d = c * 1e10;
        return d;
    }

    /**
     * @notice Internal getter function.
     * @param user Address of the user.
     * @return uint256 Maximum amount of rupio that can be minted by a user at current state in no decimals.
     */
    function _getMaxMintableRupio(
        address user
    ) internal view returns (uint256) {
        if (userVaults[userIndexes[user]].vaultHealth < 150) {
            return 0;
        }
        uint256 bal = userVaults[userIndexes[user]].balance; //amount, can say 1 token = 1 inr
        uint256 _getUserBalanceInINR = _getAmountETHToINR(bal); // in 8 decimals
        uint256 rupioIssued = userVaults[userIndexes[user]].rupioIssued; //amount, can say 1 token = 1 inr
        uint256 totalAval = (_getUserBalanceInINR * 2) / (3 * 1e8);
        uint256 grand = totalAval - rupioIssued;
        return grand;
    }

    /**
     * @notice Internal getter function.
     * @param user Address of the user.
     * @return uint256 Max amount of collateral that can be withdrawn by a user at current state in native decimals, in this case 1e18.
     */
    function _getMaxWithdrawableCollateral(
        address user
    ) internal view returns (uint256) {
        uint256 collateral = userVaults[userIndexes[user]].balanceInINR;
        uint256 rupioIssued = userVaults[userIndexes[user]].rupioIssued;
        require(
            (userVaults[userIndexes[user]].rupioIssued) * 1e8 <
                userVaults[userIndexes[user]].balanceInINR,
            "you are in debt!"
        );
        require(
            userVaults[userIndexes[user]].vaultHealth > CRP,
            "you are in debt"
        );
        if (rupioIssued == 0) {
            return _getAmountINRToETH(collateral);
        } else {
            uint256 a = (rupioIssued * 3) / 2;
            uint256 b = a * 1e8;
            uint256 c = collateral - b;

            uint256 d = _getAmountINRToETH(c);
            return d;
        }
    }
}
