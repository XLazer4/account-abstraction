// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC20WithDecimals is IERC20 {
    function decimals() external view returns (uint8);
}

contract TokenSwap is Ownable, ReentrancyGuard {
    IERC20WithDecimals public token1;
    IERC20WithDecimals public token2;
    IERC20WithDecimals public token3;

    event TokensSwapped(
        address indexed fromToken,
        address indexed toToken,
        address indexed user,
        uint256 amount
    );

    error TransferFailed(address token);
    error InvalidTokenAddress(address token);

    constructor(address _token1, address _token2, address _token3) {
        token1 = IERC20WithDecimals(_token1);
        token2 = IERC20WithDecimals(_token2);
        token3 = IERC20WithDecimals(_token3);
    }

    function getDecimals(address tokenAddress) internal view returns (uint8) {
        IERC20WithDecimals token = IERC20WithDecimals(tokenAddress);
        return token.decimals();
    }

    function refund() external onlyOwner {
        _refundToken(token1);
        _refundToken(token2);
        _refundToken(token3);
    }

    function swapTokens(
        address fromTokenAddress,
        address toTokenAddress,
        uint256 amount
    ) external {
        if (
            fromTokenAddress != address(token1) &&
            fromTokenAddress != address(token2) &&
            fromTokenAddress != address(token3)
        ) revert InvalidTokenAddress(fromTokenAddress);
        if (
            toTokenAddress != address(token1) &&
            toTokenAddress != address(token2) &&
            toTokenAddress != address(token3)
        ) revert InvalidTokenAddress(toTokenAddress);

        IERC20WithDecimals fromToken = IERC20WithDecimals(fromTokenAddress);
        IERC20WithDecimals toToken = IERC20WithDecimals(toTokenAddress);

        uint256 fromTokenDecimals = fromToken.decimals();
        uint256 toTokenDecimals = toToken.decimals();
        uint256 realAmount = amount * (10 ** fromTokenDecimals);

        if (!fromToken.transferFrom(msg.sender, address(this), realAmount))
            revert TransferFailed(fromTokenAddress);

        if (fromTokenDecimals > toTokenDecimals) {
            realAmount =
                realAmount /
                (10 ** (fromTokenDecimals - toTokenDecimals));
        } else if (toTokenDecimals > fromTokenDecimals) {
            realAmount =
                realAmount *
                (10 ** (toTokenDecimals - fromTokenDecimals));
        }

        if (!toToken.transfer(msg.sender, realAmount))
            revert TransferFailed(toTokenAddress);

        emit TokensSwapped(
            fromTokenAddress,
            toTokenAddress,
            msg.sender,
            amount
        );
    }

    function _refundToken(IERC20WithDecimals token) internal {
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            if (!token.transfer(msg.sender, balance))
                revert TransferFailed(address(token));
        }
    }
}
