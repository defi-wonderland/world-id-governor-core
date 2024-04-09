// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';

interface IDemocraticGovernance is IGovernorWorldID {
  /**
   * @notice Emitted when the quorum threshold is set
   * @param _oldQuorumThreshold The quorum threshold
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

  /**
   * @notice Clock used for flagging checkpoints
   * @return _clock The block number
   * @dev Follows the Open Zeppelin implementation when the token does not implement EIP-6372,
   *  but using timestamp instead
   */
  function clock() external view returns (uint48 _clock);

  /**
   * @notice Description of the clock mode
   * @return _mode The description of the clock mode
   * @dev Follows the Open Zeppelin implementation when the token does not implement EIP-6372,
   *  but using timestamp instead
   */
  // solhint-disable-next-line func-name-mixedcase
  function CLOCK_MODE() external view returns (string memory _mode);
}
