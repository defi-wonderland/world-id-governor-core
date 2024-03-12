// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IWorldIDRouter {
  /**
   * @notice Returns the contract address for a given group ID
   * @param _groupId The group ID
   * @return _contractAddress The contract address
   */
  function routeFor(uint256 _groupId) external view returns (address _contractAddress);
}
