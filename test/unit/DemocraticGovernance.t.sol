// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IMockDemocraticGovernanceForTest, MockDemocraticGovernance} from '../mocks/MockDemocraticGovernance.sol';
import {MockERC20Votes} from '../mocks/MockERC20Votes.sol';
import {GovernorSigUtils} from '../utils/GovernorSigUtils.sol';
import {UnitUtils} from './UnitUtils.sol';
import {Test, Vm} from 'forge-std/Test.sol';

import {IDemocraticGovernance} from 'interfaces/IDemocraticGovernance.sol';
import {IGovernorSettings} from 'interfaces/IGovernorSettings.sol';
import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';
import {IWorldIDIdentityManager} from 'interfaces/IWorldIDIdentityManager.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {ByteHasher} from 'libraries/ByteHasher.sol';
import {Ownable} from 'open-zeppelin/access/Ownable.sol';
import {IGovernor} from 'open-zeppelin/governance/IGovernor.sol';
import {GovernorSettings} from 'open-zeppelin/governance/extensions/GovernorSettings.sol';
import {IERC20} from 'open-zeppelin/token/ERC20/IERC20.sol';

abstract contract Base is Test, UnitUtils {
  uint8 public constant SUPPORT = 1;
  uint256 public constant GROUP_ID = 1;
  string public constant REASON = '';
  uint256 public constant WEIGHT = 1;
  uint256 public constant QUORUM = 5;
  uint256 public constant ONE = 1;
  bytes public constant APP_ID = 'appId';
  string public constant DESCRIPTION = '0xDescription';
  uint48 public constant INITIAL_VOTING_DELAY = 1 days;
  uint32 public constant INITIAL_VOTING_PERIOD = 3 days;
  uint256 public constant INITIAL_PROPOSAL_THRESHOLD = 0;
  uint256 public constant ROOT_EXPIRATION_THRESHOLD = 0;
  uint256 public constant RESET_GRACE_PERIOD = 13 days + 22 hours;
  uint256 public constant ROOT_HISTORY_EXPIRY = 1 weeks;
  uint128 public rootTimestamp = uint128(block.timestamp - 1);

  IERC20 public token;
  IGovernorWorldID public governor;
  IWorldIDRouter public worldIDRouter;
  IWorldIDIdentityManager public worldIDIdentityManager;
  GovernorSigUtils public sigUtils;

  uint256 public proposalId;
  bytes public signature;
  Vm.Wallet public signer;
  address public user;
  address public owner;

  function setUp() public {
    signer = vm.createWallet('signer');
    user = makeAddr('user');
    owner = makeAddr('owner');

    // Deploy token
    token = new MockERC20Votes();

    // Deploy mock worldIDRouter
    worldIDRouter = IWorldIDRouter(makeAddr('worldIDRouter'));
    vm.etch(address(worldIDRouter), new bytes(0x1));

    // Deploy mock worldIDIdentityManager
    worldIDIdentityManager = IWorldIDIdentityManager(makeAddr('worldIDIdentityManager'));
    vm.etch(address(worldIDIdentityManager), new bytes(0x1));

    // Mock the routeFor function
    vm.mockCall(
      address(worldIDRouter),
      abi.encodeWithSelector(IWorldIDRouter.routeFor.selector, GROUP_ID),
      abi.encode(address(worldIDIdentityManager))
    );

    // Mock the rootHistoryExpiry function
    vm.mockCall(
      address(worldIDIdentityManager),
      abi.encodeWithSelector(IWorldIDIdentityManager.rootHistoryExpiry.selector),
      abi.encode(1 weeks)
    );

    // Deploy governor
    vm.prank(owner);
    governor = IGovernorWorldID(
      new MockDemocraticGovernance(
        GROUP_ID,
        worldIDRouter,
        APP_ID,
        QUORUM,
        INITIAL_VOTING_DELAY,
        INITIAL_VOTING_PERIOD,
        INITIAL_PROPOSAL_THRESHOLD,
        ROOT_EXPIRATION_THRESHOLD
      )
    );

    // Deploy sigUtils
    sigUtils = new GovernorSigUtils(address(governor), 'DemocraticGovernor');

    // Create proposal
    vm.prank(owner);
    proposalId = governor.propose(new address[](1), new uint256[](1), new bytes[](1), DESCRIPTION);

    // Advance time assuming 1 block == 1 second (this will make the proposal active)
    vm.warp(block.timestamp + governor.votingDelay() + 1);
    vm.roll(block.number + governor.votingDelay() + 1);

    // Generate signature
    bytes32 _hash = sigUtils.getHash(proposalId, SUPPORT, signer.addr);
    (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(signer.privateKey, _hash);
    signature = abi.encodePacked(_r, _s, _v);
  }
}

contract DemocraticGovernance_Unit_Constructor is Base {
  /**
   * @notice Check that the constructor reverts if the root expiration threshold is bigger than the reset grace period
   */
  function test_revertIfThresholdBiggerThanResetGracePeriod(uint256 _rootExpirationThreshold) public {
    vm.assume(_rootExpirationThreshold > RESET_GRACE_PERIOD);

    vm.expectRevert(IGovernorWorldID.GovernorWorldID_InvalidRootExpirationThreshold.selector);
    vm.prank(address(governor));
    governor = new MockDemocraticGovernance(
      GROUP_ID,
      worldIDRouter,
      APP_ID,
      QUORUM,
      INITIAL_VOTING_DELAY,
      INITIAL_VOTING_PERIOD,
      INITIAL_PROPOSAL_THRESHOLD,
      _rootExpirationThreshold
    );
  }

  /**
   * @notice Check that the constructor reverts if the root expiration threshold is bigger than the root history expiry
   */
  function test_revertIfThresholdBiggerThanRootHistoryExpiry(uint256 _rootExpirationThreshold) public {
    vm.assume(_rootExpirationThreshold > ROOT_HISTORY_EXPIRY);

    vm.expectRevert(IGovernorWorldID.GovernorWorldID_InvalidRootExpirationThreshold.selector);
    vm.prank(address(governor));
    governor = new MockDemocraticGovernance(
      GROUP_ID,
      worldIDRouter,
      APP_ID,
      QUORUM,
      INITIAL_VOTING_DELAY,
      INITIAL_VOTING_PERIOD,
      INITIAL_PROPOSAL_THRESHOLD,
      _rootExpirationThreshold
    );
  }

  /**
   * @notice Check that the constructor works as expected
   */
  function test_correctDeploy(uint256 _rootExpirationThreshold) public {
    vm.assume(_rootExpirationThreshold <= RESET_GRACE_PERIOD);
    vm.assume(_rootExpirationThreshold <= ROOT_HISTORY_EXPIRY);

    vm.prank(address(governor));
    governor = new MockDemocraticGovernance(
      GROUP_ID,
      worldIDRouter,
      APP_ID,
      QUORUM,
      INITIAL_VOTING_DELAY,
      INITIAL_VOTING_PERIOD,
      INITIAL_PROPOSAL_THRESHOLD,
      _rootExpirationThreshold
    );
  }
}

contract DemocraticGovernance_Unit_WORLD_ID_ROUTER is Base {
  /**
   * @notice Test that the function returns the WorldIDRouter instance
   */
  function test_returnWorldIDInstance() public {
    assertEq(address(governor.WORLD_ID_ROUTER()), address(worldIDRouter));
  }
}

contract DemocraticGovernance_Unit_GROUP_ID is Base {
  /**
   * @notice Test that the function returns the group ID
   */
  function test_returnGroupId() public {
    assertEq(governor.GROUP_ID(), GROUP_ID);
  }
}

contract DemocraticGovernance_Unit_APP_ID is Base {
  using ByteHasher for bytes;

  /**
   * @notice Test that the function returns the app ID
   */
  function test_returnAppId() public view {
    assert(governor.APP_ID() == abi.encodePacked(APP_ID).hashToField());
  }
}

contract DemocraticGovernance_Unit_ResetGracePeriod is Base {
  /**
   * @notice Test that the function returns the correct reset grace period
   */
  function test_returnResetGracePeriod() public {
    assertEq(governor.resetGracePeriod(), RESET_GRACE_PERIOD);
  }
}

contract DemocraticGovernance_Unit_RootExpirationThreshold is Base {
  /**
   * @notice Test that the function returns the correct root expiration threshold
   */
  function test_returnRootExpirationThreshold() public {
    assertEq(governor.rootExpirationThreshold(), ROOT_EXPIRATION_THRESHOLD);
  }
}

contract DemocraticGovernance_Unit_SetRootExpirationThreshold is Base {
  /**
   * @notice Check that the function reverts if called by non-governance
   */
  function test_revertIfCalledByNonGovernance(uint256 _rootExpirationThreshold) public {
    vm.assume(_rootExpirationThreshold <= RESET_GRACE_PERIOD);
    vm.assume(_rootExpirationThreshold <= ROOT_HISTORY_EXPIRY);

    vm.expectRevert(abi.encodeWithSelector(IGovernor.GovernorOnlyExecutor.selector, user));
    vm.prank(user);
    governor.setRootExpirationThreshold(_rootExpirationThreshold);
  }

  /**
   * @notice Check that the function reverts if the new root expiration threshold is bigger than the reset grace period
   */
  function test_revertIfBiggerThanResetGracePeriod(uint256 _rootExpirationThreshold) public {
    vm.assume(_rootExpirationThreshold > RESET_GRACE_PERIOD);

    vm.expectRevert(IGovernorWorldID.GovernorWorldID_InvalidRootExpirationThreshold.selector);
    vm.prank(address(governor));
    governor.setRootExpirationThreshold(_rootExpirationThreshold);
  }

  /**
   * @notice Check that the function reverts if the new root expiration threshold is bigger than the reset grace period
   */
  function test_revertIfBiggerThanRootHistoryExpiry(uint256 _rootExpirationThreshold) public {
    vm.assume(_rootExpirationThreshold > ROOT_HISTORY_EXPIRY);

    vm.expectRevert(IGovernorWorldID.GovernorWorldID_InvalidRootExpirationThreshold.selector);
    vm.prank(address(governor));
    governor.setRootExpirationThreshold(_rootExpirationThreshold);
  }

  /**
   * @notice Check that the function works as expected
   */
  function test_setRootExpirationThreshold(uint256 _rootExpirationThreshold) public {
    vm.assume(_rootExpirationThreshold <= RESET_GRACE_PERIOD);
    vm.assume(_rootExpirationThreshold <= ROOT_HISTORY_EXPIRY);

    vm.expectEmit(true, true, true, true);
    emit IGovernorWorldID.RootExpirationThresholdUpdated(_rootExpirationThreshold, ROOT_EXPIRATION_THRESHOLD);

    vm.prank(address(governor));
    governor.setRootExpirationThreshold(_rootExpirationThreshold);
  }
}

contract DemocraticGovernance_Unit_SetResetGracePeriod is Base {
  /**
   * @notice Check that the function reverts if called by non-governance
   */
  function test_revertIfCalledByNonGovernance(uint256 _resetGracePeriod) public {
    vm.expectRevert(abi.encodeWithSelector(IGovernor.GovernorOnlyExecutor.selector, user));
    vm.prank(user);
    governor.setResetGracePeriod(_resetGracePeriod);
  }

  /**
   * @notice Check that the function works as expected
   */
  function test_setResetGracePeriod(uint256 _resetGracePeriod) public {
    vm.expectEmit(true, true, true, true);
    emit IGovernorWorldID.ResetGracePeriodUpdated(_resetGracePeriod, RESET_GRACE_PERIOD);

    vm.prank(address(governor));
    governor.setResetGracePeriod(_resetGracePeriod);
  }
}

contract DemocraticGovernance_Unit_CheckVoteValidity is Base {
  /**
   * @notice Test that the function reverts if the nullifier is already used
   */
  function test_revertIfNullifierAlreadyUsed(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);

    IMockDemocraticGovernanceForTest(address(governor)).forTest_setNullifierHash(_nullifierHash, true);

    vm.expectRevert(IGovernorWorldID.GovernorWorldID_NullifierHashAlreadyUsed.selector);
    vm.prank(user);
    governor.checkVoteValidity(SUPPORT, proposalId, _params);
  }

  /**
   * @notice Test that the function calls the latestRoot function from the Router contract
   */
  function test_callRouteFor(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    bytes memory _params = _mockWorlIDCalls(
      worldIDRouter, worldIDIdentityManager, _root, _nullifierHash, _proof, ROOT_EXPIRATION_THRESHOLD, rootTimestamp
    );

    _mockAndExpect(
      address(worldIDRouter),
      abi.encodeWithSelector(IWorldIDRouter.routeFor.selector),
      abi.encode(address(worldIDIdentityManager))
    );

    vm.prank(user);
    governor.checkVoteValidity(SUPPORT, proposalId, _params);
  }

  /**
   * @notice Test that the function calls the rootHistory function from the IdentityManager contract
   */
  function test_callRootHistory(
    uint128 _rootTimestamp,
    uint256 _root,
    uint256 _nullifierHash,
    uint256[8] memory _proof
  ) public {
    vm.warp(1_000_000);
    uint256 _rootExpirationThreshold = ROOT_EXPIRATION_THRESHOLD + 1;

    vm.assume(_rootTimestamp > block.timestamp - _rootExpirationThreshold);

    bytes memory _params = _mockWorlIDCalls(
      worldIDRouter, worldIDIdentityManager, _root, _nullifierHash, _proof, _rootExpirationThreshold, _rootTimestamp
    );

    // Set a new root expiration threshold
    vm.prank(address(governor));
    governor.setRootExpirationThreshold(_rootExpirationThreshold);

    vm.prank(user);
    governor.checkVoteValidity(SUPPORT, proposalId, _params);
  }

  /**
   * @notice Test that the function reverts if the root is outdated
   */
  function test_revertIfOutdatedRoot(
    uint128 _rootTimestamp,
    uint256 _root,
    uint256 _nullifierHash,
    uint256[8] memory _proof
  ) public {
    vm.warp(1_000_000);
    uint256 _rootExpirationThreshold = ROOT_EXPIRATION_THRESHOLD + 1;

    vm.assume(_rootTimestamp < block.timestamp - _rootExpirationThreshold);

    _mockAndExpect(
      address(worldIDIdentityManager),
      abi.encodeWithSelector(IWorldIDIdentityManager.rootHistory.selector),
      abi.encode(_rootTimestamp)
    );

    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);

    // Set a new root expiration threshold
    vm.prank(address(governor));
    governor.setRootExpirationThreshold(_rootExpirationThreshold);

    // Try to cast a vote with an outdated root
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_OutdatedRoot.selector);
    vm.prank(user);
    governor.checkVoteValidity(SUPPORT, proposalId, _params);
  }

  /**
   * @notice Test that the function calls the latestRoot function from the IdentityManager contract
   */
  function test_callLatestRoot(
    uint256 _root,
    uint256 _latestRoot,
    uint256 _nullifierHash,
    uint256[8] memory _proof
  ) public {
    // Encode the parameters
    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);

    _mockWorlIDCalls(
      worldIDRouter,
      worldIDIdentityManager,
      _latestRoot,
      _nullifierHash,
      _proof,
      ROOT_EXPIRATION_THRESHOLD,
      rootTimestamp
    );

    vm.prank(user);
    governor.checkVoteValidity(SUPPORT, proposalId, _params);
  }

  /**
   * @notice Test that the function calls the verifyProof function from the WorldID contract
   */
  function test_callVerifyProof(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    bytes memory _params = _mockWorlIDCalls(
      worldIDRouter, worldIDIdentityManager, _root, _nullifierHash, _proof, ROOT_EXPIRATION_THRESHOLD, rootTimestamp
    );

    vm.prank(user);
    governor.checkVoteValidity(SUPPORT, proposalId, _params);
  }

  /**
   * @notice Test that the function returns the nullifier hash
   */
  function test_returnNullifierHash(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    bytes memory _params = _mockWorlIDCalls(
      worldIDRouter, worldIDIdentityManager, _root, _nullifierHash, _proof, ROOT_EXPIRATION_THRESHOLD, rootTimestamp
    );

    vm.prank(user);
    uint256 _returnedNullifierHash = governor.checkVoteValidity(SUPPORT, proposalId, _params);
    assertEq(_returnedNullifierHash, _nullifierHash);
  }
}

