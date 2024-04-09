# GovernorWorldID

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/defi-wonderland/world-id-governor-core/blob/main/LICENSE)

⚠️ The code has not been audited yet, tread with caution.

## Overview

The GovernorWorldID contract is designed to offer a Sybil-resistant voting framework, ensuring that only orb-verified addresses can participate in DAO voting processes via World ID. This system is built to be both versatile and extensible. 

The GovernorDemocratic contract capitalizes on this feature to establish democratic governance for DAOs. It achieves this by assigning a voting power of one vote per voter, ensuring an equitable and transparent voting process.

## Setup

This project uses [Foundry](https://book.getfoundry.sh/). To build it locally, run:

```sh
git clone git@github.com:defi-wonderland/world-id-governor-core.git
cd world-id-governor-core
yarn install
yarn build
```

## Implementing the abstracts

You can implement [GovernorWorldID](src/contracts/GovernorWorldID.sol) and [GovernorDemocratic](src/contracts/GovernorDemocratic.sol) abstract contracts and use it as base to create your own governance protocols.
When implementing the contracts, other functions and extensions related to OpenZeppelin standard contracts should be implemented as well.

An example implementation of GovernorWorldID would like:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {GovernorWorldID} from 'contracts/GovernorWorldID.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {Governor, IERC6372, IGovernor} from '@openzeppelin/contracts/governance/Governor.sol';
import {GovernorCountingSimple} from '@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol';

contract Governance is GovernorCountingSimple, GovernorWorldID {
  constructor(
    uint256 _groupID,
    IWorldIDRouter _worldIdRouter,
    string memory _appId,
    string memory _governorName,
    uint48 _initialVotingDelay,
    uint32 _initialVotingPeriod,
    uint256 _initialProposalThreshold,
    uint256 _rootExpirationThreshold
  )
    GovernorWorldID(
      _groupID,
      _worldIdRouter,
      _appId,
      _governorName,
      _initialVotingDelay,
      _initialVotingPeriod,
      _initialProposalThreshold,
      _rootExpirationThreshold
    )
  {}

  function votingDelay() public view virtual override(Governor, GovernorWorldID) returns (uint256 _votingDelay) {
    _votingDelay = super.votingDelay();
  }

  function votingPeriod() public view virtual override(Governor, GovernorWorldID) returns (uint256 _votingPeriod) {
    _votingPeriod = super.votingPeriod();
  }

  function proposalThreshold()
    public
    view
    virtual
    override(Governor, GovernorWorldID)
    returns (uint256 _proposalThreshold)
  {
    _proposalThreshold = super.proposalThreshold();
  }

  function quorum(uint256 _timepoint) public view override(Governor, IGovernor) returns (uint256 _quorumThreshold) {
    _quorumThreshold = quorum(_timepoint);
  }

  function clock() public view override(Governor, IERC6372) returns (uint48 _clock) {
    _clock = clock();
  }

  function CLOCK_MODE() public pure override(Governor, IERC6372) returns (string memory _mode) {
    _mode = CLOCK_MODE();
  }

  function _castVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    string memory _reason
  ) internal override(Governor, GovernorWorldID) returns (uint256) {
    super._castVote(_proposalId, _account, _support, _reason);
  }

  function _castVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    string memory _reason,
    bytes memory _params
  ) internal override(Governor, GovernorWorldID) returns (uint256 _votingWeight) {
    _votingWeight = super._castVote(_proposalId, _account, _support, _reason, _params);
  }

  function _getVotes(
    address _account,
    uint256 _timepoint,
    bytes memory _params
  ) internal view virtual override(Governor) returns (uint256 _votingWeight) {
    _votingWeight = _getVotes(_account, _timepoint, _params);
  }
}

```
### Available Commands

Make sure to set `OPTIMISM_RPC` environment variable before running integration tests.

| Yarn Command            | Description                                                |
| ----------------------- | ---------------------------------------------------------- |
| `yarn build`            | Compile all contracts.                                     |
| `yarn coverage`         | See `forge coverage` report.                               |
| `yarn test`             | Run all unit and integration tests.                        |
| `yarn test:unit`        | Run unit tests.                                            |
| `yarn test:integration` | Run integration tests.                                     |

## Licensing

The primary license for Prophet contracts is MIT, see [`LICENSE`](./LICENSE).

## Contributors

GovernorWorldID was built with ❤️ by [Wonderland](https://defi.sucks).

Wonderland is a team of top Web3 researchers, developers, and operators who believe that the future needs to be open-source, permissionless, and decentralized.

[DeFi sucks](https://defi.sucks), but Wonderland is here to make it better.