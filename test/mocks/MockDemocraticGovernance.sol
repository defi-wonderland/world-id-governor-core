// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {DemocraticGovernance} from 'contracts/DemocraticGovernance.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';

interface IMockDemocraticGovernanceForTest {
  function forTest_castVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    string memory _reason,
    bytes memory _params
  ) external returns (uint256);

  function forTest_castVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    string memory _reason
  ) external returns (uint256);

  function forTest_countVote(uint256 _proposalId, address _account, uint8 _support, uint256 _weight) external;

  function forTest_getVotes(
    address _account,
    uint256 _timepoint,
    bytes memory _params
  ) external view returns (uint256 _votingWeight);

  function forTest_quorumReached(uint256 _proposalId) external view returns (bool _reached);
}

contract MockDemocraticGovernance is DemocraticGovernance {
  constructor(
    uint256 _groupID,
    IWorldIDRouter _worldIdRouter,
    bytes memory _appId,
    uint256 _quorum,
    uint48 _initialVotingDelay,
    uint32 _initialVotingPeriod,
    uint256 _initialProposalThreshold,
    uint256 _rootExpirationThreshold
  )
    DemocraticGovernance(
      _groupID,
      _worldIdRouter,
      _appId,
      _quorum,
      _initialVotingDelay,
      _initialVotingPeriod,
      _initialProposalThreshold,
      _rootExpirationThreshold
    )
  {}

  function forTest_castVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    string memory _reason,
    bytes memory _params
  ) public returns (uint256) {
    return _castVote(_proposalId, _account, _support, _reason, _params);
  }

  function forTest_castVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    string memory _reason
  ) public returns (uint256) {
    return _castVote(_proposalId, _account, _support, _reason);
  }

  function forTest_countVote(uint256 _proposalId, address _account, uint8 _support, uint256 _weight) public {
    _countVote(_proposalId, _account, _support, _weight, bytes(''));
  }

  function forTest_getVotes(
    address _account,
    uint256 _timepoint,
    bytes memory _params
  ) public view returns (uint256 _votingWeight) {
    return _getVotes(_account, _timepoint, _params);
  }

  function forTest_quorumReached(uint256 _proposalId) public view returns (bool _reached) {
    return _quorumReached(_proposalId);
  }
}