contract DemocraticGovernance_Unit_VotingDelay is Base {
  /**
   * @notice Check that the function works as expected
   */
  function test_VotingDelay() public {
    assertEq(governor.votingDelay(), INITIAL_VOTING_DELAY);
  }
}

contract DemocraticGovernance_Unit_VotingPeriod is Base {
  /**
   * @notice Check that the function works as expected
   */
  function test_VotingPeriod() public {
    assertEq(governor.votingPeriod(), INITIAL_VOTING_PERIOD);
  }
}

contract DemocraticGovernance_Unit_ProposalThreshold is Base {
  /**
   * @notice Check that the function works as expected
   */
  function test_ProposalThreshold() public {
    assertEq(governor.proposalThreshold(), INITIAL_PROPOSAL_THRESHOLD);
  }
}

contract DemocraticGovernance_Unit_SetVotingPeriod is Base {
  /**
   * @notice Check that the function reverts if invalid voting period
   */
  function test_revertIfInvalidPeriodWhenZeroThreshold(uint32 _votingPeriod) public {
    vm.assume(_votingPeriod > RESET_GRACE_PERIOD);

    vm.expectRevert(IGovernorWorldID.GovernorWorldID_InvalidVotingPeriod.selector);
    vm.prank(address(governor));
    IGovernorSettings(address(governor)).setVotingPeriod(_votingPeriod);
  }

  /**
   * @notice Check that the function reverts if invalid voting period
   */
  function test_revertIfInvalidPeriodWhenNonZeroThreshold(uint32 _votingPeriod) public {
    uint256 _rootExpirationThreshold = ROOT_EXPIRATION_THRESHOLD + 1;

    vm.assume(_votingPeriod > RESET_GRACE_PERIOD - _rootExpirationThreshold);

    // Set a new root expiration threshold
    vm.prank(address(governor));
    governor.setRootExpirationThreshold(_rootExpirationThreshold);

    vm.expectRevert(IGovernorWorldID.GovernorWorldID_InvalidVotingPeriod.selector);
    vm.prank(address(governor));
    IGovernorSettings(address(governor)).setVotingPeriod(_votingPeriod);
  }

  /**
   * @notice Check that the function works as expected
   */
  function test_setVotingPeriod(uint32 _votingPeriod) public {
    vm.assume(_votingPeriod != 0);
    vm.assume(_votingPeriod < RESET_GRACE_PERIOD);

    vm.expectEmit(true, true, true, true);
    emit GovernorSettings.VotingPeriodSet(INITIAL_VOTING_PERIOD, _votingPeriod);

    vm.prank(address(governor));
    IGovernorSettings(address(governor)).setVotingPeriod(_votingPeriod);
  }
}

