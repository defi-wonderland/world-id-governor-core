// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Constants} from './Constants.sol';
import {DemocraticGovernance} from 'contracts/DemocraticGovernance.sol';
import {Script, console} from 'forge-std/Script.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';

abstract contract Deploy is Script, Constants {
  function _deploy(
    uint256 _groupId,
    IWorldIDRouter _worldIdRouter,
    string memory _appId,
    uint256 _quorum,
    uint48 _initialVotingDelay,
    uint32 _initialVotingPeriod,
    uint256 _initialProposalThreshold,
    uint256 _rootExpirationThreshold
  ) internal returns (DemocraticGovernance _democraticGovernance) {
    _democraticGovernance = new DemocraticGovernance(
      _groupId,
      _worldIdRouter,
      _appId,
      _quorum,
      _initialVotingDelay,
      _initialVotingPeriod,
      _initialProposalThreshold,
      _rootExpirationThreshold
    );
    console.log('Democratic Governance deployed at:', address(_democraticGovernance));
  }
}