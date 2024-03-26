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
   * @notice The World ID instance that will be used for verifying proofs
   * @return _worldId The World ID instance
   */
  // solhint-disable-next-line func-name-mixedcase
  function WORLD_ID() external view returns (IWorldIDRouter _worldId);

  function GROUP_ID() external view returns (uint256 _groupId);

  function APP_ID() external view returns (uint256 _appId);

  function nullifierHashes(uint256 _nullifier) external view returns (bool _isUsed);

  function setRootExpirationThreshold(uint256 _newRootExpirationThreshold) external;

  function setResetGracePeriod(uint256 _newResetGracePeriod) external;

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
