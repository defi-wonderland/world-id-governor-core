// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {MockERC20Votes} from '../mocks/MockERC20Votes.sol';
import {IMockGovernorWorldIdForTest, MockGovernorWorldId} from '../mocks/MockGovernorWorldId.sol';
import {GovernorSigUtils} from '../utils/GovernorSigUtils.sol';
import {UnitUtils} from './UnitUtils.sol';
import {Test, Vm, console} from 'forge-std/Test.sol';
import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';
import {IWorldIDIdentityManager} from 'interfaces/IWorldIDIdentityManager.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {ByteHasher} from 'libraries/ByteHasher.sol';
import {IGovernor} from 'open-zeppelin/governance/IGovernor.sol';
import {IVotes} from 'open-zeppelin/governance/utils/IVotes.sol';
import {IERC20} from 'open-zeppelin/token/ERC20/IERC20.sol';

abstract contract Base is Test, UnitUtils {
  uint8 public constant SUPPORT = 1;
  uint256 public constant GROUP_ID = 1;
  string public constant REASON = '';
  uint256 public constant WEIGHT = 0;
  bytes public constant APP_ID = 'appId';
  uint48 public constant INITIAL_VOTING_DELAY = 1 days;
  uint32 public constant INITIAL_VOTING_PERIOD = 3 days;
  uint256 public constant INITIAL_PROPOSAL_THRESHOLD = 0;
  uint256 public constant ROOT_EXPIRATION_THRESHOLD = 0;
  uint256 public constant RESET_GRACE_PERIOD = 14 days;
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

  function setUp() public {
    signer = vm.createWallet('signer');
    user = makeAddr('user');

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

    // Mock the getRootHistoryExpiry function
    vm.mockCall(
      address(worldIDIdentityManager),
      abi.encodeWithSelector(IWorldIDIdentityManager.getRootHistoryExpiry.selector),
      abi.encode(ROOT_HISTORY_EXPIRY)
    );

    // Deploy governor
    governor =
    new MockGovernorWorldId(MockGovernorWorldId.ConstructorArgs(GROUP_ID, worldIDRouter, APP_ID, IVotes(address(token)), INITIAL_VOTING_DELAY, INITIAL_VOTING_PERIOD, INITIAL_PROPOSAL_THRESHOLD, ROOT_EXPIRATION_THRESHOLD));

    // Deploy sigUtils
    sigUtils = new GovernorSigUtils(address(governor), 'Governor');

    // Create proposal
    string memory _description = '0xDescription';
    proposalId = governor.propose(new address[](1), new uint256[](1), new bytes[](1), _description);

    // Advance time assuming 1 block == 1 second (this will make the proposal active)
    vm.warp(block.timestamp + governor.votingDelay() + 1);
    vm.roll(block.number + governor.votingDelay() + 1);

    // Generate signature
    bytes32 _hash = sigUtils.getHash(proposalId, SUPPORT, signer.addr);
    (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(signer.privateKey, _hash);
    signature = abi.encodePacked(_r, _s, _v);
  }
}

contract GovernorWorldId_Unit_WORLD_ID_ROUTER is Base {
  /**
   * @notice Test that the function returns the WorldIDRouter instance
   */
  function test_returnWorldIDInstance() public {
    assertEq(address(governor.WORLD_ID_ROUTER()), address(worldIDRouter));
  }
}

contract GovernorWorldId_Unit_GROUP_ID is Base {
  /**
   * @notice Test that the function returns the group ID
   */
  function test_returnGroupId() public {
    assertEq(governor.GROUP_ID(), GROUP_ID);
  }
}

contract GovernorWorldId_Unit_APP_ID is Base {
  /**
   * @notice Test that the function returns the app ID
   */
  function test_returnAppId() public {
    // assertEq(governor.APP_ID(), APP_ID);
  }
}

contract GovernorWorldId_Unit_ResetGracePeriod is Base {
  /**
   * @notice Test that the function returns the correct reset grace period
   */
  function test_returnResetGracePeriod() public {
    assertEq(governor.resetGracePeriod(), 14 days);
  }
}

contract GovernorWorldId_Unit_RootExpirationThreshold is Base {
  /**
   * @notice Test that the function returns the correct root expiration threshold
   */
  function test_returnRootExpirationThreshold() public {
    assertEq(governor.rootExpirationThreshold(), ROOT_EXPIRATION_THRESHOLD);
  }
}

contract GovernorWorldID_Unit_CastVote_WithoutParams is Base {
  /**
   * @notice Check that the function is disabled and reverts
   */
  function test_revertWithNotSupportedFunction() public {
    vm.prank(user);
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_NotSupportedFunction.selector);
    governor.castVote(proposalId, SUPPORT);
  }
}

contract GovernorWorldID_Unit_CastVoteWithReason is Base {
  /**
   * @notice Check that the function is disabled and reverts
   */
  function test_revertWithNotSupportedFunction() public {
    vm.prank(user);
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_NotSupportedFunction.selector);
    governor.castVoteWithReason(proposalId, SUPPORT, REASON);
  }
}

contract GovernorWorldID_Unit_CastVoteBySig is Base {
  /**
   * @notice Check that the function is disabled and reverts
   */
  function test_revertWithNotSupportedFunction() public {
    vm.prank(signer.addr);
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_NotSupportedFunction.selector);
    governor.castVoteBySig(proposalId, SUPPORT, signer.addr, signature);
  }
}

// contract GovernorWorldID_Unit_CheckVoteValidity is Base {

//   /**
//      * @notice Test that the function reverts if the nullifier is already used
//      */
//     function test_revertIfNullifierAlreadyUsed(
//       uint256 _currentRoot,
//       uint256 _root,
//       uint256 _nullifierHash,
//       uint256[8] memory _proof
//     ) public {
//     }

