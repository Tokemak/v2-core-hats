// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 Tokemak Foundation. All rights reserved.
pragma solidity 0.8.17;

import { Stats } from "src/stats/Stats.sol";
import { Roles } from "src/libs/Roles.sol";
import { Errors } from "src/utils/Errors.sol";
import { SecurityBase } from "src/security/SecurityBase.sol";
import { ISystemRegistry } from "src/interfaces/ISystemRegistry.sol";
import { IStatsCalculator } from "src/interfaces/stats/IStatsCalculator.sol";
import { ICurveRegistry } from "src/interfaces/external/curve/ICurveRegistry.sol";
import { IStatsCalculatorRegistry } from "src/interfaces/stats/IStatsCalculatorRegistry.sol";

/// @title Base Stats Calculator
/// @notice Captures common behavior across all calculators
/// @dev Performs security checks and general roll-up behavior
abstract contract BaseStatsCalculator is IStatsCalculator, SecurityBase {
    ISystemRegistry public immutable systemRegistry;

    modifier onlyStatsSnapshot() {
        if (!_hasRole(Roles.STATS_SNAPSHOT_ROLE, msg.sender)) {
            revert Errors.MissingRole(Roles.STATS_SNAPSHOT_ROLE, msg.sender);
        }
        _;
    }

    constructor(ISystemRegistry _systemRegistry) SecurityBase(address(_systemRegistry.accessController())) {
        systemRegistry = _systemRegistry;
    }

    /// @inheritdoc IStatsCalculator
    function snapshot() external override onlyStatsSnapshot {
        if (!shouldSnapshot()) {
            revert NoSnapshotTaken();
        }
        _snapshot();
    }

    /// @notice Capture stat data about this setup
    /// @dev This is protected by the STATS_SNAPSHOT_ROLE
    function _snapshot() internal virtual;

    /// @inheritdoc IStatsCalculator
    function shouldSnapshot() public view virtual returns (bool takeSnapshot);
}
