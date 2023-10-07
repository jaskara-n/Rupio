// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract OffchainCompute {
    /************STRUCTS******************/
    struct vault {
        uint256 vaultId;
        address userAddress;
        uint256 balance;
        uint256 indaiIssued;
    }

    /************MAPS******************/
    mapping(address => bool) computers;

    /**************ARRAYS***************/
    vault[] internal liquidationVaults;

    /**************MODIFIERS***************/
    modifier onlyComputer() {
        require(computers[msg.sender] == true, "Caller is not owner");
        _;
    }

    constructor() {
        computers[msg.sender] = true;
    }

    function getLiquidationVaults()
        external
        view
        onlyComputer
        returns (vault[] memory)
    {
        return liquidationVaults;
    }

    function setLiquidationVaults(vault[] memory vaults) external onlyComputer {
        delete liquidationVaults;
        for (uint256 i = 0; i < vaults.length; i++) {
            liquidationVaults.push(vaults[i]);
        }
    }

    function setAsComputer(address _new, bool status) external onlyComputer {
        computers[_new] = status;
    }
}

