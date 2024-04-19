// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';

interface IGovernorWorldID {
  /**
   * @notice Emitted when the root expiration period is updated
   * @param _oldRootExpirationThreshold The previous expiration threshold
   * @param _newRootExpirationThreshold The new expiration threshold
   */
  event RootExpirationThresholdSet(uint256 _oldRootExpirationThreshold, uint256 _newRootExpirationThreshold);

  /**
   * @notice Emitted when the reset grace period is updated
   * @param _oldResetGracePeriod The previous reset grace period
   * @param _newResetGracePeriod The new reset grace period
   */
  event ResetGracePeriodSet(uint256 _oldResetGracePeriod, uint256 _newResetGracePeriod);

  /**
   * @notice Thrown when attempting to call a non supported function
   */
  error GovernorWorldID_NotSupportedFunction();

  /**
   * @notice Thrown when the provided root is too old
   */
  error GovernorWorldID_OutdatedRoot();

  /**
   * @notice Thrown when the provided root expiration threshold
   *  is bigger than the root history expiry from identity manager
   */
  error GovernorWorldID_InvalidRootExpirationThreshold();

  /**
   * @notice Thrown when the provided reset grace period is minus than the current root expiration threshold
   */
  error GovernorWorldID_InvalidResetGracePeriod();

  /**
   * @notice Thrown when the provided voting period
   *  is bigger than the reset grace period minus root expiration threshold
   */
  error GovernorWorldID_InvalidVotingPeriod();

  /**
   * @notice Thrown when the provided nullifier hash was already used
   */
  error GovernorWorldID_DuplicateNullifier();

  /**
   * @notice Checks the validity of a vote
   * @param _support The support for the proposal
   * @param _proposalId The proposal id
   * @param _proofData The proof data containing the Merkle root, the nullifier hash and the zkProof
   * @return _nullifierHash The nullifier hash
   */
  function checkVoteValidity(
    uint8 _support,
    uint256 _proposalId,
    bytes memory _proofData
  ) external returns (uint256 _nullifierHash);

  /**
   * @notice Sets the configuration parameters for the contract
   * @param _newVotingPeriod The new voting period
   * @param _newResetGracePeriod The new reset grace period
   * @param _newRootExpirationThreshold The new root expiration threshold
   * @dev The purpose of this function is to ensure that `votingPeriod` is smaller than `resetGracePeriod`
   * minus `rootExpirationThreshold` to prevent double-voting attacks from resetted WorldID users
   */
  function setConfig(
    uint32 _newVotingPeriod,
    uint256 _newResetGracePeriod,
    uint256 _newRootExpirationThreshold
  ) external;

  /**
   * @notice The World ID instance that will be used for verifying proofs
   * @return _worldId The World ID Router instance
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
   * @notice The hash of the developer portal app ID used to verify the proofs
   * @return _appIdHash The hash of the app ID
   * @dev Already hashed to be used as part of the external nullifier hash on the on-chain proof verification
   */
  // solhint-disable-next-line func-name-mixedcase
  function APP_ID_HASH() external view returns (uint256 _appIdHash);

  /**
   * @notice The developer portal app ID used to verify the proofs
   * @return _appId The app ID
   * @dev This will be needed for the off-chain to generate valid proofs using the correct app ID
   * @dev Can't be defined as immutable because its type is string, but is never updated
   */
  // solhint-disable-next-line func-name-mixedcase
  function appId() external view returns (string memory _appId);

  /**
   * @notice The nullifier hashes used to prevent double voting
   * @param _nullifierHash The nullifier hash
   * @return _isUsed True if the nullifier hash is already used
   */
  function nullifierHashes(uint256 _nullifierHash) external view returns (bool _isUsed);

  /**
   * @notice The current World ID reset grace period before inserting the user into the Merkle tree again.
   *  The current period is 14 days, and it has a setter function to be updated by the governance if it changes.
   * @dev Initialized to 13 days and 22 hours as an extra safety measure
   * @return _resetGracePeriod The grace period
   */
  function resetGracePeriod() external view returns (uint256 _resetGracePeriod);

  /**
   * @notice The expiration threshold used to define how old a root must be to be considered valid or invalid.
   * @dev If set to 0, the proof can only be verified using the latest root.
   * @dev If deploying this contract on mainnet or mainnet testnets, the value must be 0.
   * @return _rootExpirationThreshold The expiration threshold
   */
  function rootExpirationThreshold() external view returns (uint256 _rootExpirationThreshold);
}
