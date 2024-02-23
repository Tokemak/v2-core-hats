// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 Tokemak Foundation. All rights reserved.
pragma solidity 0.8.17;

import { Stats } from "src/stats/Stats.sol";
import { ISystemRegistry } from "src/interfaces/ISystemRegistry.sol";
import { ICurveRegistry } from "src/interfaces/external/curve/ICurveRegistry.sol";
import { CurvePoolNoRebasingCalculatorBase } from "src/stats/calculators/base/CurvePoolNoRebasingCalculatorBase.sol";
import { IStatsCalculator } from "src/interfaces/stats/IStatsCalculator.sol";
import { IDexLSTStats } from "src/interfaces/stats/IDexLSTStats.sol";
import { ICurveV1StableSwap } from "src/interfaces/external/curve/ICurveV1StableSwap.sol";
import { ICurveOwner } from "src/interfaces/external/curve/ICurveOwner.sol";

/// @title Curve V1 Pool No Rebasing
/// @notice Calculate stats for a Curve V1 StableSwap pool
/// @dev Do not use this contract for pools with ETH due to a reentrancy issue
contract CurveV1PoolNoRebasingStatsCalculator is CurvePoolNoRebasingCalculatorBase {
    constructor(ISystemRegistry _systemRegistry) CurvePoolNoRebasingCalculatorBase(_systemRegistry) { }

    function getVirtualPrice() internal view override returns (uint256 virtualPrice) {
        // NOTE: this contract is not intended to be used with ETH pools due to reentrancy issues
        return ICurveV1StableSwap(poolAddress).get_virtual_price();
    }
}
