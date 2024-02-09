// SPDX-License-Identifier: MIT

//This contract is governed by ---------, this is only the erc20 interface of the system

pragma solidity ^0.8.8;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Indai is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    ERC20PermitUpgradeable, Ownable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _initialOwner) {
        _disableInitializers();
        Ownable(_initialOwner);
    }

    function initialize() public initializer {
        __ERC20_init("Indai", "ind");
        __ERC20Burnable_init();
        __ERC20Permit_init("Indai");
    }

    function mint(address to, uint256 amount) public onlyOwner{
        _mint(to, amount);
    }
}
