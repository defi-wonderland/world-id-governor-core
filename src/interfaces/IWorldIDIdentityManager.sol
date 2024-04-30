// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IWorldIDIdentityManager {
  /**
   * @notice Returns the latest root of the merkle tree
   * @return _latestRoot The latest root
   */
  function latestRoot() external view returns (uint256 _latestRoot);

  /**
   * @notice Returns the timestamp of the desired root
   * @param _root The Merkle tree root
   * @return _timestamp The timestamp of the root
   */
  function rootHistory(uint256 _root) external view returns (uint128 _timestamp);

  /**
   * @notice Returns the expiry time of the root history
   * @return _rootHistoryExpiry The expiry time of the root history
   */
  function rootHistoryExpiry() external view returns (uint256 _rootHistoryExpiry);
}
