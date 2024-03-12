// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {MockERC20Votes} from '../mocks/MockERC20Votes.sol';
import {IMockGovernorWorldIdForTest, MockGovernorWorldId} from '../mocks/MockGovernorWorldId.sol';
import {GovernorSigUtils} from '../utils/GovernorSigUtils.sol';
import {Test, Vm} from 'forge-std/Test.sol';
import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';
import {IWorldID} from 'interfaces/IWorldID.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {IGovernor} from 'open-zeppelin/governance/IGovernor.sol';
import {IVotes} from 'open-zeppelin/governance/utils/IVotes.sol';
import {IERC20} from 'open-zeppelin/token/ERC20/IERC20.sol';

abstract contract Base is Test {
  uint8 public constant SUPPORT = 0;
  uint256 public constant GROUP_ID = 1;
  string public constant REASON = '';
  uint256 public constant WEIGHT = 0;

  IERC20 public token;
  IGovernorWorldID public governor;
  IWorldIDRouter public worldIDRouter;
  IWorldID public worldID;
  GovernorSigUtils public sigUtils;

  uint256 public proposalId;
  bytes public signature;
  Vm.Wallet public signer;
  Vm.Wallet public random;

  function setUp() public virtual {
    vm.clearMockedCalls();

    signer = vm.createWallet('voter');
    random = vm.createWallet('random');

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
    string memory _appId = 'appId';
    string memory _actionId = 'actionId';
    governor = new MockGovernorWorldId(GROUP_ID, worldIDRouter, _appId, _actionId, IVotes(address(token)));

    // Deploy sigUtils
    sigUtils = new GovernorSigUtils(address(governor));

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

  /**
   * @notice Sets up a mock and expects a call to it*
   * @param _receiver The address to have a mock on
   * @param _calldata The calldata to mock and expect
   * @param _returned The data to return from the mocked call
   */
  function _mockAndExpect(address _receiver, bytes memory _calldata, bytes memory _returned) internal {
    vm.mockCall(_receiver, _calldata, _returned);
    vm.expectCall(_receiver, _calldata);
  }
}

contract GovernorWorldID_Unit_CastVote_WithoutParams is Base {
  /**
   * @notice Check that the function is disabled and reverts
   */
  function test_revertWithNotSupportedFunction() public {
    vm.prank(random.addr);
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_NotSupportedFunction.selector);
    governor.castVote(proposalId, SUPPORT);
  }
}

contract GovernorWorldID_Unit_CastVoteWithReason is Base {
  /**
   * @notice Check that the function is disabled and reverts
   */
  function test_revertWithNotSupportedFunction() public {
    vm.prank(random.addr);
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_NotSupportedFunction.selector);
    governor.castVoteWithReason(proposalId, SUPPORT, REASON);
  }
}

