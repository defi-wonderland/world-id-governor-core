// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IDemocraticGovernance {
  /**
   * @notice Emitted when the quorum threshold is set
   * @param _oldQuorumThreshold The previous quorum threshold
   * @param _newQuorumThreshold The new quorum threshold
   */
  event QuorumSet(uint256 _oldQuorumThreshold, uint256 _newQuorumThreshold);

  /**
   * @notice Sets the quorum threshold for the democratic governance
   * @param _quorumThreshold The quorum threshold
   */
  function setQuorum(uint256 _quorumThreshold) external;

  /**
   * @notice Returns the quorum threshold for the democratic governance
   * @return _quorumThreshold The quorum threshold
   */
  function quorumThreshold() external view returns (uint256 _quorumThreshold);

  /**
   * @notice Returns the quorum threshold for the proposal
   * @param _proposalId The ID of the proposal
   * @return _quorumThreshold The quorum threshold for the proposal
   */
  function proposalsQuorumThreshold(uint256 _proposalId) external view returns (uint256 _quorumThreshold);
}
