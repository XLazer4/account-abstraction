pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenSwap is Ownable {
    IERC20 public token1;
    IERC20 public token2;
    IERC20 public token3;

    uint256 constant token1Decimals = 10 ** 6; 
    uint256 constant token3Decimals = 10 ** 18; /

    error TransferFailed(address token);
    error InvalidTokenAddress(address token);

    constructor(address _token1, address _token2, address _token3) {
        token1 = IERC20(_token1);
        token2 = IERC20(_token2);
        token3 = IERC20(_token3);
    }

    function addLiquidity(
        uint256 token1Amount,
        uint256 token2Amount,
        uint256 token3Amount
    ) public onlyOwner {
        if (!token1.transferFrom(msg.sender, address(this), token1Amount))
            revert TransferFailed(address(token1));
        if (!token2.transferFrom(msg.sender, address(this), token2Amount))
            revert TransferFailed(address(token2));
        if (
            !token3.transferFrom(
                msg.sender,
                address(this),
                (token3Amount * token3Decimals) / token1Decimals
            )
        ) revert TransferFailed(address(token3));
    }

    function refund() public onlyOwner {
        uint256 balance;
        balance = token1.balanceOf(address(this));
        if (balance > 0) {
            if (!token1.transfer(msg.sender, balance))
                revert TransferFailed(address(token1));
        }
        balance = token2.balanceOf(address(this));
        if (balance > 0) {
            if (!token2.transfer(msg.sender, balance))
                revert TransferFailed(address(token2));
        }
        balance = token3.balanceOf(address(this));
        if (balance > 0) {
            if (!token3.transfer(msg.sender, balance))
                revert TransferFailed(address(token3));
        }
    }

    function swapTokens(
        address fromTokenAddress,
        address toTokenAddress,
        uint256 amount
    ) public {
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

        IERC20 fromToken = IERC20(fromTokenAddress);
        IERC20 toToken = IERC20(toTokenAddress);

        if (!fromToken.transferFrom(msg.sender, address(this), amount))
            revert TransferFailed(address(fromToken));

        if (
            fromTokenAddress == address(token3) ||
            toTokenAddress == address(token3)
        ) {
            amount = (fromTokenAddress == address(token3))
                ? (amount * token1Decimals) / token3Decimals
                : (amount * token3Decimals) / token1Decimals;
        }

        if (!toToken.transfer(msg.sender, amount))
            revert TransferFailed(address(toToken));
    }
}
