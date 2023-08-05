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

    function redeem(uint256 shares, address receiver, address owner) external;
}

interface IGainsEpoch {
    function forceNewEpoch() external;
}

interface IPrimex {
    function deposit(address _for, uint256 _pid, uint256 _amount) external;

    function withdraw(address token, uint256 amount) external;
}

contract InvestmentVault is Ownable {
    struct Investor {
        uint256 amountAllowed;
        mapping(address => uint256) balances;
        mapping(address => bool) vaultManagers;
    }

    IERC20 constant DAI = "0x04B2A6E51272c82932ecaB31A5Ab5aC32AE168C3";
    IERC20 constant USDT = "0xAcDe43b9E5f72a4F554D4346e69e8e7AC8F352f0";
    IERC20 constant USDC = "0x19D66Abd20Fb2a0Fc046C139d5af1e97F09A695e";

    IAave public aave;
    IGains public gains;
    IGainsEpoch public gainsEpoch;
    IPrimex public primex;
    mapping(address => Investor) public investors;

    enum ActionType {
        AaveSupply,
        AaveWithdraw,
        GainsDeposit,
        GainsConvertToShares,
        GainsWithdrawRequest,
        GainsRedeem,
        GainsEpochForceNewEpoch,
        PrimexDeposit,
        PrimexWithdraw
    }

    error InvalidToken();
    error UnauthorizedVaultManager();
    error ExceedsInvestorLimit();
    error InsufficientInvestorBalance();
    error TokenTransferFailed()

    constructor(
        address _aave,
        address _gains,
        address _gainsEpoch,
        address _primex
    ) {
        aave = IAave(_aave);
        gains = IGains(_gains);
        gainsEpoch = IGainsEpoch(_gainsEpoch);
        primex = IPrimex(_primex);
    }

    function deposit(address tokenAddress, uint256 _amount) public {
        IERC20 token;

        if (tokenAddress == address(DAI)) {
            token = DAI;
        } else if (tokenAddress == address(USDT)) {
            token = USDT;
        } else if (tokenAddress == address(USDC)) {
            token = USDC;
        } else {
            revert InvalidToken();
        }

        if (!token.transferFrom(msg.sender, address(this), _amount)) {
            revert TokenTransferFailed();
        }

        investors[msg.sender].balances[tokenAddress] += _amount;
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

    function executeInvestmentPlan(
        address investorAddress,
        uint256 _amount,
        ActionType[] memory steps
    ) public {
        if (!investors[investorAddress].vaultManagers[msg.sender]) {
            revert UnauthorizedVaultManager();
        }
        if (investors[investorAddress].amountAllowed < _amount) {
            revert ExceedsInvestorLimit();
        }
        for (uint256 i = 0; i < steps.length; i++) {
            if (steps[i] == ActionType.AaveSupply) {
                aave.supply(
                    address(investmentToken),
                    1000 /*amount*/,
                    address(this),
                    0
                );
            } else if (steps[i] == ActionType.AaveWithdraw) {
                aave.withdraw(
                    address(investmentToken),
                    1000 /*amount*/,
                    address(this)
                );
            } else if (steps[i] == ActionType.GainsDeposit) {
                gains.deposit(1000 /*amount*/, address(this));
            } else if (steps[i] == ActionType.GainsConvertToShares) {
                gains.convertToShares(1000 /*amount*/);
            } else if (steps[i] == ActionType.GainsWithdrawRequest) {
                gains.makeWithdrawRequest(1000 /*amount*/, address(this));
            } else if (steps[i] == ActionType.GainsRedeem) {
                gains.redeem(1000 /*amount*/, address(this), address(this));
            } else if (steps[i] == ActionType.GainsEpochForceNewEpoch) {
                gainsEpoch.forceNewEpoch();
            } else if (steps[i] == ActionType.PrimexDeposit) {
                primex.deposit(address(this), 0 /*pid*/, 1000 /*amount*/);
            } else if (steps[i] == ActionType.PrimexWithdraw) {
                primex.withdraw(address(investmentToken), 1000 /*amount*/);
            }
        }
    }
}