contract DemocraticGovernance_Unit_CastVote_WithoutParams is Base {
  /**
   * @notice Check that the function is disabled and reverts
   */
  function test_revertWithNotSupportedFunction() public {
    vm.prank(user);
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_NotSupportedFunction.selector);
    governor.castVote(proposalId, SUPPORT);
  }
}

contract DemocraticGovernance_Unit_CastVoteWithReason is Base {
  /**
   * @notice Check that the function is disabled and reverts
   */
  function test_revertWithNotSupportedFunction() public {
    vm.prank(user);
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_NotSupportedFunction.selector);
    governor.castVoteWithReason(proposalId, SUPPORT, REASON);
  }
}

contract DemocraticGovernance_Unit_CastVoteBySig is Base {
  /**
   * @notice Check that the function is disabled and reverts
   */
  function test_revertWithNotSupportedFunction() public {
    vm.prank(signer.addr);
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_NotSupportedFunction.selector);
    governor.castVoteBySig(proposalId, SUPPORT, signer.addr, signature);
  }
}

contract DemocraticGovernance_Unit_CastVote_WithParams is Base {
  /**
   * @notice Check that the function stores the nullifier as used
   */
  function test_nullifierIsStored(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    bytes memory _params = _mockWorlIDCalls(
      worldIDRouter, worldIDIdentityManager, _root, _nullifierHash, _proof, ROOT_EXPIRATION_THRESHOLD, rootTimestamp
    );

    // Cast the vote
    vm.prank(user);
    IMockDemocraticGovernanceForTest(address(governor)).forTest_castVote(proposalId, user, SUPPORT, REASON, _params);

    assertTrue(governor.nullifierHashes(_nullifierHash));
  }

  /**
   * @notice Check that the function works as expected
   */
  function test_castVoteWithReasonAndParams(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    bytes memory _params = _mockWorlIDCalls(
      worldIDRouter, worldIDIdentityManager, _root, _nullifierHash, _proof, ROOT_EXPIRATION_THRESHOLD, rootTimestamp
    );

    vm.expectEmit(true, true, true, true);
    emit IGovernor.VoteCastWithParams(user, proposalId, SUPPORT, WEIGHT, REASON, _params);

    // Cast the vote
    vm.prank(user);
    IMockDemocraticGovernanceForTest(address(governor)).forTest_castVote(proposalId, user, SUPPORT, REASON, _params);
  }
}

