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

    IERC20 constant DAI = IERC20(0x04B2A6E51272c82932ecaB31A5Ab5aC32AE168C3);
    IERC20 constant USDT = IERC20(0xAcDe43b9E5f72a4F554D4346e69e8e7AC8F352f0);
    IERC20 constant USDC = IERC20(0x19D66Abd20Fb2a0Fc046C139d5af1e97F09A695e);
    IAave constant aave = IAave(0x0b913A76beFF3887d35073b8e5530755D60F78C7);
    IGains constant gains = IGains(0x5215C8B3e76D493c8bcb9A7352F7afe18A6bb091);
    IGainsEpoch constant gainsEpoch =
        IGainsEpoch(0xa7c829cb2346e12dc49fd5ea8002abaf48e9396c);
    IPrimex constant primex =
        IPrimex(0x30a676Cfde63e855Ab072269808eD192736cb46D);

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
    error TokenTransferFailed();

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

    function withdraw(address tokenAddress, uint256 _amount) public {
        if (
            !(tokenAddress == address(DAI) ||
                tokenAddress == address(USDT) ||
                tokenAddress == address(USDC))
        ) {
            revert InvalidToken();
        }

        if (investors[msg.sender].balances[tokenAddress] < _amount) {
            revert InsufficientInvestorBalance();
        }

        investors[msg.sender].balances[tokenAddress] -= _amount;

        if (!IERC20(tokenAddress).transfer(msg.sender, _amount)) {
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
