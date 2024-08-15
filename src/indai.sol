// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Indai is ERC20 {
    constructor() ERC20("INDAI", "IND") {}

    function mint(address _add, uint256 _amount) public {
        _mint(_add, _amount);
    }

    function burnFrom(address _add, uint256 _amount) public {
        _burn(_add, _amount);
    }
}
