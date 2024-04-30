// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IGovernorDemocratic {
  /**
   * @notice The constant holding the votes for every voter (1 since it's a democratic system)
   * @return _oneVote One as voting power
   */
  // solhint-disable-next-line func-name-mixedcase
  function ONE_VOTE() external view returns (uint256 _oneVote);
}
