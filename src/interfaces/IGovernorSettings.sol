// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IGovernorSettings {
  /**
   * @notice Sets the voting period for the governance
   * @param _newVotingPeriod The new voting period
   */
  function setVotingPeriod(uint32 _newVotingPeriod) external;
}
