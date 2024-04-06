// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.23;

import {Common} from './Common.sol';
import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';

/**
 * @notice Contract that tests the voting flows on the DemocraticGovernance contract
 * by using a non-zero root expiration threshold.
 */
contract DemocraticGovernance_Integration_NonZeroThreshold is Common {
  error InvalidProof();

  /**
   * @notice Test a user casts his vote using a real proof to validate the vote.
   */
  function test_voteWithValidProof() public {
    // Get the proposals votes before the vote
    (uint256 _againstVotesBef, uint256 _forVotesBef, uint256 _abstainVotesBef) = governance.proposalVotes(PROPOSAL_ID);

    // Cast the vote
    vm.prank(user);
    uint256 _votingWeigth = governance.castVoteWithReasonAndParams(PROPOSAL_ID, FOR_SUPPORT, REASON, proofData);

    // Get the proposals votes after the vote
    (uint256 _againstVotesAfter, uint256 _forVotesAfter, uint256 _abstainVotesAfter) =
      governance.proposalVotes(PROPOSAL_ID);

    // Assert the user has voted, with 1 as voting weight supporting the proposal.
    assertTrue(governance.hasVoted(PROPOSAL_ID, user));
    assertEq(_votingWeigth, 1);
    assertEq(_forVotesAfter, _forVotesBef + 1);
    assertEq(_abstainVotesAfter, _abstainVotesBef);
    assertEq(_againstVotesAfter, _againstVotesBef);
  }

  /**
   * @notice Test a user tries to vote twice on the same proposal and expect the second vote to revert.
   */
  function test_revertIfVotingTwiceOnSameProposal() public {
    // Cast the vote
    vm.startPrank(user);
    governance.castVoteWithReasonAndParams(PROPOSAL_ID, FOR_SUPPORT, REASON, proofData);
    assertTrue(governance.hasVoted(PROPOSAL_ID, user));

    // Try to cast the same vote over the same proposal again and expect it to revert
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_NullifierHashAlreadyUsed.selector);
    governance.castVoteWithReasonAndParams(PROPOSAL_ID, FOR_SUPPORT, REASON, proofData);

    // Try to cast the same vote over the same proposal again from another address and expect it to revert
    vm.stopPrank();
    vm.prank(stranger);
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_NullifierHashAlreadyUsed.selector);
    governance.castVoteWithReasonAndParams(PROPOSAL_ID, FOR_SUPPORT, REASON, proofData);
  }

  /**
   * @notice Test a user tries to vote with an invalid proof and expect the vote to revert.
   */
  function test_revertIfInvalidVote(
    uint8 _invalidSupport,
    uint256 _invalidNullifierHash,
    uint256[8] memory _invalidProof
  ) public {
    // Get the invalid proof data
    bytes memory _invalidProofData = abi.encode(ROOT, _invalidNullifierHash, _invalidProof);

    // Try to vote with the invalid proof and expect it to revert
    vm.expectRevert(InvalidProof.selector);
    vm.prank(user);
    governance.castVoteWithReasonAndParams(PROPOSAL_ID, _invalidSupport, REASON, _invalidProofData);
  }

  /**
   * @notice Test a user tries to use the valid proof, but with another support (signal) and expect the vote to revert.
   */
  function test_revertIfInvalidSupportSignal() public {
    // The real signal used for the support was `1`, so `0` is an invalid one for the given proof
    uint8 _againstSupport = 0;

    // Try to vote with the invalid support signal and expect it to revert
    vm.expectRevert(InvalidProof.selector);
    vm.prank(user);
    governance.castVoteWithReasonAndParams(PROPOSAL_ID, _againstSupport, REASON, proofData);
  }

  /**
   * @notice Test a user tries to vote with an outdated root and expect the vote to revert.
   */
  function test_revertIfOutdatedRoot() public {
    // Advance the time to make the root outdated
    vm.warp(block.timestamp + rootExpirationThreshold + 1);

    // Try to vote with the outdated root and expect it to revert
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_OutdatedRoot.selector);
    vm.prank(user);
    governance.castVoteWithReasonAndParams(PROPOSAL_ID, FOR_SUPPORT, REASON, proofData);
  }
}

/**
 * @notice Contract that tests the voting flows on the DemocraticGovernance contract
 * by using a zero root expiration threshold.
 */
