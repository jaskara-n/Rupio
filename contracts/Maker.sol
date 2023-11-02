// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract MAKER is ERC20, ERC20Burnable, ERC20Permit {
    address[] public tokenHolders;
    address public admin;
    uint256 public basePrice;

    constructor() ERC20("MAKER", "MKR") ERC20Permit("MAKER") {
        _mint(msg.sender, 200 * 10 ** decimals());
    }

    function setBasePrice(uint256 amount) public authicatedMinter {
        basePrice = amount;
    }

    function mint(uint256 amount) public authicatedMinter {
        _mint(address(this), amount);
    }

    modifier authicatedMinter() {
        require(balanceOf(msg.sender) > 0, "Caller is not a token holder");
        _;
    }

    function buyMaker(uint256 amount) public payable {
        require(msg.value > 0, "pay value must be greater than 0");
        require(basePrice > 0, "basePrice is not set yet");
        require(
            msg.value == basePrice,
            "Pay value is not match with token price"
        );
        transfer(msg.sender, amount);
    }
}
