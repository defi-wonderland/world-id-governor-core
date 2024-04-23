// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {E2EBase} from './E2EBase.sol';
import {IGovernor} from 'open-zeppelin/governance/IGovernor.sol';
import {IERC20} from 'open-zeppelin/token/ERC20/IERC20.sol';
import {Strings} from 'open-zeppelin/utils/Strings.sol';

contract E2E_GoatsDAO is E2EBase {
  using Strings for *;

  /**
   * @notice Test a successful flow on the GoatsDAO contract
   */
  function test_flowSuccessful() public {
    uint256 _startVoteTimestamp = block.timestamp;
    // Create a proposal that matches the proposal id used as action id when generating the proof
    vm.prank(owner);
    uint256 _proposalId = governance.propose(targets, values, calldatas, description);
    assert(_proposalId == PROPOSAL_ID);

    // Advance the time to make the proposal active
    vm.warp(block.timestamp + INITIAL_VOTING_DELAY + 1);

    // Call setConfig and check that does not apply to the live proposal
    uint32 _newVotingPeriod = INITIAL_VOTING_PERIOD + 1;
    uint256 _newResetGracePeriod = 15 days;
    uint256 _newRootExpirationThreshold = rootExpirationThreshold + 2 hours;
    vm.prank(address(governance));
    governance.setConfig(_newVotingPeriod, _newResetGracePeriod, _newRootExpirationThreshold);
    assert(
      governance.proposalDeadline(PROPOSAL_ID) == _startVoteTimestamp + INITIAL_VOTING_DELAY + INITIAL_VOTING_PERIOD
    );
    // Assert that the config was correctly set
    assert(governance.votingPeriod() == _newVotingPeriod);
    assert(governance.resetGracePeriod() == _newResetGracePeriod);
    assert(governance.rootExpirationThreshold() == _newRootExpirationThreshold);

    // The two users vote `for`
    vm.prank(userOne);
    governance.castVoteWithReasonAndParams(PROPOSAL_ID, FOR_SUPPORT, REASON, userOneProofData);

    vm.prank(userTwo);
    governance.castVoteWithReasonAndParams(PROPOSAL_ID, FOR_SUPPORT, REASON, userTwoProofData);

    // Save balance before exec
    uint256 _goatGuyBalanceBefore = IERC20(WLD).balanceOf(GOAT_GUY);

    // After the voting period has ended, the proposal is executed
    vm.warp(block.timestamp + INITIAL_VOTING_PERIOD);

    string memory _saltDescription = string.concat(description, governance.proposalUniquenessSalt());
    bytes32 _descriptionHash = keccak256(abi.encodePacked(_saltDescription));
    vm.prank(owner);
    governance.execute(targets, values, calldatas, _descriptionHash);

    // Check that the Goat Guy has received the WLD tokens
    assert(IERC20(WLD).balanceOf(GOAT_GUY) == _goatGuyBalanceBefore + WLD_AMOUNT);
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
    vm.prank(userOne);
    governance.castVoteWithReasonAndParams(PROPOSAL_ID, FOR_SUPPORT, REASON, userOneProofData);

    // After the voting period has ended, the proposal is executed but fails
    vm.warp(block.timestamp + INITIAL_VOTING_PERIOD);

    // Get the proposal's description hash
    string memory _saltDescription = string.concat(description, governance.proposalUniquenessSalt());
    bytes32 _descriptionHash = keccak256(abi.encodePacked(_saltDescription));

    // Expect to revert with the unexpected proposal state error
    bytes32 _succeededStateBitmap = bytes32(1 << uint8(IGovernor.ProposalState.Succeeded));
    bytes32 _queuedStateBitmap = bytes32(1 << uint8(IGovernor.ProposalState.Queued));
    IGovernor.ProposalState _currentState = IGovernor.ProposalState.Defeated;
    bytes32 _expectedStateBitmap = _succeededStateBitmap | _queuedStateBitmap;
    vm.expectRevert(
      abi.encodeWithSelector(
        IGovernor.GovernorUnexpectedProposalState.selector, PROPOSAL_ID, _currentState, _expectedStateBitmap
      )
    );

    vm.prank(owner);
    governance.execute(targets, values, calldatas, _descriptionHash);
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
    vm.prank(userOne);
    governance.castVoteWithReasonAndParams(PROPOSAL_ID, FOR_SUPPORT, REASON, userOneProofData);

    vm.prank(userTwo);
    governance.castVoteWithReasonAndParams(PROPOSAL_ID, FOR_SUPPORT, REASON, userTwoProofData);

    // Get the proposal's description hash
    string memory _saltDescription = string.concat(description, governance.proposalUniquenessSalt());
    bytes32 _descriptionHash = keccak256(abi.encodePacked(_saltDescription));

    // Set the proposal state to active but not yet ended
    bytes32 _succeededStateBitmap = bytes32(1 << uint8(IGovernor.ProposalState.Succeeded));
    bytes32 _queuedStateBitmap = bytes32(1 << uint8(IGovernor.ProposalState.Queued));
    IGovernor.ProposalState _currentState = IGovernor.ProposalState.Active;
    bytes32 _expectedStateBitmap = _succeededStateBitmap | _queuedStateBitmap;
    // Expect a revert when trying to execute the proposal
    vm.expectRevert(
      abi.encodeWithSelector(
        IGovernor.GovernorUnexpectedProposalState.selector, PROPOSAL_ID, _currentState, _expectedStateBitmap
      )
    );

    vm.prank(owner);
    governance.execute(targets, values, calldatas, _descriptionHash);
  }
}
