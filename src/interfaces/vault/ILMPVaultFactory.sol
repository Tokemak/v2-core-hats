// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 Tokemak Foundation. All rights reserved.
pragma solidity 0.8.17;

interface ILMPVaultFactory {
    ///////////////////////////////////////////////////////////////////
    //                        Vault Creation
    ///////////////////////////////////////////////////////////////////

    /**
     * @notice Spin up a new LMPVault
     * @param supplyLimit Total supply limit for the new vault
     * @param walletLimit Wallet limit for the new vault
     * @param symbolSuffix Symbol suffix of the new token
     * @param descPrefix Description prefix of the new token
     * @param salt Vault creation salt
     * @param extraParams Any extra data needed for the vault
     */
    function createVault(
        uint256 supplyLimit,
        uint256 walletLimit,
        string memory symbolSuffix,
        string memory descPrefix,
        bytes32 salt,
        bytes calldata extraParams
    ) external returns (address newVaultAddress);
}