contract DemocraticGovernance_Integration_ZeroThreshold is Common {
  error InvalidProof();

  /**
   * @notice Set the root expiration threshold to zero before each test, to simulate the zero threshold scenario
   * that calls `latestRoot`.
   */
  function setUp() public override {
    rootExpirationThreshold = 0;
    super.setUp();
  }

  /**
   * @notice Test a user casts his vote using a real proof to validate the vote.
   */
  function test_voteWithValidProof() public {
    // Get the proposals votes before the vote
    (uint256 _againstVotesBef, uint256 _forVotesBef, uint256 _abstainVotesBef) = governance.proposalVotes(PROPOSAL_ID);

    // Cast the vote
    vm.prank(user);
    uint256 _votingWeigth = governance.castVoteWithReasonAndParams(PROPOSAL_ID, FOR_SUPPORT, REASON, proofData);

    // Get the proposals votes after the vote
    (uint256 _againstVotesAfter, uint256 _forVotesAfter, uint256 _abstainVotesAfter) =
      governance.proposalVotes(PROPOSAL_ID);

    // Assert the user has voted, with 1 as voting weight supporting the proposal.
    assertTrue(governance.hasVoted(PROPOSAL_ID, user));
    assertEq(_votingWeigth, 1);
    assertEq(_forVotesAfter, _forVotesBef + 1);
    assertEq(_abstainVotesAfter, _abstainVotesBef);
    assertEq(_againstVotesAfter, _againstVotesBef);
  }

  /**
   * @notice Test a user tries to vote twice on the same proposal and expect the second vote to revert.
   */
  function test_revertIfVotingTwiceOnSameProposal() public {
    // Cast the vote
    vm.startPrank(user);
    governance.castVoteWithReasonAndParams(PROPOSAL_ID, FOR_SUPPORT, REASON, proofData);
    assertTrue(governance.hasVoted(PROPOSAL_ID, user));

    // Try to cast the same vote over the same proposal again and expect it to revert
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_NullifierHashAlreadyUsed.selector);
    governance.castVoteWithReasonAndParams(PROPOSAL_ID, FOR_SUPPORT, REASON, proofData);

    // Try to cast the same vote over the same proposal again from another address and expect it to revert
    vm.stopPrank();
    vm.prank(stranger);
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_NullifierHashAlreadyUsed.selector);
    governance.castVoteWithReasonAndParams(PROPOSAL_ID, FOR_SUPPORT, REASON, proofData);
  }

  /**
   * @notice Test a user tries to vote with an invalid proof and expect the vote to revert.
   */
  function test_revertIfInvalidVote(
    uint8 _invalidSupport,
    uint256 _invalidNullifierHash,
    uint256[8] memory _invalidProof
  ) public {
    // Get the invalid proof data
    bytes memory _invalidProofData = abi.encode(ROOT, _invalidNullifierHash, _invalidProof);

    // Try to vote with the invalid proof and expect it to revert
    vm.expectRevert(InvalidProof.selector);
    vm.prank(user);
    governance.castVoteWithReasonAndParams(PROPOSAL_ID, _invalidSupport, REASON, _invalidProofData);
  }

  /**
   * @notice Test a user tries to use the valid proof, but with another support (signal) and expect the vote to revert.
   */
  function test_revertIfInvalidSupportSignal() public {
    // The real signal used for the support was `1`, so `0` is an invalid one for the given proof
    uint8 _againstSupport = 0;

    // Try to vote with the invalid support signal and expect it to revert
    vm.expectRevert(InvalidProof.selector);
    vm.prank(user);
    governance.castVoteWithReasonAndParams(PROPOSAL_ID, _againstSupport, REASON, proofData);
  }

  /**
   * @notice Test a user tries to vote when the `ROOT` from the proof is not anymore the current one
   */
  function test_revertIfNotLatestRoot() public {
    // Current block number where the latest root changed
    uint256 _currentBlockNumber = 118_381_402;

    // Make persisten the deployed governance contract
    vm.makePersistent(address(governance));
    // Advance the block number to the current one, where the `ROOT` is not longer the current one on the Merkle tree
    vm.createSelectFork(vm.rpcUrl('optimism'), _currentBlockNumber);

    // Try to vote with the outdated root and expect it to revert
    vm.prank(user);
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_OutdatedRoot.selector);
    governance.castVoteWithReasonAndParams(PROPOSAL_ID, FOR_SUPPORT, REASON, proofData);
  }
}
