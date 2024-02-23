// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 Tokemak Foundation. All rights reserved.
pragma solidity 0.8.17;

import { Roles } from "src/libs/Roles.sol";
import { Errors } from "src/utils/Errors.sol";
import { ISystemRegistry } from "src/interfaces/ISystemRegistry.sol";
import { IAccessController } from "src/interfaces/security/IAccessController.sol";
import { AccessControlEnumerable } from "openzeppelin-contracts/access/AccessControlEnumerable.sol";
import { SystemComponent } from "src/SystemComponent.sol";

contract AccessController is SystemComponent, AccessControlEnumerable, IAccessController {
    // ------------------------------------------------------------
    //          Pre-initialize roles list for deployer
    // ------------------------------------------------------------
    constructor(address _systemRegistry) SystemComponent(ISystemRegistry(_systemRegistry)) {
        Errors.verifyNotZero(_systemRegistry, "systemRegistry");

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(Roles.REBALANCER_ROLE, msg.sender);
        _setupRole(Roles.CREATE_POOL_ROLE, msg.sender);
    }

    // ------------------------------------------------------------
    //               Role management methods
    // ------------------------------------------------------------
    function setupRole(bytes32 role, address account) external {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert AccessDenied();
        }

        // only do if role is not registered already
        if (!hasRole(role, account)) {
            _setupRole(role, account);
        }
    }

    function verifyOwner(address account) public view {
        if (!hasRole(DEFAULT_ADMIN_ROLE, account)) {
            revert AccessDenied();
        }
    }
}
