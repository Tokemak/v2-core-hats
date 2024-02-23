// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 Tokemak Foundation. All rights reserved.

pragma solidity 0.8.17;

import { Errors } from "src/utils/Errors.sol";
import { ISystemRegistry } from "src/interfaces/ISystemRegistry.sol";
import { IPriceOracle } from "src/interfaces/oracles/IPriceOracle.sol";
import { SystemComponent } from "src/SystemComponent.sol";

/// @title Price oracle for tokens we want to configure 1:1 to ETH. WETH for example
/// @dev getPriceEth is not a view fn to support reentrancy checks. Dont actually change state.
contract EthPeggedOracle is SystemComponent, IPriceOracle {
    constructor(ISystemRegistry _systemRegistry) SystemComponent(_systemRegistry) { }

    /// @inheritdoc IPriceOracle
    function getPriceInEth(address) external pure returns (uint256 price) {
        price = 1e18;
    }
}
