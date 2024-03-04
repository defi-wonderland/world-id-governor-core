// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {GovernorWorldID} from 'contracts/GovernorWorldID.sol';
import {IWorldID} from 'interfaces/IWorldID.sol';
import {Governor, IERC6372, IGovernor} from 'open-zeppelin/governance/Governor.sol';
import {GovernorCountingSimple} from 'open-zeppelin/governance/extensions/GovernorCountingSimple.sol';
import {GovernorVotes, IVotes} from 'open-zeppelin/governance/extensions/GovernorVotes.sol';
import {GovernorVotesQuorumFraction} from 'open-zeppelin/governance/extensions/GovernorVotesQuorumFraction.sol';

contract MockGovernorWorldId is GovernorWorldID, GovernorCountingSimple, GovernorVotes, GovernorVotesQuorumFraction {
  constructor(
    IWorldID _worldId,
    string memory _appId,
    string memory _actionId,
    IVotes _token
  ) GovernorWorldID(_worldId, _appId, _actionId, 'Governor') GovernorVotes(_token) GovernorVotesQuorumFraction(4) {}

  function quorum(uint256 blockNumber)
    public
    view
    override(Governor, IGovernor, GovernorVotesQuorumFraction)
    returns (uint256)
  {
    return super.quorum(blockNumber);
  }

  // solhint-disable-next-line
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
}
