// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';
import {IWorldIDIdentityManager} from 'interfaces/IWorldIDIdentityManager.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {ByteHasher} from 'libraries/ByteHasher.sol';
import {Governor} from 'open-zeppelin/governance/Governor.sol';
import {IGovernor} from 'open-zeppelin/governance/IGovernor.sol';
import {GovernorSettings} from 'open-zeppelin/governance/extensions/GovernorSettings.sol';

/**
 * @title GovernorWorldID
 * @notice Governor contract that checks if the voter is a real human before proceeding with the vote.
 */
abstract contract GovernorWorldID is Governor, GovernorSettings, IGovernorWorldID {
  using ByteHasher for bytes;

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
  uint256 public immutable APP_ID;

  /**
   * @inheritdoc IGovernorWorldID
   */
  uint256 public resetGracePeriod = 14 days;

  /**
   * @inheritdoc IGovernorWorldID
   */
  uint256 public rootExpirationThreshold;

  /**
   * @inheritdoc IGovernorWorldID
   */
  mapping(uint256 nullifierHash => bool isUsed) public nullifierHashes;

  /**
   * @param _groupID The WorldID group ID, 1 for orb verification level
   * @param _worldIdRouter The WorldID router instance to obtain the WorldID contract address
   * @param _appId The World ID app ID
   * @param _name The governor name
   * @param _initialVotingDelay The initial voting delay for the proposals
   * @param _initialVotingPeriod The initial voting period for the proposals
   * @param _initialProposalThreshold The initial proposal threshold
   * @param _rootExpirationThreshold The root expiration threshold
   */
  constructor(
    uint256 _groupID,
    IWorldIDRouter _worldIdRouter,
    bytes memory _appId,
    string memory _name,
    uint48 _initialVotingDelay,
    uint32 _initialVotingPeriod,
    uint256 _initialProposalThreshold,
    uint256 _rootExpirationThreshold
  ) Governor(_name) GovernorSettings(_initialVotingDelay, _initialVotingPeriod, _initialProposalThreshold) {
    WORLD_ID_ROUTER = _worldIdRouter;
    GROUP_ID = _groupID;
    APP_ID = abi.encodePacked(_appId).hashToField();

    _checkExpirationThresholdValidity(_rootExpirationThreshold);

    rootExpirationThreshold = _rootExpirationThreshold;
  }

  /**
   * @inheritdoc IGovernorWorldID
   */
  function setRootExpirationThreshold(uint256 _rootExpirationThreshold) external onlyGovernance {
    _checkExpirationThresholdValidity(_rootExpirationThreshold);

    uint256 _oldRootExpirationThreshold = rootExpirationThreshold;
    rootExpirationThreshold = _rootExpirationThreshold;

    emit RootExpirationThresholdUpdated(_rootExpirationThreshold, _oldRootExpirationThreshold);
  }

  /**
   * @inheritdoc IGovernorWorldID
   */
  function setResetGracePeriod(uint256 _resetGracePeriod) external onlyGovernance {
    uint256 _oldResetGracePeriod = resetGracePeriod;
    resetGracePeriod = _resetGracePeriod;

    emit ResetGracePeriodUpdated(_resetGracePeriod, _oldResetGracePeriod);
  }

  /**
   * @inheritdoc IGovernorWorldID
   */
  function checkVoteValidity(
    uint8 _support,
    uint256 _proposalId,
    bytes memory _proofData
  ) public override returns (uint256 _decodedNullifierHash) {
    // Decode the parameters
    (uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) =
      abi.decode(_proofData, (uint256, uint256, uint256[8]));

    if (nullifierHashes[_nullifierHash]) revert GovernorWorldID_NullifierHashAlreadyUsed();

    IWorldIDIdentityManager _identityManager = IWorldIDIdentityManager(WORLD_ID_ROUTER.routeFor(GROUP_ID));

    if (rootExpirationThreshold > 0) {
      // Query and validate root information
      uint128 _rootTimestamp = _identityManager.rootHistory(_root);
      if (block.timestamp - rootExpirationThreshold > _rootTimestamp) revert GovernorWorldID_OutdatedRoot();
    } else {
      _root = _identityManager.latestRoot();
    }

    // Verify the provided proof
    uint256 _signal = abi.encodePacked(_support).hashToField();
    uint256 _externalNullifier = abi.encodePacked(APP_ID, _proposalId).hashToField();
    WORLD_ID_ROUTER.verifyProof(_root, GROUP_ID, _signal, _nullifierHash, _externalNullifier, _proof);

    // Return the decoded nullifier hash
    _decodedNullifierHash = _nullifierHash;
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
   * @notice Adds extra checks to the OZ function to ensure the voting period is valid. After that, it calls the parent function
   * @param _votingPeriod The voting period
   */
  function _setVotingPeriod(uint32 _votingPeriod) internal virtual override {
    if (rootExpirationThreshold == 0 && _votingPeriod > resetGracePeriod - 2 hours) {
      revert GovernorWorldID_InvalidVotingPeriod();
    }

    if (rootExpirationThreshold > 0 && _votingPeriod > resetGracePeriod - rootExpirationThreshold) {
      revert GovernorWorldID_InvalidVotingPeriod();
    }

    super._setVotingPeriod(_votingPeriod);
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

    // Save the nullifier hash as used
    nullifierHashes[_nullifierHash] = true;

    return super._castVote(_proposalId, _account, _support, _reason, _params);
  }

  /**
   * @notice This function is disabled because is not compatible with the new implementations. It will make revert the functions that implement it as: `castVote`, `castVoteWithReason`, `castVoteBySig`.
   */
  function _castVote(uint256, address, uint8, string memory) internal virtual override returns (uint256) {
    revert GovernorWorldID_NotSupportedFunction();
  }

  /**
   * Check if the root expiration threshold is valid
   * @dev If zero, it will not check the root expiration threshold. If not zero, it will check if it is less than the reset grace period and the root history expiry
   * @param _rootExpirationThreshold The root expiration threshold
   */
  function _checkExpirationThresholdValidity(uint256 _rootExpirationThreshold) internal view {
    if (_rootExpirationThreshold == 0) return;

    IWorldIDIdentityManager _identityManager = IWorldIDIdentityManager(WORLD_ID_ROUTER.routeFor(GROUP_ID));
    if (_rootExpirationThreshold > resetGracePeriod || _rootExpirationThreshold > _identityManager.rootHistoryExpiry())
    {
      revert GovernorWorldID_InvalidRootExpirationThreshold();
    }
  }
}
