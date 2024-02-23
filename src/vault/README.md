# Tokemak Vaults Docs

## Autopilot (LMP) Vaults

Autopilot Vaults will be the main jumping off point for end-user interactions with the system (though technically this is the Router, these are the tokens the user will get back). Users will deposit and withdraw the base asset from here. Vaults are ERC 4626 + Permit compatible.

An Autopilot Vault is actually a pair of contracts. These contracts are:

-   The Vault itself
-   A Convex-like, block height+rate style, Rewarder

The purpose of an Autopilot Vault is to represent a set of destinations that deposited assets may be deployed. It acts almost as an index. If an Autopilot Vault points to 5 destinations then your assets may be deployed to one or all of those destinations depending on how much those destinations are currently earning.

In this context, a “destination” is any DEX pool we are configured for: Balancer MetaStable/ComposableStable pools, Curve, and Maverick (mode both only). A “Destination Vault” is a vault contract that sits in front of each of those pools and represents it in our system.

## Base Asset

An Autopilot Vault should track it’s “base asset”. This is the asset that will be deposited and withdrawn from the Vault. Any auto-compounding that happens will be in terms of the base asset, as well. The result of this is that an Autopilot Vault should only accept Destination Vaults in its Strategy that match it’s base asset. However, it is expected that the Autopilot Vaults associated Rewarder can emit any token(s).

## Tracked Tokens

Vaults should treat tokens that they “track” different than other tokens. “Tracked” tokens are those that make up it’s core functionality. For an Autopilot Vault, that would be WETH and any Destination Vault LP tokens it holds. Tokens that are included in the Rewarder should never be stored directly in the Vault contract so it is safe to consider them “non-tracked”.

## Autopilot Rewards (the Rewarder)

Autopilot Vaults generate yield in multiple ways. One of the ways they do this is through auto-compounding. Auto-compounding happens at the Rebalancer + Destination Vault levels and isn’t much of a concern Autopilot the Autopilot Vault itself. However, each Autopilot Vault is itself a participant in a Convex-style Rewarder. This rewarder that emits some amount of TOKE or other tokens. The Rewarder itself doesn’t take a deposit of the Autopilot Vault LP token, but it is up to the Autopilot Vault to update the users balance in the rewarder before any minting/burning/transferring of the Autopilot LP units occurs.

An LMPVault can have multiple rewarders, however only one will be actively supplied with rewards. The others will be put into a `pastRewarders` state variable. NOTE: This structure leaves a loophole where users can 'hide' tokens in a deprecated rewarder and get around any imposed per wallet limit. This is a known possibility and was determined to be okay. This is because the wallet limit is only planned to be used during any ramp up phase that the vault may have, after that it will not be used.

## Profit Loss & Reporting

Periodically, an automated process will trigger a reporting event for the destinations related to an Autopilot Vault. An Autopilot Vault will compare it’s last known debt that is attributed to a Destination to that Destinations current reporting of its assets and determine if we are sitting with a profit or a loss. If we are in a loss scenario, we decrease our debt value immediately. If we are sitting at a profit, we take a fee, and recalculate the value.

## Performance Fee

Any time a profit is reported, the protocol is minted shares of the Autopilot Vault to represent the fee they are taking. Autopilot Vaults can have unique fee %’s.

## Destination Vaults

Destination Vaults are vaults that sit in front of any place we may be deploying assets. These vaults act as a common interface to these various places allowing us to hide the intricacies of DeFi from the rest of the system. These vaults also hold any receipt tokens we receive from these deployments. These are not 4626 vaults.

To facilitate the testing of these vaults, each type of destination has an explicitly defined contract in our code base. These are top-level contracts with minimal code, with the majority of the functionality being accessed from the Destination Vault contracts and Adapter libraries.

Destination Vaults mint shares on 1:1 proportion against their underlyer and they're priced in terms of Vault's "base asset".

Every new Vault should be based on `src/vault/DestinationVault.sol` which encapsulates all the common functionality and gives the ability to child contracts to define the details of integrating with the specific exchanges. Destination Vaults usually combine two sources of operating destinations: the base layer of depositing (usually a pool) and LP staking part. E.g. in `CurveConvexDestinationVault` we operate with assets deployed to Curve and manage the rewards from staking Curve LPs to Convex.

### Tracked Tokens

Vaults treat tokens that they “track” different than other tokens. “Tracked” tokens are those that make up it’s core functionality. For example, if a Destination Vault is targeting a stETH/rETH DEX pool, then the LP token of that pool, stETH, and rETH would all be considered “tracked” tokens. Additionally, the “base asset” for the vault, in our MVP case WETH, falls into this category.

### Data

-   `idle` - This is the amount of the base asset that is currently in the vault
-   `debt` - This is the amount of the base asset that has been transferred away from Vault in service of a deployment.
    -   For example, if the Vault contained 100 idle WETH and we decided to deploy the entire lot, idle would go to 0, and debt would go to 100
