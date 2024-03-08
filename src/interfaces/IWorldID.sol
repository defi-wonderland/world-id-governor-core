// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IWorldID {
  /// @notice Reverts if the zero-knowledge proof is invalid.
  /// @param _root The root of the Merkle tree
  /// @param _signalHash A keccak256 hash of the Semaphore signal
  /// @param _nullifierHash The nullifier hash
  /// @param _externalNullifierHash A keccak256 hash of the external nullifier
  /// @param _proof The zero-knowledge proof
  /// @dev  Note that a double-signaling check is not included here, and should be carried by the caller.
  function verifyProof(
    uint256 _root,
    uint256 _signalHash,
    uint256 _nullifierHash,
    uint256 _externalNullifierHash,
    uint256[8] calldata _proof
  ) external view;

  function latestRoot() external view returns (uint256 _latestRoot);
}
