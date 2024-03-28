// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {IGovernor} from 'open-zeppelin/governance/IGovernor.sol';

interface IGovernorWorldID is IGovernor {
  /**
   * @notice Emitted when the root expiration period is updated
   */
  event RootExpirationThresholdUpdated(uint256 _newRootExpirationThreshold, uint256 _oldRootExpirationThreshold);

  /**
   * @notice Emitted when the reset grace period is updated
   */
  event ResetGracePeriodUpdated(uint256 _newResetGracePeriod, uint256 _oldResetGracePeriod);

  /**
   * @notice Thrown when attempting to call a non supported function
   */
  error GovernorWorldID_NotSupportedFunction();

  /**
   * @notice Thrown when the provided root is too old
   */
  error GovernorWorldID_OutdatedRoot();

  /**
   * @notice Thrown when the provided root expiration threshold is bigger than the root history expiry from identity manager
   */
  error GovernorWorldID_InvalidRootExpirationThreshold();

  /**
   * @notice Thrown when the provided voting period is bigger than the reset grace period minus root expiration threshold
   */
  error GovernorWorldID_InvalidVotingPeriod();

  /**
   * @notice Thrown when the provided external nullifier hash is already used
   */
  error GovernorWorldID_NullifierHashAlreadyUsed();

  /**
   * @notice Sets a new expiration threshold
   * @param _newRootExpirationThreshold The new expiration threshold
   */
  function setRootExpirationThreshold(uint256 _newRootExpirationThreshold) external;

  /**
   * @notice Sets a new reset grace period
   * @param _newResetGracePeriod The new reset grace period
   */
  function setResetGracePeriod(uint256 _newResetGracePeriod) external;

  /**
   * @notice The World ID instance that will be used for verifying proofs
   * @return _worldId The World ID instance
   */
  // solhint-disable-next-line func-name-mixedcase
  function WORLD_ID_ROUTER() external view returns (IWorldIDRouter _worldId);

  /**
   * @notice The group ID used to verify the proofs
   * @return _groupId The group ID
   */
  // solhint-disable-next-line func-name-mixedcase
  function GROUP_ID() external view returns (uint256 _groupId);

  /**
   * @notice The app ID used to verify the proofs
   * @return _appId The app ID
   */
  // solhint-disable-next-line func-name-mixedcase
  function APP_ID() external view returns (uint256 _appId);

  /**
   * @notice The nullifier hashes used to prevent double voting
   * @param _nullifier The nullifier hash
   * @return _isUsed True if the nullifier hash is used
   */
  function nullifierHashes(uint256 _nullifier) external view returns (bool _isUsed);

  /**
   * @notice Checks the validity of a vote
   * @param _support The support for the proposal
   * @param _proposalId The proposal id
   * @param _proofData The proof data
   * @return _decodedNullifierHash The decoded nullifier hash
   */
  function checkVoteValidity(
    uint8 _support,
    uint256 _proposalId,
    bytes memory _proofData
  ) external view returns (uint256 _decodedNullifierHash);

  /**
   * @notice The current World ID reset grace period before inserting the user into the Merkle tree again. The current period is 14 days, and it has a setter function to be updated by the governance if needed.
   * @return _resetGracePeriod The grace period
   */
  function resetGracePeriod() external view returns (uint256 _resetGracePeriod);

  /**
   * @notice The expiration threshold used to define how old a root must be to be considered valid or invalid.
   * @return _rootExpirationThreshold The expiration threshold
   */
  function rootExpirationThreshold() external view returns (uint256 _rootExpirationThreshold);
}