//     /**
//      * @notice Test that the function reverts if the root is outdated
//      */
//     function test_revertIfOutdatedRoot(
//       uint256 _currentRoot,
//       uint256 _root,
//       uint256 _nullifierHash,
//       uint256[8] memory _proof
//     ) public {
//       // vm.assume(_currentRoot != 0);
//       // vm.assume(_currentRoot != _root);

//       // // Set the current root
//       // vm.mockCall(address(worldIDIdentityManager), abi.encodeWithSelector(IWorldIDIdentityManager.latestRoot.selector), abi.encode(_currentRoot));

//       // // Try to cast a vote with an outdated root
//       // bytes memory _params = abi.encode(_root, _nullifierHash, _proof);
//       // vm.expectRevert(IGovernorWorldID.GovernorWorldID_OutdatedRoot.selector);
//       // vm.prank(user);
//       // IMockGovernorWorldIdForTest(address(governor)).forTest_isHuman(user, proposalId, _params);
//     }

//   /**
//    * @notice Test that the function calls the verifyProof function from the WorldID contract
//    */
//   function test_callVerifyProof(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
//     bytes memory _params = _mockWorlIDCalls(worldIDIdentityManager, _root, _nullifierHash, _proof);

//     // Cast the vote
//     vm.prank(user);
//     IMockGovernorWorldIdForTest(address(governor)).forTest_checkVoteValidity(SUPPORT, proposalId, _params);
//   }
// }

contract GovernorWorldID_Unit_CastVote_WithParams is Base {
  /**
   * @notice Check that the function stores the nullifier as used
   */
  function test_nullifierIsStored(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    bytes memory _params =
      _mockWorlIDCalls(worldIDIdentityManager, _root, _nullifierHash, _proof, ROOT_EXPIRATION_THRESHOLD, rootTimestamp);

    // Cast the vote
    vm.prank(user);
    IMockGovernorWorldIdForTest(address(governor)).forTest_castVote(proposalId, user, SUPPORT, REASON, _params);

    assertTrue(governor.nullifierHashes(_nullifierHash));
  }

  /**
   * @notice Check that the function works as expected
   */
  function test_castVoteWithReasonAndParams(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    bytes memory _params =
      _mockWorlIDCalls(worldIDIdentityManager, _root, _nullifierHash, _proof, ROOT_EXPIRATION_THRESHOLD, rootTimestamp);

    vm.expectEmit(true, true, true, true);
    emit IGovernor.VoteCastWithParams(user, proposalId, SUPPORT, WEIGHT, REASON, _params);

    // Cast the vote
    vm.prank(user);
    IMockGovernorWorldIdForTest(address(governor)).forTest_castVote(proposalId, user, SUPPORT, REASON, _params);
  }
}

contract GovernorWorldID_Unit_CastVoteWithReasonAndParams is Base {
  /**
   * @notice Check that the function works as expected
   */
  function test_castVoteWithReasonAndParams(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    bytes memory _params =
      _mockWorlIDCalls(worldIDIdentityManager, _root, _nullifierHash, _proof, ROOT_EXPIRATION_THRESHOLD, rootTimestamp);

    vm.expectEmit(true, true, true, true);
    emit IGovernor.VoteCastWithParams(user, proposalId, SUPPORT, WEIGHT, REASON, _params);

    // Cast the vote
    vm.prank(user);
    governor.castVoteWithReasonAndParams(proposalId, SUPPORT, REASON, _params);
  }
}

contract GovernorWorldID_Unit_CastVoteWithReasonAndParamsBySig is Base {
  /**
   * @notice Check that the function works as expected
   */
  function test_castVoteWithReasonAndParamsBySig(
    uint256 _root,
    uint256 _nullifierHash,
    uint256[8] memory _proof
  ) public {
    bytes memory _params =
      _mockWorlIDCalls(worldIDIdentityManager, _root, _nullifierHash, _proof, ROOT_EXPIRATION_THRESHOLD, rootTimestamp);

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

contract GovernorWorldID_Unit_SetRootExpirationThreshold is Base {
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
  function test_revertIfBiggerThanResetGracePeriod() public {
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_InvalidRootExpirationThreshold.selector);
    vm.prank(address(governor));
    governor.setRootExpirationThreshold(RESET_GRACE_PERIOD + 1);
  }

  /**
   * @notice Check that the function reverts if the new root expiration threshold is bigger than the reset grace period
   */
  function test_revertIfBiggerThanRootHistoryExpiry() public {
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_InvalidRootExpirationThreshold.selector);
    vm.prank(address(governor));
    governor.setRootExpirationThreshold(ROOT_HISTORY_EXPIRY + 1);
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

contract GovernorWorldID_Unit_SetResetGracePeriod is Base {
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

contract GovernorWorldID_Unit_SetVotingPeriod is Base {
  /**
   * @notice Check that the function reverts if invalid voting period
   */
  function test_revertIfInvalidVotingPeriod(uint256 _votingPeriod) public {}

  /**
   * @notice Check that the function works as expected
   */
  function test_setVotingPeriod(uint256 _votingPeriod) public {}
}

contract GovernorWorldID_Unit_VotingDelay is Base {
  /**
   * @notice Check that the function works as expected
   */
  function test_VotingDelay() public {}
}

contract GovernorWorldID_Unit_VotingPeriod is Base {
  /**
   * @notice Check that the function works as expected
   */
  function test_VotingPeriod() public {}
}

contract GovernorWorldID_Unit_ProposalThreshold is Base {
  /**
   * @notice Check that the function works as expected
   */
  function test_ProposalThreshold() public {}
}
