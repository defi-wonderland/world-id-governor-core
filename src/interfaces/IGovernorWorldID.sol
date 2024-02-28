// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IGovernorWorldID {
  /// @notice Thrown when attempting to call a non supported function
  error GovernorWorldID_NotSupportedFunction();

  /// @notice Thrown when attempting to use a nullifier hash that has been used before
  error GovernorWorldID_InvalidNullifier();
}
