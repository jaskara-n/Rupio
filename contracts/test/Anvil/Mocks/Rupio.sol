// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessManager} from "../../../src/AccessManager.sol";

/**
 * @title Indai.
 * @author Jaskaran Singh.
 * @notice A simple ERC20 token for the INDAI stablecoin, pegegd to 1 INR.
 * @notice Integrated with Indai access manager to manage access.
 */
contract Rupio is ERC20 {
    AccessManager internal accessManager;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address _accessManager) ERC20("INDAI", "IND") {
        accessManager = AccessManager(_accessManager);
    }

    modifier onlyMinter() {
        require(accessManager.hasRole(MINTER_ROLE, msg.sender));
        _;
    }

    function mint(address _add, uint256 _amount) public /* onlyMinter */ {
        _mint(_add, _amount);
    }

    function burnFrom(address _add, uint256 _amount) public {
        _burn(_add, _amount);
    }

    function decimals() public pure override returns (uint8) {
        return 8;
    }
}
