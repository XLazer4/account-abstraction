// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface ITokenSwap {
    function swapTokens(
        address fromTokenAddress,
        address toTokenAddress,
        uint256 amount
    ) external;
}

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

    function balanceOf(address account) external returns (uint256);

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

contract InvestmentVault is ReentrancyGuard {
    struct Investor {
        uint256 amountAllowed;
        // mapping(address => uint256) balances;
        mapping(address => bool) vaultManagers;
    }

    uint256 constant INT_MAX = 2 ** 256 - 1;
    IERC20 constant DAI = IERC20(0x04B2A6E51272c82932ecaB31A5Ab5aC32AE168C3);
    IERC20 constant USDT = IERC20(0xAcDe43b9E5f72a4F554D4346e69e8e7AC8F352f0);
    IERC20 constant USDC = IERC20(0x19D66Abd20Fb2a0Fc046C139d5af1e97F09A695e);
    ITokenSwap immutable tokenSwap;
    IAave constant aave = IAave(0x0b913A76beFF3887d35073b8e5530755D60F78C7);
    IGains constant gains = IGains(0x5215C8B3e76D493c8bcb9A7352F7afe18A6bb091);
    IGainsEpoch constant gainsEpoch =
        IGainsEpoch(0xA7C829CB2346E12DC49Fd5ea8002Abaf48E9396C);
    IPrimex constant primex =
        IPrimex(0x30a676Cfde63e855Ab072269808eD192736cb46D);

    mapping(address => Investor) public investors;

    enum ActionType {
        TokenSwap,
        AaveSupply,
        AaveWithdraw,
        GainsDeposit,
        GainsWithdrawRequest,
        GainsEpochForceNewEpoch,
        GainsRedeem,
        PrimexDeposit,
        PrimexWithdraw
    }

    event InvestorDeposited(
        address indexed investor,
        address indexed token,
        uint256 amount
    );
    event InvestorWithdrew(
        address indexed investor,
        address indexed token,
        uint256 amount
    );
    event InvestmentPlanExecuted(
        address indexed investor,
        address indexed executor,
        uint256 stepsExecuted
    );

    error InvalidToken();
    error UnauthorizedVaultManager();
    error ExceedsInvestorLimit();
    error InsufficientInvestorBalance();
    error TokenTransferFailed();

    constructor(address _tokenSwap) {
        tokenSwap = ITokenSwap(_tokenSwap);
        DAI.approve(_tokenSwap, INT_MAX);
        USDT.approve(_tokenSwap, INT_MAX);
        USDC.approve(_tokenSwap, INT_MAX);
    }

    function deposit(address tokenAddress, uint256 _amount) external {
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

        // investors[msg.sender].balances[tokenAddress] += _amount;

        emit InvestorDeposited(msg.sender, tokenAddress, _amount);
    }

    function withdraw(address tokenAddress, uint256 _amount) external {
        if (
            !(tokenAddress == address(DAI) ||
                tokenAddress == address(USDT) ||
                tokenAddress == address(USDC))
        ) {
            revert InvalidToken();
        }

        // if (investors[msg.sender].balances[tokenAddress] < _amount) {
        //     revert InsufficientInvestorBalance();
        // }

        // investors[msg.sender].balances[tokenAddress] -= _amount;

        if (!IERC20(tokenAddress).transfer(msg.sender, _amount)) {
            revert TokenTransferFailed();
        }

        emit InvestorWithdrew(msg.sender, tokenAddress, _amount);
    }

    function setAllowance(uint256 _amountAllowed) external {
        investors[msg.sender].amountAllowed = _amountAllowed;
    }

    function addVaultManager(address _vaultManager) external {
        investors[msg.sender].vaultManagers[_vaultManager] = true;
    }

    function removeVaultManager(address _vaultManager) external {
        investors[msg.sender].vaultManagers[_vaultManager] = false;
    }

    function executeInvestmentPlan(
        address investorAddress,
        address _tokenToSwapFrom,
        address _swapToTokenAddress,
        uint256 _amount,
        ActionType[] memory steps
    ) external {
        if (!investors[investorAddress].vaultManagers[msg.sender]) {
            revert UnauthorizedVaultManager();
        }
        if (investors[investorAddress].amountAllowed < _amount) {
            revert ExceedsInvestorLimit();
        }
        for (uint256 i = 0; i < steps.length; i++) {
            if (steps[i] == ActionType.TokenSwap) {
                tokenSwap.swapTokens(
                    _tokenToSwapFrom,
                    _swapToTokenAddress,
                    _amount
                );
            } else if (steps[i] == ActionType.AaveSupply) {
                USDT.approve(address(aave), 100 * 10 ** 6);
                aave.supply(address(USDT), 100 * 10 ** 6, address(this), 0);
            } else if (steps[i] == ActionType.AaveWithdraw) {
                aave.withdraw(address(USDT), 100 * 10 ** 6, address(this));
            } else if (steps[i] == ActionType.GainsDeposit) {
                DAI.approve(address(gains), 100 * 10 ** 18);
                gains.deposit(100 * 10 ** 18, address(this));
            } else if (steps[i] == ActionType.GainsWithdrawRequest) {
                uint256 gainsTokenBalance = gains.balanceOf(address(this));
                gains.makeWithdrawRequest(gainsTokenBalance, address(this));
            } else if (steps[i] == ActionType.GainsEpochForceNewEpoch) {
                gainsEpoch.forceNewEpoch();
            } else if (steps[i] == ActionType.GainsRedeem) {
                uint256 gainsTokenBalance = gains.balanceOf(address(this));
                gains.redeem(gainsTokenBalance, address(this), address(this));
            } else if (steps[i] == ActionType.PrimexDeposit) {
                USDC.approve(address(primex), 100 * 10 ** 6);
                primex.deposit(address(this), 100 * 10 ** 6, 0);
            } else if (steps[i] == ActionType.PrimexWithdraw) {
                primex.withdraw(address(this), 100 * 10 ** 6);
            }
        }

        emit InvestmentPlanExecuted(investorAddress, msg.sender, steps.length);
    }

    function executeInvestmentPlan2(
        address investorAddress,
        address[] memory targets,
        bytes[] memory data
    ) external {
        require(targets.length == data.length, "Mismatched inputs");

        for (uint256 i = 0; i < targets.length; i++) {
            if (!investors[investorAddress].vaultManagers[msg.sender]) {
                revert UnauthorizedVaultManager();
            }

            (bool success, ) = targets[i].call(data[i]);
            require(success, "Transaction execution failed");
        }
    }
}
