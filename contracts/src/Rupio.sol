// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessManager} from "./AccessManager.sol";
import {OFT} from "@layerzerolabs/oft-evm/contracts/OFT.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Rupio.
 * @author Jaskaran Singh.
 * @notice A simple ERC20 token for the Rupio stablecoin, pegegd to 1 INR.
 * @notice Integrated with LayerZero OFT to make Rupio Crosschain.
 * @notice Integrated with RupioDao access manager to manage access.
 */
contract Rupio is Ownable, OFT {
    AccessManager internal accessManager;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint32 public chainEid;

    /**
     * @param _lzEndpoint LayerZero endpoint for the current chain.
     * @param _accessManager RupioDao AccessManager address.
     * @param _chainEid Layerzero ChainEid for the current chain.
     */
    constructor(
        address _lzEndpoint,
        address _accessManager,
        uint32 _chainEid
    ) OFT("Rupio", "RUP", _lzEndpoint, msg.sender) Ownable(msg.sender) {
        accessManager = AccessManager(_accessManager);
        chainEid = _chainEid;
    }

    /**
     * @notice Modifier to check if the msg.sender has Minter role in RupioDao AccessManager.
     */
    modifier onlyMinter() {
        require(accessManager.hasRole(MINTER_ROLE, msg.sender));
        _;
    }

    /**
     * @notice This function is used by the CSK contract to mint Rupio for investors.
     * @param _add The address to mint Rupio to.
     * @param _amount The amount of Rupio to mint.
     */
    function mint(address _add, uint256 _amount) public /**onlyMinter*/ {
        _credit(_add, _amount, chainEid);
    }

    /**
     * @notice This function is used to burn any rupio tokens
     * @param _add Address of wallet to burn from.
     * @param _amount Amount to burn.
     */
    function burnFrom(address _add, uint256 _amount) public {
        _debit(_add, _amount, _amount - 100, chainEid);
    }

    function decimals() public pure override returns (uint8) {
        return 8;
    }
}
