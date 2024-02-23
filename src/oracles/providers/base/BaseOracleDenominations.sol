// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 Tokemak Foundation. All rights reserved.

pragma solidity 0.8.17;

import { IPriceOracle } from "src/interfaces/oracles/IPriceOracle.sol";
import { Errors } from "src/utils/Errors.sol";
import { ISystemRegistry } from "src/interfaces/ISystemRegistry.sol";
import { Ownable } from "openzeppelin-contracts/access/Ownable.sol";
import { SecurityBase } from "src/security/SecurityBase.sol";
import { SystemComponent } from "src/SystemComponent.sol";

/// @title Base functionalities for Chainlink and Tellor Oracle contracts.
abstract contract BaseOracleDenominations is SystemComponent, IPriceOracle, SecurityBase {
    /// @notice Used to denote what denomination a token is in.
    enum Denomination {
        ETH,
        USD
    }

    /// @notice Amount of time that can pass until a price is considered stale.
    uint256 public constant DEFAULT_PRICING_TIMEOUT = 2 hours;

    /**
     * @dev Address for unique use case where asset does not have price feed with ETh as
     *      quote asset.  This address must be registered with the Chainlink oracle contract
     *      using the ETH / USD feed for the corresponding chain.
     */
    address public constant ETH_IN_USD = address(bytes20("ETH_IN_USD"));

    // Thrown in the event that parameter returned with data is invalid.  Timestamp, pricing, etc.
    error InvalidDataReturned();

    constructor(ISystemRegistry _systemRegistry)
        SystemComponent(_systemRegistry)
        SecurityBase(address(_systemRegistry.accessController()))
    {
        Errors.verifyNotZero(address(_systemRegistry.rootPriceOracle()), "rootPriceOracle");
    }

    // Handles non-Eth denomination if neccessary.
    function _denominationPricing(
        Denomination denomination,
        uint256 normalizedPrice,
        address tokenToPrice
    ) internal returns (uint256) {
        if (tokenToPrice != ETH_IN_USD && denomination == Denomination.USD) {
            return _getPriceDenominationUSD(normalizedPrice);
        }
        return normalizedPrice;
    }

    /**
     * @notice Necessary due to of USD / Eth price feed.  Price of both assets in USD make it possible
     *      to get `normalizedPrice` in terms of Eth.  Many assets are priced in USD as opposed to Eth
     *      on Chainlink price feeds.
     *
     * @param normalizedPrice  Normalized price of asset in USD
     */
    function _getPriceDenominationUSD(uint256 normalizedPrice) private returns (uint256) {
        uint256 ethInUsd = systemRegistry.rootPriceOracle().getPriceInEth(ETH_IN_USD);

        return (normalizedPrice * (10 ** 18) / ethInUsd);
    }
}
