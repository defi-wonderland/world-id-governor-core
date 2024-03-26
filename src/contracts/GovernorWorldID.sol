// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IGovernor} from 'open-zeppelin/governance/IGovernor.sol';
import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';
import {IWorldID} from 'interfaces/IWorldID.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {ByteHasher} from 'libraries/ByteHasher.sol';
import {GovernorSettings} from 'open-zeppelin/governance/extensions/GovernorSettings.sol';
import {Governor} from 'open-zeppelin/governance/Governor.sol';

/**
 * @title GovernorWorldID
 * @notice Governor contract that checks if the voter is a real human before proceeding with the vote.
 */
abstract contract GovernorWorldID is Governor, GovernorSettings, IGovernorWorldID {
  using ByteHasher for bytes;

  /**
   * @inheritdoc IGovernorWorldID
   */
  IWorldIDRouter public immutable WORLD_ID;

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
  uint256 public resetGracePeriod;

  /**
   * @inheritdoc IGovernorWorldID
   */
  uint256 public rootExpirationThreshold;

  /**
   * @inheritdoc IGovernorWorldID
   */
  mapping(uint256 nullifier => bool isUsed) public nullifierHashes;

  /**
   * @param _groupID The WorldID group ID, 1 for orb verification level
   * @param _worldIdRouter The WorldID router instance to obtain the WorldID contract address
   * @param _appId The World ID app ID
   * @param _name The governor name
   */
  constructor(
    uint256 _groupID,
    IWorldIDRouter _worldIdRouter,
    bytes memory _appId,
    string memory _name,
    uint48 _initialVotingDelay,
    uint32 _initialVotingPeriod,
    uint256 _initialProposalThreshold
  ) Governor(_name) GovernorSettings(_initialVotingDelay, _initialVotingPeriod, _initialProposalThreshold) {
    WORLD_ID = _worldIdRouter;
    GROUP_ID = _groupID;
    APP_ID = abi.encodePacked(_appId).hashToField();

    resetGracePeriod = 14 days;

    IWorldID _identityManager = IWorldID(WORLD_ID.routeFor(_groupID));
    rootExpirationThreshold = _identityManager.getRootHistoryExpiry();
  }

  /**
   * @inheritdoc IGovernorWorldID
   */
  function setRootExpirationThreshold(uint256 _rootExpirationThreshold) external onlyGovernance {
    IWorldID _identityManager = IWorldID(WORLD_ID.routeFor(GROUP_ID));
    if (_identityManager.getRootHistoryExpiry() < _rootExpirationThreshold) {
      revert GovernorWorldID_InvalidRootExpirationThreshold();
    }

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
   * @inheritdoc GovernorSettings
   */
  function _setVotingPeriod(uint32 _votingPeriod) internal virtual override {
    // TODO: if rootExpirationThreshold > resetGracePeriod will fail with arithmetic error, how to proceed there?
    if (_votingPeriod > resetGracePeriod - rootExpirationThreshold) revert GovernorWorldID_InvalidVotingPeriod();

    super._setVotingPeriod(_votingPeriod);
  }

  /**
   * @notice Check if the voter is a real human and the vote is valid
   * @param _support The support for the proposal
   * @param _proposalId The proposal id
   * @param _proofData The proof data
   */
  function _validateUniqueVote(uint8 _support, uint256 _proposalId, bytes memory _proofData) internal virtual {
    // Decode the parameters
    (uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) =
      abi.decode(_proofData, (uint256, uint256, uint256[8]));

    if (nullifierHashes[_nullifierHash]) revert GovernorWorldID_NullifierHashAlreadyUsed();

    IWorldID _identityManager = IWorldID(WORLD_ID.routeFor((GROUP_ID)));

    // Query and validate root information
    IWorldID.RootInfo memory _rootInfo = _identityManager.queryRoot(_root);
    if (block.timestamp - rootExpirationThreshold > _rootInfo.supersededTimestamp) {
      revert GovernorWorldID_OutdatedRoot();
    }

    // Verify the provided proof
    uint256 _signal = uint256(_support);
    uint256 _externalNullifier = abi.encodePacked(APP_ID, _proposalId).hashToField();
    _identityManager.verifyProof(_root, _signal, _nullifierHash, _externalNullifier, _proof);

    // Save the nullifier hash as used
    nullifierHashes[_nullifierHash] = true;
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
    _validateUniqueVote(_support, _proposalId, _params);

    return super._castVote(_proposalId, _account, _support, _reason, _params);
  }

  /**
   * @notice This function is disabled because is not compatible with the new implementations. It will make revert the functions that implement it as: `castVote`, `castVoteWithReason`, `castVoteBySig`.
   */
  function _castVote(uint256, address, uint8, string memory) internal virtual override returns (uint256) {
    revert GovernorWorldID_NotSupportedFunction();
  }

  function votingDelay() public view virtual override(Governor, GovernorSettings, IGovernor) returns (uint256) {
    return super.votingDelay();
  }

  function votingPeriod() public view virtual override(Governor, GovernorSettings, IGovernor) returns (uint256) {
    return super.votingPeriod();
  }

  function proposalThreshold() public view virtual override(Governor, GovernorSettings, IGovernor) returns (uint256) {
    return super.proposalThreshold();
  }
}
