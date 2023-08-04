// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IAave {
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(address asset, uint256 amount, address to) external;
}

interface IGains {
    function deposit(uint256 assets, address receiver) external;

    function convertToShares(uint256 assets) external;

    function makeWithdrawRequest(uint256 shares, address owner) external;
}

interface IGainsEpoch {
    function forceNewEpoch() external;
}

interface IPrimeX {
    function deposit(address _for, uint256 _pid, uint256 _amount) external;

    function withdraw(address token, uint256 amount) external;
}

contract InvestmentVault is Ownable {
    struct Investor {
        uint256 balance;
        uint256 amountAllowed;
        mapping(address => bool) vaultManagers;
    }

    IERC20 public investmentToken;
    IAave public aave;
    IGains public gains;
    IGainsEpoch public gainsEpoch;
    IPrimeX public primex;
    mapping(address => Investor) public investors;

    error UnauthorizedVaultManager();
    error ExceedsInvestorLimit();
    error InsufficientInvestorBalance();
    error TokenTransferFailed();

    constructor(
        IERC20 _investmentToken,
        address _aave,
        address _gains,
        address _gainsEpoch,
        address _primex
    ) {
        investmentToken = _investmentToken;
        aave = IAave(_aave);
        gains = IGains(_gains);
        gainsEpoch = IGainsEpoch(_gainsEpoch);
        primex = IPrimeX(_primex);
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
