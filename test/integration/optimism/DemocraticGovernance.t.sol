// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.23;

import {Common} from './Common.sol';
import 'forge-std/Test.sol';
import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';

contract DemocraticGovernance_Integration_NonZeroThreshold is Common {
  error InvalidProof();

  function test_voteWithValidProof() public {
    (uint256 _againstVotesBef, uint256 _forVotesBef, uint256 _abstainVotesBef) = governance.proposalVotes(PROPOSAL_ID);

    vm.prank(user);
    uint256 _votingWeigth = governance.castVoteWithReasonAndParams(PROPOSAL_ID, FOR_SUPPORT, VOTE_REASON, proofData);

    (uint256 _againstVotesAfter, uint256 _forVotesAfter, uint256 _abstainVotesAfter) =
      governance.proposalVotes(PROPOSAL_ID);

    // Assert the user has voted, with 1 as voting weight supporting the proposal.
    assertTrue(governance.hasVoted(PROPOSAL_ID, user));
    assertEq(_votingWeigth, _ONE);
    assertEq(_forVotesAfter, _forVotesBef + 1);
    assertEq(_abstainVotesAfter, _abstainVotesBef);
    assertEq(_againstVotesAfter, _againstVotesBef);
  }

  function test_revertIfVotingTwiceOnSameProposal() public {
    vm.startPrank(user);
    governance.castVoteWithReasonAndParams(PROPOSAL_ID, FOR_SUPPORT, VOTE_REASON, proofData);
    assertTrue(governance.hasVoted(PROPOSAL_ID, user));

    vm.expectRevert(IGovernorWorldID.GovernorWorldID_NullifierHashAlreadyUsed.selector);
    governance.castVoteWithReasonAndParams(PROPOSAL_ID, FOR_SUPPORT, VOTE_REASON, proofData);
  }

  function test_revertIfInvalidVote(
    uint8 _invalidSupport,
    uint256 _invalidNullifierHash,
    uint256[8] memory _invalidProof
  ) public {
    bytes memory _invalidProofData = abi.encode(ROOT, _invalidNullifierHash, _invalidProof);
    vm.expectRevert(InvalidProof.selector);

    vm.prank(user);
    governance.castVoteWithReasonAndParams(PROPOSAL_ID, _invalidSupport, VOTE_REASON, _invalidProofData);
  }

  function test_revertIfInvalidSupportSignal() public {
    uint8 _againstSupport = 0;
    vm.expectRevert(InvalidProof.selector);

    vm.prank(user);
    uint256 _votingWeigth = governance.castVoteWithReasonAndParams(PROPOSAL_ID, _againstSupport, VOTE_REASON, proofData);
  }

  function test_revertIfOutdatedRoot() public {
    vm.warp(block.timestamp + rootExpirationThreshold + 1);

    vm.expectRevert(IGovernorWorldID.GovernorWorldID_OutdatedRoot.selector);

    vm.prank(user);
    uint256 _votingWeigth = governance.castVoteWithReasonAndParams(PROPOSAL_ID, FOR_SUPPORT, VOTE_REASON, proofData);
  }
}

contract DemocraticGovernance_Integration_ZeroThreshold is Common {
  error InvalidProof();

  function setUp() public override {
    rootExpirationThreshold = 0;
    super.setUp();
  }

  function test_voteWithValidProof() public {
    (uint256 _againstVotesBef, uint256 _forVotesBef, uint256 _abstainVotesBef) = governance.proposalVotes(PROPOSAL_ID);

    vm.prank(user);
    uint256 _votingWeigth = governance.castVoteWithReasonAndParams(PROPOSAL_ID, FOR_SUPPORT, VOTE_REASON, proofData);

    (uint256 _againstVotesAfter, uint256 _forVotesAfter, uint256 _abstainVotesAfter) =
      governance.proposalVotes(PROPOSAL_ID);

    // Assert the user has voted, with 1 as voting weight supporting the proposal.
    assertTrue(governance.hasVoted(PROPOSAL_ID, user));
    assertEq(_votingWeigth, _ONE);
    assertEq(_forVotesAfter, _forVotesBef + 1);
    assertEq(_abstainVotesAfter, _abstainVotesBef);
    assertEq(_againstVotesAfter, _againstVotesBef);
  }

  function test_revertIfVotingTwiceOnSameProposal() public {
    vm.startPrank(user);
    governance.castVoteWithReasonAndParams(PROPOSAL_ID, FOR_SUPPORT, VOTE_REASON, proofData);
    assertTrue(governance.hasVoted(PROPOSAL_ID, user));

    vm.expectRevert(IGovernorWorldID.GovernorWorldID_NullifierHashAlreadyUsed.selector);
    governance.castVoteWithReasonAndParams(PROPOSAL_ID, FOR_SUPPORT, VOTE_REASON, proofData);
  }

  function test_revertIfInvalidVote(
    uint8 _invalidSupport,
    uint256 _invalidNullifierHash,
    uint256[8] memory _invalidProof
  ) public {
    bytes memory _invalidProofData = abi.encode(ROOT, _invalidNullifierHash, _invalidProof);
    vm.expectRevert(InvalidProof.selector);

    vm.prank(user);
    governance.castVoteWithReasonAndParams(PROPOSAL_ID, _invalidSupport, VOTE_REASON, _invalidProofData);
  }

  function test_revertIfInvalidSupportSignal() public {
    uint8 _againstSupport = 0;
    vm.expectRevert(InvalidProof.selector);

    vm.prank(user);
    uint256 _votingWeigth = governance.castVoteWithReasonAndParams(PROPOSAL_ID, _againstSupport, VOTE_REASON, proofData);
  }

  function test_revertIfNotLatestRoot() public {
    // Current block number where the latest root changed
    uint256 _currentBlockNumber = 118_381_402;

    vm.makePersistent(address(governance));
    vm.createSelectFork(vm.rpcUrl('optimism'), _currentBlockNumber);

    vm.prank(user);
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_OutdatedRoot.selector);
    uint256 _votingWeigth = governance.castVoteWithReasonAndParams(PROPOSAL_ID, FOR_SUPPORT, VOTE_REASON, proofData);
  }
}
