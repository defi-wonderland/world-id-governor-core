# GovernorWorldID

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/defi-wonderland/world-id-governor-core/blob/main/LICENSE)

⚠️ The code has not been audited yet, tread with caution.

## Overview

The `GovernorWorldID` contract is designed to offer a Sybil-resistant voting framework, ensuring that only orb-verified addresses can participate in DAO voting processes via World ID. 

The `GovernorDemocratic` contract capitalizes on this feature to establish democratic governance for DAOs. It achieves this by assigning a voting power of one vote per voter.

## Setup

This project uses [Foundry](https://book.getfoundry.sh/). To build it locally, run:

```sh
git clone git@github.com:defi-wonderland/world-id-governor-core.git
cd world-id-governor-core
yarn install
yarn build
```

### Available Commands

Make sure to set `OPTIMISM_RPC` environment variable before running integration tests.

| Yarn Command            | Description                                                |
| ----------------------- | ---------------------------------------------------------- |
| `yarn build`            | Compile all contracts.                                     |
| `yarn coverage`         | See `forge coverage` report.                               |
| `yarn test`             | Run all unit and integration tests.                        |
| `yarn test:unit`        | Run unit tests.                                            |
| `yarn test:integration` | Run integration tests. |

## Implementing the abstracts

You can implement [GovernorWorldID](src/contracts/GovernorWorldID.sol) and [GovernorDemocratic](src/contracts/GovernorDemocratic.sol) abstract contracts and use it as base to create your own governance protocols.
When implementing the contracts, other functions related to OpenZeppelin standard contracts should be implemented as well, depending on the implemented OZ extensions.
A GovernorDemocratic implementation already exists and can be found at [GoatsDAO.sol](src/contracts/GoatsDAO.sol).

### Deployment considerations

- `_groupID`: The group ID of the World ID group. Currently 1 for orb verification level.
- `_worldIdRouter`: The World ID router contract address, depending on the chain it was deployed. You can see the list [here](https://docs.worldcoin.org/reference/address-book)
- `_rootExpirationThreshold`: The time it takes for a root provided by the user to expire. See more [here](#double-voting-mitigation).

### SDK considerations
- `appId`: The application ID created on the [Worldcoin developer portal](https://developer.worldcoin.org/).
- `actionId`: The action ID is composed by the `proposalId` passed as a string.
- `signal`: The signal will be the support passed as a string.

### Double voting mitigation

In the WorldID protocol, users can choose to reset their account, and this re-insertion will take a certain amount of time (currently [14 days](https://docs.worldcoin.org/further-reading/world-id-reset)). To prevent this, the contract has `resetGracePeriod` and `rootExpirationThreshold` variables. The `resetGracePeriod` is the time it takes for a user to reset their account after the last reset. It's an arbitrary value and it's not on-chain, se we have to track it and update it if needed.

The `rootExpirationThreshold` is the time it takes for a root provided by the user to expire.
Then, when the `votingPeriod` variable is set, a check is performed to ensure that `votingPeriod` is less than the `resetGracePeriod` minus `rootExpirationThreshold`.
This way, the user will not be able to reset their account and vote again in the same proposal.

New WorldID accounts are inserted into the tree at a fast pace (currently 20 mins to 1 hour) changing the root from the Merkle tree. This means `latestRoot` changes very often, that's when `rootExpirationThreshold` comes into play. It adds some flexibility preventing a user from voting in a proposal with an old root.

`rootExpirationThreshold` for L2s can be any value while **_should always be 0 in Mainnet and Mainnet testnets_** due to a discrepancy between the WorldID protocol on Ethereum and L2s. 

If a safer version is desired, the latestRoot can be utilized, but it must be considered that it introduces the possibility wherein a user generates a valid proof for a Merkle root, but the root changes when they cast their vote on the transaction due to the fast pace of insertions. Adding a threshold to be used as a buffer is a wise choice, but we recommend using a small value, no more than 30 minutes or 1 hour, as the rootHistoryExpiry can be updated on the IdentityManager, potentially breaking the invariant of the voting period that ensures no double-voting can occur.

## Licensing

The primary license for GovernorWorldID contracts is MIT, see [`LICENSE`](./LICENSE).

## Contributors

GovernorWorldID was built with ❤️ by [Wonderland](https://defi.sucks).

Wonderland is a team of top Web3 researchers, developers, and operators who believe that the future needs to be open-source, permissionless, and decentralized.

[DeFi sucks](https://defi.sucks), but Wonderland is here to make it better.