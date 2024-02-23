// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 Tokemak Foundation. All rights reserved.
pragma solidity 0.8.17;

import { Roles } from "src/libs/Roles.sol";
import { Errors } from "src/utils/Errors.sol";
import { SecurityBase } from "src/security/SecurityBase.sol";
import { Clones } from "openzeppelin-contracts/proxy/Clones.sol";
import { ISystemRegistry } from "src/interfaces/ISystemRegistry.sol";
import { IStatsCalculator } from "src/interfaces/stats/IStatsCalculator.sol";
import { IStatsCalculatorFactory } from "src/interfaces/stats/IStatsCalculatorFactory.sol";
import { SystemComponent } from "src/SystemComponent.sol";

contract StatsCalculatorFactory is SystemComponent, IStatsCalculatorFactory, SecurityBase {
    using Clones for address;

    /// @notice Registered stat calculator templates
    mapping(bytes32 => address) public templates;

    modifier onlyCreator() {
        if (!_hasRole(Roles.CREATE_STATS_CALC_ROLE, msg.sender)) {
            revert Errors.MissingRole(Roles.CREATE_STATS_CALC_ROLE, msg.sender);
        }
        _;
    }

    modifier onlyTemplateManager() {
        if (!_hasRole(Roles.STATS_CALC_TEMPLATE_MGMT_ROLE, msg.sender)) {
            revert Errors.MissingRole(Roles.STATS_CALC_TEMPLATE_MGMT_ROLE, msg.sender);
        }
        _;
    }

    event TemplateRemoved(bytes32 aprTemplateId, address template);
    event TemplateRegistered(bytes32 aprTemplateId, address newTemplate);
    event TemplateReplaced(bytes32 aprTemplateId, address oldAddress, address newAddress);

    error TemplateAlreadyRegistered(bytes32 aprTemplateId);
    error TemplateDoesNotExist(bytes32 aprTemplateId);
    error TemplateReplaceMismatch(bytes32 aprTemplateId, address actualOld, address specifiedOld);
    error TemplateReplaceMatches(bytes32 aprTemplateId, address actualOld, address specifiedOld);

    constructor(ISystemRegistry _systemRegistry)
        SystemComponent(_systemRegistry)
        SecurityBase(address(_systemRegistry.accessController()))
    { }

    /// @inheritdoc IStatsCalculatorFactory
    function create(
        bytes32 aprTemplateId,
        bytes32[] calldata dependentAprIds,
        bytes calldata initData
    ) external onlyCreator returns (address calculatorAddress) {
        // Get the template to clone
        address template = templates[aprTemplateId];
        Errors.verifyNotZero(template, "template");

        // Copy and set it up
        calculatorAddress = template.clone();
        IStatsCalculator(calculatorAddress).initialize(dependentAprIds, initData);

        // Add the vault to the registry
        systemRegistry.statsCalculatorRegistry().register(calculatorAddress);
    }

    /// @notice Register a new template
    /// @dev Does not allow overwriting an aprTemplateId, must replace or remove first
    /// @param aprTemplateId id of the template
    /// @param newTemplate address of the template
    function registerTemplate(bytes32 aprTemplateId, address newTemplate) external onlyTemplateManager {
        Errors.verifyNotZero(aprTemplateId, "aprTemplateId");
        Errors.verifyNotZero(newTemplate, "template");

        // Cannot overwrite an existing template
        if (templates[aprTemplateId] != address(0)) {
            revert TemplateAlreadyRegistered(aprTemplateId);
        }

        emit TemplateRegistered(aprTemplateId, newTemplate);

        templates[aprTemplateId] = newTemplate;
    }

    /// @notice Replace an template registered with an id
    /// @dev Requires an existing registration. Specified old template must match. New can't match old
    /// @param aprTemplateId id of the template
    /// @param oldTemplate address of currently registered template
    /// @param newTemplate address of new template to register with id
    function replaceTemplate(
        bytes32 aprTemplateId,
        address oldTemplate,
        address newTemplate
    ) external onlyTemplateManager {
        Errors.verifyNotZero(aprTemplateId, "aprTemplateId");
        Errors.verifyNotZero(oldTemplate, "oldTemplate");
        Errors.verifyNotZero(newTemplate, "newTemplate");

        // Make sure you're replacing what you think you are
        if (templates[aprTemplateId] != oldTemplate) {
            revert TemplateReplaceMismatch(aprTemplateId, templates[aprTemplateId], oldTemplate);
        }

        // If you're trying to replace with the same template you're probably
        // not doing what you think you're doing
        if (oldTemplate == newTemplate) {
            revert TemplateReplaceMatches(aprTemplateId, templates[aprTemplateId], oldTemplate);
        }

        emit TemplateReplaced(aprTemplateId, oldTemplate, newTemplate);

        templates[aprTemplateId] = newTemplate;
    }

    /// @notice Remove a registered template
    /// @dev Must have a template set with id or will revert
    /// @param aprTemplateId id of the template
    function removeTemplate(bytes32 aprTemplateId) external onlyTemplateManager {
        Errors.verifyNotZero(aprTemplateId, "aprTemplateId");

        // Template must exist otherwise why would you have called
        if (templates[aprTemplateId] == address(0)) {
            revert TemplateDoesNotExist(aprTemplateId);
        }

        emit TemplateRemoved(aprTemplateId, templates[aprTemplateId]);

        delete templates[aprTemplateId];
    }
}
