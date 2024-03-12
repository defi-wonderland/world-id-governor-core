// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IGovernor} from 'open-zeppelin/governance/IGovernor.sol';
import {IWorldID} from 'interfaces/IWorldID.sol';

interface IGovernorWorldID is IGovernor {
  /// @notice Thrown when attempting to call a non supported function
  error GovernorWorldID_NotSupportedFunction();

  /// @notice Thrown when the proof data is empty
  error GovernorWorldID_NoProofData();

  /// @notice Thrown when the provided root is not equal to the current root
  error GovernorWorldID_OutdatedRoot();

  /**
   * @notice The World ID instance that will be used for verifying proofs
   * @return _worldId The World ID instance
   */
  // solhint-disable-next-line func-name-mixedcase
  function WORLD_ID() external view returns (IWorldID _worldId);

  /**
   * @notice The contract's external nullifier hash
   * @return _externalNullifier The external nullifier hash
   */
  // solhint-disable-next-line func-name-mixedcase
  function EXTERNAL_NULLIFIER() external view returns (uint256 _externalNullifier);

  /**
   * @notice The latest root verifier for each voter
   * @param _voter The voter address
   * @return _root The latest root verifier
   */
  function latestRootPerVoter(address _voter) external view returns (uint256 _root);
}
