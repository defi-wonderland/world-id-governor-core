// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {GoatsDAO} from 'contracts/example/GoatsDAO.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';

contract GoatsDAOForTest is GoatsDAO {
  constructor(
    uint256 _groupID,
    IWorldIDRouter _worldIdRouter,
    string memory _appId,
    uint256 _quorum,
    uint48 _initialVotingDelay,
    uint32 _initialVotingPeriod,
    uint256 _initialProposalThreshold,
    uint256 _rootExpirationThreshold
  )
    GoatsDAO(
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

  function forTest_setNullifierHash(uint256 _nullifierHash, bool _isUsed) public {
    nullifierHashes[_nullifierHash] = _isUsed;
  }

  function forTest_setRootExpirationThreshold(uint256 _newRootExpirationThreshold) public {
    rootExpirationThreshold = _newRootExpirationThreshold;
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

  function _propose(
    address[] memory _targets,
    uint256[] memory _values,
    bytes[] memory _calldatas,
    string memory _description,
    address _proposer
  ) internal virtual override returns (uint256 _proposalId) {
    _proposalId = super._propose(_targets, _values, _calldatas, _description, _proposer);
  }
}
