// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IWorldIDRouter {
  function routeFor(uint256 _groupId) external view returns (address _contractAddress);
}
