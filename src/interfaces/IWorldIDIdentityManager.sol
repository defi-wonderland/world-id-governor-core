// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IWorldIDIdentityManager {
  /**
   * @notice Provides information about a merkle tree root.
   * @param root The value of the merkle tree root.
   * @param supersededTimestamp The timestamp at which the root was inserted into the history.
   *        This may be 0 if the requested root is the current root (which has not yet been
   *        inserted into the history).
   * @param isValid Whether or not the root is valid (has not expired).
   */
  struct RootInfo {
    uint256 root;
    uint128 supersededTimestamp;
    bool isValid;
  }

  /**
   * @notice Reverts if the zero-knowledge proof is invalid.
   * @param _root The root of the Merkle tree
   * @param _signalHash A keccak256 hash of the Semaphore signal
   * @param _nullifierHash The nullifier hash
   * @param _externalNullifierHash A keccak256 hash of the external nullifier
   * @param _proof The zero-knowledge proof
   * @dev  Note that a double-signaling check is not included here, and should be carried by the caller.
   */
  function verifyProof(
    uint256 _root,
    uint256 _signalHash,
    uint256 _nullifierHash,
    uint256 _externalNullifierHash,
    uint256[8] calldata _proof
  ) external view;

  /**
   * @notice Returns the latest root of the merkle tree
   * @return _latestRoot The latest root
   */
  function latestRoot() external view returns (uint256 _latestRoot);

  function queryRoot(uint256 _root) external view returns (RootInfo memory _rootInfo);

  function getRootHistoryExpiry() external view returns (uint256 _rootHistoryExpiry);
}
