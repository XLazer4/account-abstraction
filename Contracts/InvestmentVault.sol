// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract InvestmentVault is Ownable {
    struct Investor {
        uint256 amountAllowed;
        mapping(address => bool) vaultManagers;
    }

    mapping(address => Investor) public investors;

    error UnauthorizedVaultManager();
    error ExceedsInvestorLimit();

    function setAllowance(uint256 _amountAllowed) public {
        investors[msg.sender].amountAllowed = _amountAllowed;
    }

    function addVaultManager(address _vaultManager) public {
        investors[msg.sender].vaultManagers[_vaultManager] = true;
    }

    function removeVaultManager(address _vaultManager) public {
        investors[msg.sender].vaultManagers[_vaultManager] = false;
    }

    function useFunds(address investorAddress, uint256 _amount) public {
        if (!investors[investorAddress].vaultManagers[msg.sender]) {
            revert UnauthorizedVaultManager();
        }

        if (investors[investorAddress].amountAllowed < _amount) {
            revert ExceedsInvestorLimit();
        }
    }
}
