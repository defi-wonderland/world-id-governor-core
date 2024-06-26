// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {GovernorDemocratic} from 'contracts/GovernorDemocratic.sol';
import {GovernorWorldID} from 'contracts/GovernorWorldID.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {Governor} from 'open-zeppelin/governance/Governor.sol';
import {GovernorCountingSimple} from 'open-zeppelin/governance/extensions/GovernorCountingSimple.sol';
import {GovernorSettings} from 'open-zeppelin/governance/extensions/GovernorSettings.sol';

contract GovernorDemocraticForTest is GovernorCountingSimple, GovernorDemocratic {
  constructor(
    uint256 _groupID,
    IWorldIDRouter _worldIdRouter,
    string memory _appId,
    uint48 _initialVotingDelay,
    uint32 _initialVotingPeriod,
    uint256 _initialProposalThreshold,
    uint256 _rootExpirationThreshold
  )
    Governor('GovernorDemocratic')
    GovernorSettings(_initialVotingDelay, _initialVotingPeriod, _initialProposalThreshold)
    GovernorWorldID(_groupID, _worldIdRouter, _appId, _rootExpirationThreshold)
  {}

  function forTest_getVotes(
    address _account,
    uint256 _timepoint,
    bytes memory _params
  ) public view returns (uint256 _votingWeight) {
    return _getVotes(_account, _timepoint, _params);
  }

  function quorum(uint256 blockNumber) public view override returns (uint256) {
    return quorum(blockNumber);
  }

  function CLOCK_MODE() public view override returns (string memory) {
    return CLOCK_MODE();
  }

  function clock() public view override returns (uint48) {
    return clock();
  }

  function votingDelay() public view virtual override(Governor, GovernorSettings) returns (uint256) {
    return super.votingDelay();
  }

  function votingPeriod() public view virtual override(Governor, GovernorSettings) returns (uint256) {
    return super.votingPeriod();
  }

  function proposalThreshold() public view virtual override(Governor, GovernorSettings) returns (uint256) {
    return super.proposalThreshold();
  }

  function _castVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    string memory _reason
  ) internal override(Governor, GovernorWorldID) returns (uint256) {
    return super._castVote(_proposalId, _account, _support, _reason);
  }

  function _castVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    string memory _reason,
    bytes memory _params
  ) internal override(Governor, GovernorWorldID) returns (uint256) {
    return super._castVote(_proposalId, _account, _support, _reason, _params);
  }

  function _propose(
    address[] memory _targets,
    uint256[] memory _values,
    bytes[] memory _calldatas,
    string memory _description,
    address _proposer
  ) internal virtual override(Governor, GovernorWorldID) returns (uint256 _proposalId) {
    _proposalId = super._propose(_targets, _values, _calldatas, _description, _proposer);
  }
}
