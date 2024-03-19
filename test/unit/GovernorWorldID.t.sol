// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {MockERC20Votes} from '../mocks/MockERC20Votes.sol';
import {IMockGovernorWorldIdForTest, MockGovernorWorldId} from '../mocks/MockGovernorWorldId.sol';
import {GovernorSigUtils} from '../utils/GovernorSigUtils.sol';
import {UnitUtils} from './UnitUtils.sol';
import {Test, Vm} from 'forge-std/Test.sol';
import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';
import {IWorldID} from 'interfaces/IWorldID.sol';
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
  string public constant APP_ID = 'appId';
  string public constant ACTION_ID = 'actionId';

  IERC20 public token;
  IGovernorWorldID public governor;
  IWorldIDRouter public worldIDRouter;
  IWorldID public worldID;
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

    // Deploy mock worldID
    worldID = IWorldID(makeAddr('worldID'));
    vm.etch(address(worldID), new bytes(0x1));

    // Mock the routeFor function
    vm.mockCall(
      address(worldIDRouter),
      abi.encodeWithSelector(IWorldIDRouter.routeFor.selector, GROUP_ID),
      abi.encode(address(worldID))
    );

    // Deploy governor
    governor = new MockGovernorWorldId(GROUP_ID, worldIDRouter, APP_ID, ACTION_ID, IVotes(address(token)));

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

contract GovernorWorldId_Unit_WORLD_ID is Base {
  /**
   * @notice Test that the function returns the WorldID instance
   */
  function test_returnWorldIDInstance() public {
    assertEq(address(governor.WORLD_ID()), address(worldID));
  }
}

contract GovernorWorldId_Unit_EXTERNAL_NULLIFIER is Base {
  using ByteHasher for bytes;

  /**
   * @notice Test that the function returns the EXTERNAL_NULLIFIER
   */
  function test_returnEXTERNAL_NULLIFIER() public {
    assertEq(
      governor.EXTERNAL_NULLIFIER(), abi.encodePacked(abi.encodePacked(APP_ID).hashToField(), ACTION_ID).hashToField()
    );
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

contract GovernorWorldID_Unit_IsHuman is Base {
  /**
   * @notice Test that the function returns if the root is already verified
   */
  function test_returnIfAlreadyVerifiedOnLatestRoot(
    uint256 _root,
    uint256 _nullifierHash,
    uint256[8] memory _proof
  ) public {
    vm.mockCall(address(worldID), abi.encodeWithSelector(IWorldID.latestRoot.selector), abi.encode(_root));
    IMockGovernorWorldIdForTest(address(governor)).forTest_setLatestRootPerVoter(user, _root);
    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);

    // Since the function returns, no call is expected to `verifyProof`
    uint64 _methodCallsCounter = 0;
    vm.expectCall(address(worldID), abi.encodeWithSelector(IWorldID.verifyProof.selector), _methodCallsCounter);

    vm.prank(user);
    IMockGovernorWorldIdForTest(address(governor)).forTest_isHuman(user, proposalId, _params);
  }

  /**
   * @notice Test that the function reverts if no proof data is provided
   */
  function test_revertIfNoProofData(uint256 _root) public {
    vm.assume(_root != 0);
    vm.mockCall(address(worldID), abi.encodeWithSelector(IWorldID.latestRoot.selector), abi.encode(_root));

    vm.expectRevert(IGovernorWorldID.GovernorWorldID_NoProofData.selector);
    vm.prank(user);
    bytes memory _emptyProofParams = '';
    IMockGovernorWorldIdForTest(address(governor)).forTest_isHuman(user, proposalId, _emptyProofParams);
  }

  /**
   * @notice Test that the function reverts if the root is outdated
   */
  function test_revertIfOutdatedRoot(
    uint256 _currentRoot,
    uint256 _root,
    uint256 _nullifierHash,
    uint256[8] memory _proof
  ) public {
    vm.assume(_currentRoot != 0);
    vm.assume(_currentRoot != _root);

    // Set the current root
    vm.mockCall(address(worldID), abi.encodeWithSelector(IWorldID.latestRoot.selector), abi.encode(_currentRoot));

    // Try to cast a vote with an outdated root
    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_OutdatedRoot.selector);
    vm.prank(user);
    IMockGovernorWorldIdForTest(address(governor)).forTest_isHuman(user, proposalId, _params);
  }

  /**
   * @notice Test that the function calls the verifyProof function from the WorldID contract
   */
  function test_callVerifyProof(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    bytes memory _params = _mockWorlIDCalls(worldID, _root, _nullifierHash, _proof);

    // Cast the vote
    vm.prank(user);
    IMockGovernorWorldIdForTest(address(governor)).forTest_isHuman(user, proposalId, _params);
  }

  /**
   * @notice Test that the latest root is stored
   */
  function test_storeLatestRootPerVoter(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    bytes memory _params = _mockWorlIDCalls(worldID, _root, _nullifierHash, _proof);

    // Cast the vote
    vm.prank(user);
    IMockGovernorWorldIdForTest(address(governor)).forTest_isHuman(user, proposalId, _params);

    // Check that the latest root is stored
    uint256 _latestRootStored = governor.latestRootPerVoter(user);
    assertEq(_latestRootStored, _root);
  }
}

contract GovernorWorldID_Unit_CastVote_WithParams is Base {
  /**
   * @notice Check that the function works as expected
   */
  function test_castVoteWithReasonAndParams(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    bytes memory _params = _mockWorlIDCalls(worldID, _root, _nullifierHash, _proof);

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
    bytes memory _params = _mockWorlIDCalls(worldID, _root, _nullifierHash, _proof);

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
    bytes memory _params = _mockWorlIDCalls(worldID, _root, _nullifierHash, _proof);

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
