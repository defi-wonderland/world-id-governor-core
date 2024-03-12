// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {GovernorDemocratic} from 'contracts/GovernorDemocratic.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {Governor, IERC6372, IGovernor} from 'open-zeppelin/governance/Governor.sol';
import {GovernorCountingSimple} from 'open-zeppelin/governance/extensions/GovernorCountingSimple.sol';
import {GovernorVotes, IVotes} from 'open-zeppelin/governance/extensions/GovernorVotes.sol';
import {GovernorVotesQuorumFraction} from 'open-zeppelin/governance/extensions/GovernorVotesQuorumFraction.sol';

interface IMockGovernorDemocraticForTest {
  function forTest_castVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    string memory _reason
  ) external returns (uint256);

  function forTest_castVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    string memory _reason,
    bytes memory _params
  ) external returns (uint256);

  function forTest_getVotes(
    address _account,
    uint256 _timepoint,
    bytes memory _params
  ) external view returns (uint256 _votingWeight);
}

contract MockGovernorDemocratic is
  GovernorVotes,
  GovernorCountingSimple,
  GovernorVotesQuorumFraction,
  GovernorDemocratic
{
  constructor(
    uint256 _groupID,
    IWorldIDRouter _worldIdRouter,
    string memory _appId,
    string memory _actionId,
    IVotes _token
  )
    GovernorVotes(_token)
    GovernorVotesQuorumFraction(4)
    GovernorDemocratic(_groupID, _worldIdRouter, _appId, _actionId, 'Governor')
  {}

  function forTest_castVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    string memory _reason
  ) public returns (uint256) {
    return _castVote(_proposalId, _account, _support, _reason);
  }

  function forTest_castVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    string memory _reason,
    bytes memory _params
  ) public returns (uint256) {
    return _castVote(_proposalId, _account, _support, _reason, _params);
  }

  function forTest_getVotes(
    address _account,
    uint256 _timepoint,
    bytes memory _params
  ) public view returns (uint256 _votingWeight) {
    return _getVotes(_account, _timepoint, _params);
  }

  function quorum(uint256 blockNumber)
    public
    view
    override(Governor, IGovernor, GovernorVotesQuorumFraction)
    returns (uint256)
  {
    return super.quorum(blockNumber);
  }

  function CLOCK_MODE() public view override(Governor, GovernorVotes, IERC6372) returns (string memory) {
    return super.CLOCK_MODE();
  }

  function clock() public view override(Governor, GovernorVotes, IERC6372) returns (uint48) {
    return super.clock();
  }

  function votingDelay() public pure override(Governor, IGovernor) returns (uint256) {
    return 7200; // 1 day
  }

  function votingPeriod() public pure override(Governor, IGovernor) returns (uint256) {
    return 50_400; // 1 week
  }

  function _castVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    string memory _reason
  ) internal override(Governor, GovernorDemocratic) returns (uint256) {
    return super._castVote(_proposalId, _account, _support, _reason);
  }

  function _castVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    string memory _reason,
    bytes memory _params
  ) internal override(Governor, GovernorDemocratic) returns (uint256) {
    return super._castVote(_proposalId, _account, _support, _reason, _params);
  }

  function _getVotes(
    address _account,
    uint256 _timepoint,
    bytes memory _params
  ) internal view virtual override(Governor, GovernorVotes, GovernorDemocratic) returns (uint256) {
    return super._getVotes(_account, _timepoint, _params);
  }
}
