# Tradegen Protocol

## Purpose

Implementation of a decentralized asset management system on the Celo blockchain.

## Disclaimer

This protocol is deprecated. For the latest version of the asset management protocol, visit https://github.com/Tradegen/protocol-v2.

## System Design

### Smart Contracts

* ERC20Verifier - Checks if an ERC20 token is valid.
* UbeswapLPVerifier - Checks if a LP token created by Ubeswap is valid.
* UbeswapFarmVerifier - Checks if a pool's call to a Ubeswap farm contract is valid.
* UbeswapRouterVerifier - Checks if a pool's call to the Ubeswap router contract is valid.
* AddressResolver - Stores the address of each contract in the protocol.
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
