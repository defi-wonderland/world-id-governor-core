// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {InternalCallsWatcherExtension} from '../unit/utils/CalledInternal.sol';
import {GovernorWorldID} from 'contracts/GovernorWorldID.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {Governor} from 'open-zeppelin/governance/Governor.sol';
import {GovernorCountingSimple} from 'open-zeppelin/governance/extensions/GovernorCountingSimple.sol';
import {GovernorSettings} from 'open-zeppelin/governance/extensions/GovernorSettings.sol';

contract GovernorWorldIdForTest is InternalCallsWatcherExtension, GovernorCountingSimple, GovernorWorldID {
  struct ConstructorArgs {
    uint256 groupID;
    IWorldIDRouter worldIdRouter;
    string appId;
    uint48 initialVotingDelay;
    uint32 initialVotingPeriod;
    uint256 initialProposalThreshold;
    uint256 rootExpirationThreshold;
  }

  constructor(ConstructorArgs memory _args)
    Governor('GovernorWorldID')
    GovernorSettings(_args.initialVotingDelay, _args.initialVotingPeriod, _args.initialProposalThreshold)
    GovernorWorldID(_args.groupID, _args.worldIdRouter, _args.appId, _args.rootExpirationThreshold)
  {}

  function forTest_castVote(uint256 _proposalId, address _account, uint8 _support, string memory _reason) public {
    _castVote(_proposalId, _account, _support, _reason);
  }

  function forTest_castVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    string memory _reason,
    bytes memory _params
  ) public {
    _castVote(_proposalId, _account, _support, _reason, _params);
  }

  function forTest_setConfig(
    uint32 _newVotingPeriod,
    uint256 _newResetGracePeriod,
    uint256 _newRootExpirationThreshold
  ) public {
    _setConfig(_newVotingPeriod, _newResetGracePeriod, _newRootExpirationThreshold);
  }

  function forTest_checkVoteValidity(
    uint8 _support,
    uint256 _proposalId,
    bytes memory _proofData
  ) public returns (uint256 _nullifierHash) {
    _nullifierHash = _checkVoteValidity(_support, _proposalId, _proofData);
  }

  function forTest_setNullifierHash(uint256 _nullifierHash, bool _isUsed) public {
    nullifierHashes[_nullifierHash] = _isUsed;
  }

  function forTest_setRootExpirationThreshold(uint256 _newRootExpirationThreshold) public {
    rootExpirationThreshold = _newRootExpirationThreshold;
  }

  function forTest_propose(
    address[] memory _targets,
    uint256[] memory _values,
    bytes[] memory _calldatas,
    string memory _description,
    address _proposer
  ) public returns (uint256 _proposalId) {
    _proposalId = _propose(_targets, _values, _calldatas, _description, _proposer);
  }

  function clock() public view override returns (uint48) {
    return uint48(block.timestamp);
  }

  function forTest_checkConfigValidity(
    uint32 _votingPeriod,
    uint256 _resetGracePeriod,
    uint256 _rootExpirationThreshold
  ) public view {
    _checkConfigValidity(_votingPeriod, _resetGracePeriod, _rootExpirationThreshold);
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

  function quorum(uint256) public pure override returns (uint256 _randomQuorum) {
    _randomQuorum = 10;
  }

  // solhint-disable-next-line
  function CLOCK_MODE() public pure override returns (string memory) {
    return '';
  }

  function _checkVoteValidity(
    uint8 _support,
    uint256 _proposalId,
    bytes memory _proofData
  ) internal virtual override returns (uint256 _nullifierHash) {
    _calledInternal(
      abi.encodeWithSignature('_checkVoteValidity(uint8,uint256,bytes)', _support, _proposalId, _proofData)
    );
    if (_callSuper) _nullifierHash = super._checkVoteValidity(_support, _proposalId, _proofData);
  }

  function _setConfig(
    uint32 _newVotingPeriod,
    uint256 _newResetGracePeriod,
    uint256 _newRootExpirationThreshold
  ) internal virtual override {
    _calledInternal(
      abi.encodeWithSignature(
        '_setConfig(uint32,uint256,uint256)', _newVotingPeriod, _newResetGracePeriod, _newRootExpirationThreshold
      )
    );
    if (_callSuper) super._setConfig(_newVotingPeriod, _newResetGracePeriod, _newRootExpirationThreshold);
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

  function _checkConfigValidity(
    uint32 _votingPeriod,
    uint256 _resetGracePeriod,
    uint256 _rootExpirationThreshold
  ) internal view virtual override {
    _calledInternal(
      abi.encodeWithSignature(
        '_checkConfigValidity(uint32,uint256,uint256)', _votingPeriod, _resetGracePeriod, _rootExpirationThreshold
      )
    );
    if (_callSuper) super._checkConfigValidity(_votingPeriod, _resetGracePeriod, _rootExpirationThreshold);
  }

  function _getVotes(address, uint256, bytes memory) internal view virtual override returns (uint256) {
    return 1;
  }
}
