// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IInternalBribe {
    function rewards(uint256 index) external view returns (address);
    function rewardsListLength() external view returns (uint256);
}
