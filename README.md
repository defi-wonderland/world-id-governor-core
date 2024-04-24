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

Make sure to copy `.env.example` and set `OPTIMISM_RPC` environment variable before running integration tests.

| Yarn Command            | Description                         |
| ----------------------- | ----------------------------------- |
| `yarn build`            | Compile all contracts.              |
| `yarn coverage`         | See `forge coverage` report.        |
| `yarn test`             | Run all unit and integration tests. |
| `yarn test:unit`        | Run unit tests.                     |
| `yarn test:integration` | Run integration tests.              |

## How to Use

You can implement [GovernorWorldID](src/contracts/GovernorWorldID.sol) and [GovernorDemocratic](src/contracts/GovernorDemocratic.sol) abstract contracts, and use them as the base to create your own governance protocols.
When implementing the contracts, other functions related to OpenZeppelin standard contracts should be implemented as well, depending on the implemented OZ extensions.
An implementation already exists and can be found at [GoatsDAO.sol](src/contracts/example/GoatsDAO.sol).

### Deployment Considerations

- `_groupID`: The group ID of the World ID group. Currently 1 for the orb verification level.
- `_worldIdRouter`: The World ID router contract address, depending on the chain it was deployed. You can see the list [here](https://docs.worldcoin.org/reference/address-book)
- `_rootExpirationThreshold`: The time it takes for a root provided by the user to expire. See more [here](#double-voting-mitigation).

### Good to know

To interact with Worldcoin's IDKit SDK to generate proofs, you'll need to pass the `appId`, `actionId` (string type) and `support` as `signal` (string type).

### Double Voting Mitigation

#### Mitigating The Reset Period Problem

In the World ID protocol, users can choose to reset their account. The re-insertion will take a certain amount of time (currently [14 days](https://docs.worldcoin.org/further-reading/world-id-reset)). This introduces the possibility of a double-voting scenario in case the voting period is greater than the period it takes a user to be re-inserted. This period is an arbitrary value and it's not on-chain, so we have to track it with the `resetGracePeriod` variable and update if it changes.
One way to mitigate the double-voting risk, is ensuring that the `votingPeriod` is less than the `resetGracePeriod`, checking the provided proof's Merkle root is equal to `latestRoot`. But there is a caveat:

New World ID accounts are inserted into the tree at a fast pace (currently 20 mins to 1 hour) changing the root from the Merkle tree. This means `latestRoot` changes very often, which can lead to the user generating the proof for a root, and then it is updated when he is casting the vote. That's when `rootExpirationThreshold` comes into play: It adds a buffer so the user can use an older root and not only the latest one, representing the time it takes for a root provided by the user to expire.

Finally, the invariant to mitigate the double-voting period is that `votingPeriod` must be less than the `resetGracePeriod` minus `rootExpirationThreshold`.

If a safer version is desired, you can set to only use the `latestRoot()` by setting `rootExpirationThreshold` to 0.
Adding a threshold to be used as a buffer is a wise choice, but we recommend using a small value, no more than 30 minutes or 1 hour, as the rootHistoryExpiry can be updated on the IdentityManager, potentially breaking the invariant of the voting period that ensures no double-voting can occur.

`rootExpirationThreshold` for L2s can be any value while **_should always be 0 in Mainnet and Mainnet testnets_** due to a discrepancy between the World ID protocol on Ethereum and L2s.

#### Nullifier Hash Usage

The nullifier hash is unique per WorldID account and per action. This means that the same user will always generate the same nullifier hash to vote on the same proposal. Storing and verifying whether it has been stored previously helps prevent duplicate votes on the same proposal.

## Licensing

The primary license for GovernorWorldID contracts is MIT, see [`LICENSE`](./LICENSE).

## Contributors

GovernorWorldID was built with ❤️ by [Wonderland](https://defi.sucks).

Wonderland is a team of top Web3 researchers, developers, and operators who believe that the future needs to be open-source, permissionless, and decentralized.

[DeFi sucks](https://defi.sucks), but Wonderland is here to make it better.
