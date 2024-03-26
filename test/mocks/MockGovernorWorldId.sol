// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {GovernorWorldID} from 'contracts/GovernorWorldID.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {Governor, IERC6372, IGovernor} from 'open-zeppelin/governance/Governor.sol';
import {GovernorCountingSimple} from 'open-zeppelin/governance/extensions/GovernorCountingSimple.sol';
import {GovernorVotes, IVotes} from 'open-zeppelin/governance/extensions/GovernorVotes.sol';
import {GovernorVotesQuorumFraction} from 'open-zeppelin/governance/extensions/GovernorVotesQuorumFraction.sol';

interface IMockGovernorWorldIdForTest {
  function forTest_castVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    string memory _reason,
    bytes memory _params
  ) external;

  function forTest_validateUniqueVote(uint8 _support, uint256 _proposalId, bytes memory _proofData) external;
}

contract MockGovernorWorldId is GovernorCountingSimple, GovernorVotes, GovernorVotesQuorumFraction, GovernorWorldID {
  constructor(
    uint256 _groupID,
    IWorldIDRouter _worldIdRouter,
    bytes memory _appId,
    IVotes _token,
    uint48 _initialVotingDelay,
    uint32 _initialVotingPeriod,
    uint256 _initialProposalThreshold
  )
    GovernorWorldID(
      _groupID,
      _worldIdRouter,
      _appId,
      'Governor',
      _initialVotingDelay,
      _initialVotingPeriod,
      _initialProposalThreshold
    )
    GovernorVotes(_token)
    GovernorVotesQuorumFraction(4)
  {}

  function forTest_castVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    string memory _reason,
    bytes memory _params
  ) public {
    _castVote(_proposalId, _account, _support, _reason, _params);
  }

  function forTest_validateUniqueVote(uint8 _support, uint256 _proposalId, bytes memory _proofData) public {
    _validateUniqueVote(_support, _proposalId, _proofData);
  }

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

  function votingDelay() public view virtual override(Governor, GovernorWorldID) returns (uint256) {
    return super.votingDelay();
  }

  function votingPeriod() public view virtual override(Governor, GovernorWorldID) returns (uint256) {
    return super.votingPeriod();
  }

  function proposalThreshold() public view virtual override(Governor, GovernorWorldID) returns (uint256) {
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
}
