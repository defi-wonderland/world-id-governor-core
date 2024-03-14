// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';

interface IDemocraticGovernance is IGovernorWorldID {
  function setQuorum(uint256 _quorumThreshold) external;

  function quorumThreshold() external view returns (uint256 _quorumThreshold);

  function proposalsQuorumThreshold(uint256 _proposalId) external view returns (uint256 _quorumThreshold);

  function clock() external view returns (uint48);

  // solhint-disable-next-line func-name-mixedcase
  function CLOCK_MODE() external view returns (string memory);
}
