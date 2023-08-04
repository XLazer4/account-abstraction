// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract InvestmentVault is Ownable {
    struct Investor {
        uint256 balance;
        uint256 amountAllowed;
        mapping(address => bool) vaultManagers;
    }

    mapping(address => Investor) public investors;

    IERC20 public investmentToken;

    error UnauthorizedVaultManager();
    error ExceedsInvestorLimit();
    error InsufficientInvestorBalance();
    error TokenTransferFailed();

    constructor(IERC20 _investmentToken) {
        investmentToken = _investmentToken;
    }

    function deposit(uint256 _amount) public {
        if (!investmentToken.transferFrom(msg.sender, address(this), _amount)) {
            revert TokenTransferFailed();
        }

        investors[msg.sender].balance += _amount;
    }

    function withdraw(uint256 _amount) public {
        if (investors[msg.sender].balance < _amount) {
            revert InsufficientInvestorBalance();
        }
        investors[msg.sender].balance -= _amount;
        if (!investmentToken.transfer(msg.sender, _amount)) {
            revert TokenTransferFailed();
        }
    }

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