contract DemocraticGovernance_Unit_CastVoteWithReasonAndParams is Base {
  /**
   * @notice Check that the function works as expected
   */
  function test_castVoteWithReasonAndParams(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    bytes memory _params = _mockWorlIDCalls(
      worldIDRouter, worldIDIdentityManager, _root, _nullifierHash, _proof, ROOT_EXPIRATION_THRESHOLD, rootTimestamp
    );

    vm.expectEmit(true, true, true, true);
    emit IGovernor.VoteCastWithParams(user, proposalId, SUPPORT, WEIGHT, REASON, _params);

    // Cast the vote
    vm.prank(user);
    governor.castVoteWithReasonAndParams(proposalId, SUPPORT, REASON, _params);
  }
}

contract DemocraticGovernance_Unit_CastVoteWithReasonAndParamsBySig is Base {
  /**
   * @notice Check that the function works as expected
   */
  function test_castVoteWithReasonAndParamsBySig(
    uint256 _root,
    uint256 _nullifierHash,
    uint256[8] memory _proof
  ) public {
    bytes memory _params = _mockWorlIDCalls(
      worldIDRouter, worldIDIdentityManager, _root, _nullifierHash, _proof, ROOT_EXPIRATION_THRESHOLD, rootTimestamp
    );

    // Sign
    bytes32 _hash = sigUtils.getHash(proposalId, SUPPORT, signer.addr, REASON, _params);
    (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(signer.privateKey, _hash);
    bytes memory _extendedBallotSignature = abi.encodePacked(_r, _s, _v);

    vm.expectEmit(true, true, true, true);
    emit IGovernor.VoteCastWithParams(signer.addr, proposalId, SUPPORT, WEIGHT, REASON, _params);

    // Cast the vote
    vm.prank(user);
    governor.castVoteWithReasonAndParamsBySig(
      proposalId, SUPPORT, signer.addr, REASON, _params, _extendedBallotSignature
    );
  }
}

contract DemocraticGovernance_Unit_GetVotes is Base {
  /**
   * @notice Check that the voting weight is 1
   */
  function test_returnsOne(address _account, uint256 _timepoint, bytes memory _params) public {
    uint256 _votingWeight =
      IMockDemocraticGovernanceForTest(address(governor)).forTest_getVotes(_account, _timepoint, _params);
    assertEq(_votingWeight, ONE);
  }
}

contract DemocraticGovernance_Unit_Propose is Base {
  /**
   * @notice Check that only the owner can propose
   */
  function test_revertWithNotOwner(string memory _description) public {
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
    vm.prank(user);
    governor.propose(new address[](1), new uint256[](1), new bytes[](1), _description);
  }

  /**
   * @notice Check that the function works as expected
   */
  function test_proposalsQuorumThreshold(string memory _description) public {
    vm.assume(keccak256(abi.encode(_description)) != keccak256(abi.encode((DESCRIPTION))));

    uint256 _quorumBeforePropose = IDemocraticGovernance(address(governor)).quorum(block.number);

    vm.prank(owner);
    uint256 _proposalId =
      IDemocraticGovernance(address(governor)).propose(new address[](1), new uint256[](1), new bytes[](1), _description);

    uint256 _quorumFromProposal = IDemocraticGovernance(address(governor)).proposalsQuorumThreshold(_proposalId);
    assertEq(_quorumFromProposal, _quorumBeforePropose);
  }

  /**
   * @notice Check that the function returns the correct proposalId
   */
  function test_returnsCorrectProposalId(string memory _description) public {
    vm.assume(keccak256(abi.encode(_description)) != keccak256(abi.encode((DESCRIPTION))));

    address[] memory _targets = new address[](1);
    uint256[] memory _values = new uint256[](1);
    bytes[] memory _calldatas = new bytes[](1);
    bytes32 _descriptionHash = keccak256(bytes(_description));
    uint256 _proposalId = governor.hashProposal(_targets, _values, _calldatas, _descriptionHash);

    vm.prank(owner);
    uint256 _proposalIdCreated = governor.propose(_targets, _values, _calldatas, _description);

    assertEq(_proposalId, _proposalIdCreated);
  }

  /**
   * @notice Check that the function works as expected
   */
  function test_propose(string memory _description) public {
    vm.assume(keccak256(abi.encode(_description)) != keccak256(abi.encode((DESCRIPTION))));

    address[] memory _targets = new address[](1);
    uint256[] memory _values = new uint256[](1);
    bytes[] memory _calldatas = new bytes[](1);
    bytes32 _descriptionHash = keccak256(bytes(_description));
    uint256 _proposalId = governor.hashProposal(_targets, _values, _calldatas, _descriptionHash);

    vm.expectEmit(true, true, true, true);
    uint256 snapshot = governor.clock() + governor.votingDelay();
    emit IGovernor.ProposalCreated(
      _proposalId,
      owner,
      _targets,
      _values,
      new string[](_targets.length),
      _calldatas,
      snapshot,
      snapshot + governor.votingPeriod(),
      _description
    );

    vm.prank(owner);
    governor.propose(_targets, _values, _calldatas, _description);
  }
}

contract DemocraticGovernance_Unit_SetQuorum is Base {
  /**
   * @notice Check that only governance can set the quorum
   */
  function test_revertWithNotGovernance(uint256 _quorum) public {
    vm.expectRevert(abi.encodeWithSelector(IGovernor.GovernorOnlyExecutor.selector, user));
    vm.prank(user);
    IDemocraticGovernance(address(governor)).setQuorum(_quorum);
  }

  /**
   * @notice Check that the function works as expected
   */
  function test_setQuorum(uint256 _quorum) public {
    vm.prank(address(governor));
    IDemocraticGovernance(address(governor)).setQuorum(_quorum);
    uint256 _quorumFromGovernor = IDemocraticGovernance(address(governor)).quorum(block.number);
    assertEq(_quorumFromGovernor, _quorum);
  }

  /**
   * @notice Check that the function emits the QuorumSet event
   */
  function test_emitQuorumSet(uint256 _quorum) public {
    vm.expectEmit(true, true, true, true);
    emit IDemocraticGovernance.QuorumSet(_quorum);

    vm.prank(address(governor));
    IDemocraticGovernance(address(governor)).setQuorum(_quorum);
  }
}

contract DemocraticGovernance_Unit_Quorum is Base {
  /**
   * @notice Test that the function returns the current quorum, independently of the given argument
   */
  function test_returnQuorum(uint256 _randomNumber) public {
    assertEq(governor.quorum(_randomNumber), QUORUM);
  }
}

contract DemocraticGovernance_Unit_Clock is Base {
  /**
   * @notice Test that the function returns the clock
   */
  function test_returnClock() public {
    assertEq(governor.clock(), block.timestamp);
  }
}

contract DemocraticGovernance_Unit_CLOCK_MODE is Base {
  /**
   * @notice Test that the function returns the clock mode
   */
  function test_returnClockMode() public {
    string memory _mode = 'mode=blocktimestamp&from=default';
    assertEq(governor.CLOCK_MODE(), _mode);
  }
}

contract DemocraticGovernance_Unit_QuorumReached is Base {
  /**
   * @notice Test that the function returns if the quorum is reached
   */
  function test_reachedQuorum(string memory _description) public {
    vm.assume(keccak256(abi.encode(_description)) != keccak256(abi.encode((DESCRIPTION))));

    // Propose and vote
    uint256 _proposalId = _proposeAndVote(owner, _description, QUORUM + 1);

    // Check that the quorum is reached
    assertTrue(IMockDemocraticGovernanceForTest(address(governor)).forTest_quorumReached(_proposalId));
  }

  /**
   * @notice Test that the function returns if the quorum is not reached
   */
  function test_notReachedQuorum(string memory _description) public {
    vm.assume(keccak256(abi.encode(_description)) != keccak256(abi.encode((DESCRIPTION))));

    // Propose and vote
    uint256 _proposalId = _proposeAndVote(owner, _description, QUORUM - 1);

    // Check that the quorum is reached
    assertFalse(IMockDemocraticGovernanceForTest(address(governor)).forTest_quorumReached(_proposalId));
  }

  /**
   * @dev Propose a new proposal, and generate random accounts to vote on it the desired number of votes
   */
  function _proposeAndVote(
    address _owner,
    string memory _description,
    uint256 _votesRequired
  ) internal returns (uint256 _proposalId) {
    address[] memory _targets = new address[](1);
    uint256[] memory _values = new uint256[](1);
    bytes[] memory _calldatas = new bytes[](1);

    vm.prank(_owner);
    _proposalId = governor.propose(_targets, _values, _calldatas, _description);

    // Advance time assuming 1 block == 1 second (this will make the proposal active)
    vm.warp(block.timestamp + governor.votingDelay() + 1);
    vm.roll(block.number + governor.votingDelay() + 1);

    // Vote
    for (uint256 i = 0; i < _votesRequired; i++) {
      address _randomVoter = vm.addr(uint256(keccak256(abi.encodePacked(i, _description))));
      vm.prank(_randomVoter);
      IMockDemocraticGovernanceForTest(address(governor)).forTest_countVote(_proposalId, _randomVoter, SUPPORT, WEIGHT);
    }
  }
}
