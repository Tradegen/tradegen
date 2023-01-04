# Tradegen Protocol

## Purpose

Implementation of a decentralized asset management system on the Celo blockchain.

## Overview

Users can invest in pools of assets (decentralized hedge funds) that are managed by other users or external projects. When users invest in a pool, they receive tokens that represent their share of the assets in the pool. These tokens fluctuate in value based on the price of the pool's underlying assets and lifetime performance. To withdraw from a pool, users can burn their pool tokens and pay a performance fee to the pool manager (if they are withdrawing for a profit). Users receive their share of the pool’s assets when they withdraw.

Pools are represented by smart contracts that pool managers can interact with using the platform’s UI. These contracts send transactions to whitelisted DeFi projects on the pool’s behalf, eliminating the possibility of pool managers withdrawing other users’ investments into their own account or calling unsupported contracts.

In addition to pools, users can also invest in ‘NFT pools’ with a capped supply of pool tokens (each of which is an NFT) and different levels of scarcity (represented by four classes of tokens). These tokens can be traded on the platform’s marketplace or deposited into farms to earn yield while staying invested in the pool. Since there’s a max supply of pool tokens, tokens on the marketplace may trade above mint price based on factors such as pool’s past performance, token class, farm yield, and pool manager’s reputation.

## Disclaimer

This protocol is deprecated. For the latest version of the asset management protocol, visit https://github.com/Tradegen/protocol-v2.

## System Design

### Smart Contracts

* ERC20Verifier - Checks if an ERC20 token is valid.
* UbeswapLPVerifier - Checks if a LP token created by Ubeswap is valid.
* UbeswapFarmVerifier - Checks if a pool's call to a Ubeswap farm contract is valid.
* UbeswapRouterVerifier - Checks if a pool's call to the Ubeswap router contract is valid.
* AddressResolver - Stores the address of each contract in the protocol.
* AssetHandler - Tracks whitelisted assets and handles price calculations.
* BaseUbeswapAdapter - Makes calls to the Ubeswap router and farm contracts. Used for calculating price and checking if an address is valid.
* ERC20PriceAggregator - Calculates the price of an ERC20 token.
* Marketplace - Used for buying/selling NFT Pool tokens.
* NFTPool - A pool with a fixed number of tokens, each of which is an NFT.
* NFTPoolFactory - Creates NFTPool contracts.
* Ownable - Provides authorization control for contracts.
* Pool - A decentralized hedge fund. Stores a collection of assets and is managed by a user or an external contract.
* PoolFactory - Creates Pool contracts.
* Settings - Tracks the parameters used throughout the protocol.
* TradegenLPStakingEscrow - An escrow that holds tokens for the liquidity mining rewards program.
* TradegenLPStakingRewards - Implements the liquidity mining rewards program.
* TradegenStakingEscrow - An escrow that holds tokens for the staking program.
* TradegenStakingRewards - Implements the staking rewards program.
* UbeswapLPTokenPriceAggregator - Calculates the price of a Ubeswap LP token.
* UbeswapPathManager - Stores the optimal path for swapping to/from each whitelisted asset.

## Repository Structure

```
.
├── addresses  ## Address of each deployed contract, organized by network.
├── audits  ## Audit reports.
├── build/abi  ## Generated ABIs that developers can use to interact with the system.
├── contracts  ## All source code.
│   ├── interfaces  ## Interfaces used for defining/calling contracts.
│   ├── libraries  ## Libraries storing helper functions.
│   ├── openzeppelin-solidity  ## Helper contracts provided by OpenZeppelin.
│   ├── test  ## Mock contracts used for testing main contracts.
│   ├── verifiers  ## Contracts for verifying external protocols.
├── test ## Source code for testing code in //contracts.
```

## Documentation

To learn more about the Tradegen project, visit the docs at https://docs.tradegen.io.

To learn more about Celo, visit their home page: https://celo.org/.

## License

MIT
