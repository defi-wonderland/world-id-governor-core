// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {DemocraticGovernance} from 'contracts/DemocraticGovernance.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {IVotes} from 'open-zeppelin/governance/utils/IVotes.sol';

interface IMockDemocraticGovernanceForTest {
  function forTest_setLatestRootPerVoter(address _account, uint256 _latestRoot) external;

  function forTest_isHuman(address _voter, uint256 _proposalId, bytes memory _proofData) external;

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

  function forTest_getVotes(
    address _account,
    uint256 _timepoint,
    bytes memory _params
  ) external view returns (uint256 _votingWeight);
}

contract MockDemocraticGovernance is DemocraticGovernance {
  constructor(
    uint256 _groupID,
    IWorldIDRouter _worldIdRouter,
    string memory _appId,
    string memory _actionId,
    IVotes _token
  ) DemocraticGovernance(_groupID, _worldIdRouter, _appId, _actionId, _token) {}

  function forTest_setLatestRootPerVoter(address _account, uint256 _latestRoot) public {
    latestRootPerVoter[_account] = _latestRoot;
  }

  function forTest_isHuman(address _voter, uint256 _proposalId, bytes memory _proofData) public {
    _isHuman(_voter, _proposalId, _proofData);
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

  function forTest_castVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    string memory _reason
  ) public returns (uint256) {
    return _castVote(_proposalId, _account, _support, _reason);
  }

  function forTest_getVotes(
    address _account,
    uint256 _timepoint,
    bytes memory _params
  ) public view returns (uint256 _votingWeight) {
    return _getVotes(_account, _timepoint, _params);
  }
}