contract GovernorWorldID_Unit_CastVoteBySig is Base {
  /**
   * @notice Check that the function is disabled and reverts
   */
  function test_revertWithNotSupportedFunction() public {
    vm.prank(random.addr);
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

    IMockGovernorWorldIdForTest(address(governor)).forTest_setLatestRootPerVoter(signer.addr, _root);

    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);
    vm.expectCall(address(worldID), abi.encodeWithSelector(IWorldID.verifyProof.selector), 0);
    vm.prank(signer.addr);
    IMockGovernorWorldIdForTest(address(governor)).forTest_isHuman(signer.addr, proposalId, _params);
  }

  /**
   * @notice Test that the function reverts if no proof data is provided
   */
  function test_revertIfNoProofData(uint256 _root) public {
    vm.assume(_root != 0);
    vm.mockCall(address(worldID), abi.encodeWithSelector(IWorldID.latestRoot.selector), abi.encode(_root));

    vm.expectRevert(IGovernorWorldID.GovernorWorldID_NoProofData.selector);
    vm.prank(signer.addr);
    IMockGovernorWorldIdForTest(address(governor)).forTest_isHuman(signer.addr, proposalId, '');
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
    vm.prank(signer.addr);
    IMockGovernorWorldIdForTest(address(governor)).forTest_isHuman(signer.addr, proposalId, _params);
  }

  /**
   * @notice Test that the function calls the verifyProof function from the WorldID contract
   */
  function test_callVerifyProof(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    vm.assume(_root != 0);

    // Set the current root
    vm.mockCall(address(worldID), abi.encodeWithSelector(IWorldID.latestRoot.selector), abi.encode(_root));

    // Encode the parameters
    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);

    // Mock
    _mockAndExpect(address(worldID), abi.encodeWithSelector(IWorldID.verifyProof.selector), abi.encode(0));

    // Cast the vote
    vm.prank(signer.addr);
    IMockGovernorWorldIdForTest(address(governor)).forTest_isHuman(signer.addr, proposalId, _params);
  }

  /**
   * @notice Test that the latest root is stored
   */
  function test_storeLatestRootPerVoter(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    vm.assume(_root != 0);

    // Set the current root
    vm.mockCall(address(worldID), abi.encodeWithSelector(IWorldID.latestRoot.selector), abi.encode(_root));

    // Encode the parameters
    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);

    // Mock
    vm.mockCall(address(worldID), abi.encodeWithSelector(IWorldID.verifyProof.selector), abi.encode(0));

    // Cast the vote
    vm.prank(signer.addr);
    IMockGovernorWorldIdForTest(address(governor)).forTest_isHuman(signer.addr, proposalId, _params);

    // Check that the latest root is stored
    uint256 _latestRootStored = IMockGovernorWorldIdForTest(address(governor)).forTest_latestRootPerVoter(signer.addr);
    assertEq(_latestRootStored, _root);
  }
}

contract GovernorWorldID_Unit_CastVote_WithParams is Base {
  /**
   * @notice Check that the function works as expected
   */
  function test_castVoteWithReasonAndParams(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    vm.assume(_root != 0);

    // Set the current root
    vm.mockCall(address(worldID), abi.encodeWithSelector(IWorldID.latestRoot.selector), abi.encode(_root));

    // Encode the parameters
    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);

    // Mock
    vm.mockCall(address(worldID), abi.encodeWithSelector(IWorldID.verifyProof.selector), abi.encode(0));

    vm.expectEmit(true, true, true, true);
    emit IGovernor.VoteCastWithParams(signer.addr, proposalId, SUPPORT, WEIGHT, REASON, _params);

    // Cast the vote
    vm.prank(signer.addr);
    IMockGovernorWorldIdForTest(address(governor)).forTest_castVote(proposalId, signer.addr, SUPPORT, REASON, _params);
  }
}

contract GovernorWorldID_Unit_CastVoteWithReasonAndParams is Base {
  /**
   * @notice Check that the function works as expected
   */
  function test_castVoteWithReasonAndParams(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    vm.assume(_root != 0);

    // Set the current root
    vm.mockCall(address(worldID), abi.encodeWithSelector(IWorldID.latestRoot.selector), abi.encode(_root));

    // Encode the parameters
    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);

    // Mock
    vm.mockCall(address(worldID), abi.encodeWithSelector(IWorldID.verifyProof.selector), abi.encode(0));

    vm.expectEmit(true, true, true, true);
    emit IGovernor.VoteCastWithParams(signer.addr, proposalId, SUPPORT, WEIGHT, REASON, _params);

    // Cast the vote
    vm.prank(signer.addr);
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
    vm.assume(_root != 0);

    // Set the current root
    vm.mockCall(address(worldID), abi.encodeWithSelector(IWorldID.latestRoot.selector), abi.encode(_root));

    // Encode the parameters
    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);

    // Mock
    vm.mockCall(address(worldID), abi.encodeWithSelector(IWorldID.verifyProof.selector), abi.encode(0));

    // Sign
    bytes32 _hash = sigUtils.getHash(proposalId, SUPPORT, signer.addr, REASON, _params);
    (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(signer.privateKey, _hash);
    bytes memory _extendedBallotSignature = abi.encodePacked(_r, _s, _v);

    vm.expectEmit(true, true, true, true);
    emit IGovernor.VoteCastWithParams(signer.addr, proposalId, SUPPORT, WEIGHT, REASON, _params);

    // Cast the vote
    vm.prank(random.addr);
    governor.castVoteWithReasonAndParamsBySig(
      proposalId, SUPPORT, signer.addr, REASON, _params, _extendedBallotSignature
    );
  }
}
