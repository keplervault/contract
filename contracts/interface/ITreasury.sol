// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

interface ITreasury {
    function invest(address recipient) external;
    function setFee(uint256 _fee) external;
}