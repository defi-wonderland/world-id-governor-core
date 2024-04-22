// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';
import {IWorldIDIdentityManager} from 'interfaces/IWorldIDIdentityManager.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {ByteHasher} from 'libraries/ByteHasher.sol';
import {GovernorSettings} from 'open-zeppelin/governance/extensions/GovernorSettings.sol';
import {Strings} from 'open-zeppelin/utils/Strings.sol';

/**
 * @title GovernorWorldID
 * @notice Governor contract that checks if the voter is a real human before proceeding with the vote.
 */
abstract contract GovernorWorldID is GovernorSettings, IGovernorWorldID {
  using ByteHasher for bytes;
  using Strings for uint256;

  /**
   * @inheritdoc IGovernorWorldID
   */
  IWorldIDRouter public immutable WORLD_ID_ROUTER;

  /**
   * @inheritdoc IGovernorWorldID
   */
  uint256 public immutable GROUP_ID;

  /**
   * @inheritdoc IGovernorWorldID
   */
  uint256 public immutable APP_ID_HASH;

  /**
   * @inheritdoc IGovernorWorldID
   */
  string public appId;

  /**
   * @inheritdoc IGovernorWorldID
   */
  uint256 public resetGracePeriod = 13 days + 22 hours;

  /**
   * @inheritdoc IGovernorWorldID
   */
  uint256 public rootExpirationThreshold;

  /**
   * @inheritdoc IGovernorWorldID
   */
  mapping(uint256 _nullifierHash => bool _isUsed) public nullifierHashes;

  /**
   * @param _groupID The WorldID group ID for the verification level
   * @param _worldIdRouter The WorldID router instance to obtain the WorldID contract address
   * @param _appId The World ID app ID
   * @param _rootExpirationThreshold The root expiration threshold
   * @dev The `votingPeriod` will be the value passed on the `GovernorSettings` constructor. Beware that it is
   * compatible with the `resetGracePeriod` and `rootExpirationThreshold` values to prevent double-voting risks
   */
  constructor(uint256 _groupID, IWorldIDRouter _worldIdRouter, string memory _appId, uint256 _rootExpirationThreshold) {
    WORLD_ID_ROUTER = _worldIdRouter;
    GROUP_ID = _groupID;
    appId = _appId;
    APP_ID_HASH = abi.encodePacked(_appId).hashToField();
    _setConfig(uint32(votingPeriod()), resetGracePeriod, _rootExpirationThreshold);
  }

  /**
   * @inheritdoc IGovernorWorldID
   */
  function checkVoteValidity(
    uint8 _support,
    uint256 _proposalId,
    bytes memory _proofData
  ) external returns (uint256 _nullifierHash) {
    _nullifierHash = _checkVoteValidity(_support, _proposalId, _proofData);
  }

  /**
   * @inheritdoc IGovernorWorldID
   */
  function setConfig(
    uint32 _newVotingPeriod,
    uint256 _newResetGracePeriod,
    uint256 _newRootExpirationThreshold
  ) external virtual onlyGovernance {
    _setConfig(_newVotingPeriod, _newResetGracePeriod, _newRootExpirationThreshold);
  }

  /**
   * @inheritdoc IGovernorWorldID
   */
  function checkConfigValidity(
    uint32 _votingPeriod,
    uint256 _resetGracePeriod,
    uint256 _rootExpirationThreshold
  ) external view virtual {
    _checkConfigValidity(_votingPeriod, _resetGracePeriod, _rootExpirationThreshold);
  }

  /**
   * @notice Updates the voting period
   * @param _newVotingPeriod The new voting period
   * @dev The combination between the `_newVotingPeriod` and the current `resetGracePeriod`
   * and `rootExpirationThreshold` is valid
   */
  function setVotingPeriod(uint32 _newVotingPeriod) public virtual override {
    _checkConfigValidity(_newVotingPeriod, resetGracePeriod, rootExpirationThreshold);
    super.setVotingPeriod(_newVotingPeriod);
  }

  /**
   * @notice Checks the validity of a vote
   * @param _support The support for the proposal
   * @param _proposalId The proposal id
   * @param _proofData The proof data containing the Merkle root, the nullifier hash and the zkProof
   * @return _nullifierHash The nullifier hash
   */
  function _checkVoteValidity(
    uint8 _support,
    uint256 _proposalId,
    bytes memory _proofData
  ) internal virtual returns (uint256 _nullifierHash) {
    (uint256 _root, uint256 _decodedNullifierHash, uint256[8] memory _proof) =
      abi.decode(_proofData, (uint256, uint256, uint256[8]));
    if (nullifierHashes[_decodedNullifierHash]) revert GovernorWorldID_DuplicateNullifier();

    // Validate the root timestamp
    IWorldIDIdentityManager _identityManager = IWorldIDIdentityManager(WORLD_ID_ROUTER.routeFor(GROUP_ID));
    if (rootExpirationThreshold == 0) {
      if (_root != _identityManager.latestRoot()) revert GovernorWorldID_OutdatedRoot();
    } else {
      // The root expiration threshold can't be greater than `rootHistoryExpiry` in case it is updated. Suboptimal check
      // since if it is smaller, it will revert on the calculation. But the revert message vebosity is prioritized
      uint256 _rootHistoryExpiry = _identityManager.rootHistoryExpiry();
      uint256 _rootExpirationThreshold =
        rootExpirationThreshold < _rootHistoryExpiry ? rootExpirationThreshold : _rootHistoryExpiry;
      uint128 _rootTimestamp = _identityManager.rootHistory(_root);
      if (block.timestamp - _rootExpirationThreshold > _rootTimestamp) revert GovernorWorldID_OutdatedRoot();
    }

    // Verify the proof
    uint256 _signalHash = abi.encodePacked(uint256(_support).toString()).hashToField();
    uint256 _externalNullifierHash = abi.encodePacked(APP_ID_HASH, _proposalId.toString()).hashToField();
    WORLD_ID_ROUTER.verifyProof(_root, GROUP_ID, _signalHash, _decodedNullifierHash, _externalNullifierHash, _proof);
    _nullifierHash = _decodedNullifierHash;
  }

  /**
   * @notice Sets the configuration parameters for the contract
   * @param _newVotingPeriod The new voting period
   * @param _newResetGracePeriod The new reset grace period
   * @param _newRootExpirationThreshold The new root expiration threshold
   */
  function _setConfig(
    uint32 _newVotingPeriod,
    uint256 _newResetGracePeriod,
    uint256 _newRootExpirationThreshold
  ) internal virtual {
    if (_newRootExpirationThreshold > _newResetGracePeriod) revert GovernorWorldID_InvalidRootExpirationThreshold();
    _checkConfigValidity(_newVotingPeriod, _newResetGracePeriod, _newRootExpirationThreshold);

    if (_newVotingPeriod != votingPeriod()) super._setVotingPeriod(_newVotingPeriod);
    uint256 _currentResetGracePeriod = resetGracePeriod;
    if (_newResetGracePeriod != _currentResetGracePeriod) {
      resetGracePeriod = _newResetGracePeriod;
      emit ResetGracePeriodSet(_currentResetGracePeriod, _newResetGracePeriod);
    }
    uint256 _currentRootExpirationThreshold = rootExpirationThreshold;
    if (_newRootExpirationThreshold != _currentRootExpirationThreshold) {
      rootExpirationThreshold = _newRootExpirationThreshold;
      emit RootExpirationThresholdSet(_currentRootExpirationThreshold, _newRootExpirationThreshold);
    }
  }

  /**
   * @notice Cast a vote for a proposal
   * @dev It checks if the voter is a real human before proceeding with the vote
   * @param _proposalId The proposal id
   * @param _account The account that is casting the vote
   * @param _support The support value, 0 for against, 1 for in favor and 2 for abstain
   * @param _reason The reason for the vote
   * @param _params The parameters for the vote
   * @return _votingWeight The voting weight of the voter
   */
  function _castVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    string memory _reason,
    bytes memory _params
  ) internal virtual override returns (uint256 _votingWeight) {
    uint256 _nullifierHash = _checkVoteValidity(_support, _proposalId, _params);
    nullifierHashes[_nullifierHash] = true;
    _votingWeight = super._castVote(_proposalId, _account, _support, _reason, _params);
  }

  /**
   * @notice Disabled because is not compatible with the new implementations.
   *  It will make revert the functions that implement it as: `castVote`, `castVoteWithReason`, `castVoteBySig`.
   */
  function _castVote(uint256, address, uint8, string memory) internal virtual override returns (uint256) {
    revert GovernorWorldID_NotSupportedFunction();
  }

  /**
   * @notice Checks if the configuration parameters are valid
   * @param _votingPeriod The voting period to check
   * @param _resetGracePeriod The reset grace period to check
   * @param _rootExpirationThreshold The root expiration threshold to check
   * @dev The `_rootExpirationThreshold` can't be greater than IdentityManager's `rootHistoryExpiry`
   * @dev This function aims to ensure that `_votingPeriod` is smaller than `_resetGracePeriod`
   * minues `_rootExpirationThreshold` to prevent double-voting attacks from resetted WorldID users
   */
  function _checkConfigValidity(
    uint32 _votingPeriod,
    uint256 _resetGracePeriod,
    uint256 _rootExpirationThreshold
  ) internal view virtual {
    // Check that `_rootExpirationThreshold` is valid. If set to 0, no need to check the `rootHistoryExpiry`
    if (_rootExpirationThreshold != 0) {
      // Suboptimal check since if smaller, it will revert on the calculation. But the revert message is more clear
      IWorldIDIdentityManager _identityManager = WORLD_ID_ROUTER.routeFor(GROUP_ID);
      if (_rootExpirationThreshold > _identityManager.rootHistoryExpiry()) {
        revert GovernorWorldID_InvalidRootExpirationThreshold();
      }
    }
    // Voting period should be smaller than reset grace period minus root expiration threshold to prevent double-voting
    if (_votingPeriod >= _resetGracePeriod - _rootExpirationThreshold) {
      revert GovernorWorldID_InvalidVotingPeriod();
    }
  }
}
