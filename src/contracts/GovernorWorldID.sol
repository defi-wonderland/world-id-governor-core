// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';
import {IWorldIDIdentityManager} from 'interfaces/IWorldIDIdentityManager.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {ByteHasher} from 'libraries/ByteHasher.sol';
import {Governor} from 'open-zeppelin/governance/Governor.sol';
import {IGovernor} from 'open-zeppelin/governance/IGovernor.sol';
import {GovernorSettings} from 'open-zeppelin/governance/extensions/GovernorSettings.sol';
import {Strings} from 'open-zeppelin/utils/Strings.sol';

/**
 * @title GovernorWorldID
 * @notice Governor contract that checks if the voter is a real human before proceeding with the vote.
 */
abstract contract GovernorWorldID is Governor, GovernorSettings, IGovernorWorldID {
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
   * @param _governorName The governor name
   * @param _initialVotingDelay The initial voting delay for the proposals
   * @param _initialVotingPeriod The initial voting period for the proposals
   * @param _initialProposalThreshold The initial proposal threshold
   * @param _rootExpirationThreshold The root expiration threshold
   */
  constructor(
    uint256 _groupID,
    IWorldIDRouter _worldIdRouter,
    string memory _appId,
    string memory _governorName,
    uint48 _initialVotingDelay,
    uint32 _initialVotingPeriod,
    uint256 _initialProposalThreshold,
    uint256 _rootExpirationThreshold
  ) Governor(_governorName) GovernorSettings(_initialVotingDelay, _initialVotingPeriod, _initialProposalThreshold) {
    WORLD_ID_ROUTER = _worldIdRouter;
    GROUP_ID = _groupID;
    APP_ID_HASH = abi.encodePacked(_appId).hashToField();
    _setConfig(_initialVotingPeriod, resetGracePeriod, _rootExpirationThreshold);
  }

  /**
   * @inheritdoc IGovernorWorldID
   */
  function checkVoteValidity(
    uint8 _support,
    uint256 _proposalId,
    bytes memory _proofData
  ) public override returns (uint256 _nullifierHash) {
    (uint256 _root, uint256 _decodedNullifierHash, uint256[8] memory _proof) =
      abi.decode(_proofData, (uint256, uint256, uint256[8]));
    if (nullifierHashes[_decodedNullifierHash]) revert GovernorWorldID_NullifierHashAlreadyUsed();

    // Validate the root timestamp
    IWorldIDIdentityManager _identityManager = IWorldIDIdentityManager(WORLD_ID_ROUTER.routeFor(GROUP_ID));
    if (rootExpirationThreshold == 0) {
      if (_root != _identityManager.latestRoot()) revert GovernorWorldID_OutdatedRoot();
    } else {
      uint128 _rootTimestamp = _identityManager.rootHistory(_root);
      if (block.timestamp - rootExpirationThreshold > _rootTimestamp) revert GovernorWorldID_OutdatedRoot();
    }

    // Verify the proof
    uint256 _signalHash = abi.encodePacked(uint256(_support).toString()).hashToField();
    uint256 _externalNullifierHash = abi.encodePacked(APP_ID_HASH, _proposalId.toString()).hashToField();
    WORLD_ID_ROUTER.verifyProof(_root, GROUP_ID, _signalHash, _decodedNullifierHash, _externalNullifierHash, _proof);
    _nullifierHash = _decodedNullifierHash;
  }

  /**
   * @inheritdoc IGovernorWorldID
   */
  function setConfig(
    uint32 _newVotingPeriod,
    uint256 _newResetGracePeriod,
    uint256 _newRootExpirationThreshold
  ) public virtual onlyGovernance {
    _setConfig(_newVotingPeriod, _newResetGracePeriod, _newRootExpirationThreshold);
  }

  /**
   * @notice Disabled because the `votingPeriod` must be updated using the `setConfig` function along with the other
   * settings, to check the validity of the new configuration.
   */
  function setVotingPeriod(uint32) public virtual override {
    revert GovernorWorldID_NotSupportedFunction();
  }

  /**
   * @inheritdoc IGovernor
   */
  function votingDelay() public view virtual override(Governor, GovernorSettings, IGovernor) returns (uint256) {
    return super.votingDelay();
  }

  /**
   * @inheritdoc IGovernor
   */
  function votingPeriod() public view virtual override(Governor, GovernorSettings, IGovernor) returns (uint256) {
    return super.votingPeriod();
  }

  /**
   * @inheritdoc IGovernor
   */
  function proposalThreshold() public view virtual override(Governor, GovernorSettings, IGovernor) returns (uint256) {
    return super.proposalThreshold();
  }

  /**
   * @notice Sets the configuration parameters for the contract
   * @param _newVotingPeriod The new voting period
   * @param _newResetGracePeriod The new reset grace period
   * @param _newRootExpirationThreshold The new root expiration threshold
   * @dev The purpose of this function is to ensure that `votingPeriod` is smaller than `resetGracePeriod`
   * less `rootExpirationThreshold` to prevent double-voting attacks from resetted WorldID users
   */
  function _setConfig(
    uint32 _newVotingPeriod,
    uint256 _newResetGracePeriod,
    uint256 _newRootExpirationThreshold
  ) internal virtual {
    // Check that `_rootExpirationThreshold` is valid. If set to 0, no need to check the `rootHistoryExpiry`
    if (_newRootExpirationThreshold != 0) {
      if (_newRootExpirationThreshold > _newResetGracePeriod) revert GovernorWorldID_InvalidRootExpirationThreshold();
      IWorldIDIdentityManager _identityManager = WORLD_ID_ROUTER.routeFor(GROUP_ID);
      if (_newRootExpirationThreshold > _identityManager.rootHistoryExpiry()) {
        revert GovernorWorldID_InvalidRootExpirationThreshold();
      }
    }
    // Voting period should be smaller than reset grace period less root expiration threshold to prevent double-voting
    if (_newVotingPeriod > _newResetGracePeriod - _newRootExpirationThreshold) {
      revert GovernorWorldID_InvalidVotingPeriod();
    }

    if (_newVotingPeriod != votingPeriod()) super._setVotingPeriod(uint32(_newVotingPeriod));
    uint256 _currentResetGracePeriod = resetGracePeriod;
    if (_newResetGracePeriod != _currentResetGracePeriod) {
      resetGracePeriod = _newResetGracePeriod;
      emit ResetGracePeriodUpdated(_currentResetGracePeriod, _newResetGracePeriod);
    }
    uint256 _currentRootExpirationThreshold = rootExpirationThreshold;
    if (_newRootExpirationThreshold != _currentRootExpirationThreshold) {
      rootExpirationThreshold = _newRootExpirationThreshold;
      emit RootExpirationThresholdUpdated(_currentRootExpirationThreshold, _newRootExpirationThreshold);
    }
  }

  /**
   * @notice Cast a vote for a proposal
   * @dev It checks if the voter is a real human before proceeding with the vote
   * @param _proposalId The proposal id
   * @param _account The account that is casting the vote
   * @param _support The support value, 0 for against and 1 for in favor
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
    uint256 _nullifierHash = checkVoteValidity(_support, _proposalId, _params);
    nullifierHashes[_nullifierHash] = true;
    return super._castVote(_proposalId, _account, _support, _reason, _params);
  }

  /**
   * @notice Disabled because is not compatible with the new implementations.
   *  It will make revert the functions that implement it as: `castVote`, `castVoteWithReason`, `castVoteBySig`.
   */
  function _castVote(uint256, address, uint8, string memory) internal virtual override returns (uint256) {
    revert GovernorWorldID_NotSupportedFunction();
  }
}
