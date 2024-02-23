// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

//slither-disable-next-line name-reused
interface IPool {
    function coins(uint256 i) external view returns (address);

    function balances(uint256 i) external view returns (uint256);

    // These method used for cases when Pool is a LP token at the same time
    function balanceOf(address account) external returns (uint256);

    // These method used for cases when Pool is a LP token at the same time
    function totalSupply() external returns (uint256);
}
