// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {E2EBase} from './E2EBase.sol';
import {IERC20} from 'open-zeppelin/token/ERC20/IERC20.sol';

contract E2E_GoatsDAO is E2EBase {
  /**
   * @notice Test a successful flow on the GoatsDAO contract
   */
  function test_flowSuccessful() public {
    // Create a proposal that matches the proposal id used as action id when generating the proof
    vm.prank(owner);
    uint256 _proposalId = governance.propose(targets, values, calldatas, description);
    assert(_proposalId == PROPOSAL_ID);

    // Advance the time to make the proposal active
    vm.warp(block.timestamp + INITIAL_VOTING_DELAY + 1);

    // Call setConfig and check that does not apply to the live proposal

    // The two users vote `for`

    // After the voting period has ended, the proposal is executed

    // Check that the Goat Guy has received the WLD tokens
  }

  /**
   * @notice Test when the quorum is not reached
   */
  function test_flowFailureByQuorumNotReached() public {
    // Create a proposal that matches the proposal id used as action id when generating the proof
    vm.prank(owner);
    uint256 _proposalId = governance.propose(targets, values, calldatas, description);
    assert(_proposalId == PROPOSAL_ID);

    // Advance the time to make the proposal active
    vm.warp(block.timestamp + INITIAL_VOTING_DELAY + 1);

    // Only one user votes `for`

    // After the voting period has ended, the proposal is executed but fails
  }

  /**
   * @notice Test when the voting period has not ended yet
   */
  function test_flowFailureByVotingPeriodNotEnded() public {
    // Create a proposal that matches the proposal id used as action id when generating the proof
    vm.prank(owner);
    uint256 _proposalId = governance.propose(targets, values, calldatas, description);
    assert(_proposalId == PROPOSAL_ID);

    // Advance the time to make the proposal active
    vm.warp(block.timestamp + INITIAL_VOTING_DELAY + 1);

    // The two users vote `for`

    // The voting period has not ended, the proposal is executed but fails
  }
}
