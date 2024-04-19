# GovernorWorldID

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/defi-wonderland/world-id-governor-core/blob/main/LICENSE)

⚠️ The code has not been audited yet, tread with caution.

## Overview

The GovernorWorldID contract is designed to offer a Sybil-resistant voting framework, ensuring that only orb-verified addresses can participate in DAO voting processes via World ID. 

The GovernorDemocratic contract capitalizes on this feature to establish democratic governance for DAOs. It achieves this by assigning a voting power of one vote per voter.

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
A GovernorDemocratic implementation already exists and can be found at [DemocraticGovernance.sol](src/contracts/DemocraticGovernance.sol).

### Deployment considerations

- `_groupID`: The group ID of the World ID group. 1 for orb verification level.
- `_worldIdRouter`: The World ID router contract address, depending on the chain it was deployed. You can see the list [here](https://docs.worldcoin.org/reference/address-book)
- `_rootExpirationThreshold`: The time it takes for a root provided by the user to expire. See more [here](#double-voting-mitigation).

### SDK considerations
- `_appId`: The application ID created on the WorldID [developer portal](https://developer.worldcoin.org/).
- `actionId`: The action ID is composed by the `proposalId` passed as a string.
- `signal`: The signal will be the support passed as a string. And will be hashed to be used in the actionId.

### Double voting mitigation

In the WorldID protocol, users can choose to reset their account each certain amount of time. To prevent this, the contract has `resetGracePeriod` and `rootExpirationThreshold` variables. The `resetGracePeriod` is the time it takes for a user to reset their account after the last reset. The `rootExpirationThreshold` is the time it takes for a root provided by the user to expire.
Then, when the `votingPeriod` variable is set, a check is performed to ensure that `votingPeriod` is less than the `resetGracePeriod` minus `rootExpirationThreshold`.
This way, the user will not be able to reset their account and vote again in the same proposal.

New WorldID accounts are inserted into the tree at a fast pace (currently 20 mins to 1 hour) changing the root from the Merkle tree. This means `latestRoot` changes very often, that's when `rootExpirationThreshold` comes into play. It adds some flexibility preventing a user from voting in a proposal with an old root.

`rootExpirationThreshold` should never be 0 in Mainnet and Mainnet testnets due to a discrepancy between the WorldID protocol on Ethereum and L2s. 

We recommend setting `rootExpirationThreshold` as small as possible, but always greater than 0. For example: 20 minutes, so it forces the root to be recent while giving the user enough time to generate the proof and vote. At the same time, Governance should be aware of changes in the `rootHistoryExpiry` in the Router contract, and update the variables accordingly.

## Licensing

The primary license for GovernorWorldID contracts is MIT, see [`LICENSE`](./LICENSE).

## Contributors

GovernorWorldID was built with ❤️ by [Wonderland](https://defi.sucks).

Wonderland is a team of top Web3 researchers, developers, and operators who believe that the future needs to be open-source, permissionless, and decentralized.

[DeFi sucks](https://defi.sucks), but Wonderland is here to make it better.