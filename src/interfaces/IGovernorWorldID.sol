// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IGovernor} from 'open-zeppelin/governance/IGovernor.sol';

interface IGovernorWorldID is IGovernor {
  /// @notice Thrown when attempting to call a non supported function
  error GovernorWorldID_NotSupportedFunction();

  /// @notice Thrown when attempting to use a nullifier hash that has been used before
  error GovernorWorldID_InvalidNullifier();

  /// @notice Thrown when the proof data is empty
  error GovernorWorldID_NoProofData();

  /// @notice Thrown when the provided root is not equal to the current root
  error GovernorWorldID_OutdatedRoot();
}
