// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {MockERC20Votes} from '../mocks/MockERC20Votes.sol';
import {IMockGovernorWorldIdForTest, MockGovernorWorldId} from '../mocks/MockGovernorWorldId.sol';
import {GovernorSigUtils} from '../utils/GovernorSigUtils.sol';
import {Test, Vm} from 'forge-std/Test.sol';
import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';
import {IWorldID} from 'interfaces/IWorldID.sol';
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

    // Deploy mock worldID
    worldID = IWorldID(makeAddr('worldID'));
    vm.etch(address(worldID), new bytes(0x1));

    // Deploy governor
    string memory _appId = 'appId';
    string memory _actionId = 'actionId';
    governor = new MockGovernorWorldId(GROUP_ID, worldID, _appId, _actionId, IVotes(address(token)));

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

contract GovernorWorldID_Unit_CastVote_WithParams is Base {
  /**
   * @notice Test that the function reverts if the nullifier has already been used
   */
  function test_revertIfNullifierAlreadyUsed(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    // Set nullifier as used
    IMockGovernorWorldIdForTest(address(governor)).forTest_setNullifierHashes(_nullifierHash, true);

    // Try to cast another vote with same nullifier
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_InvalidNullifier.selector);
    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);
    vm.prank(signer.addr);
    IMockGovernorWorldIdForTest(address(governor)).forTest_castVote(proposalId, signer.addr, SUPPORT, REASON, _params);
  }

  /**
   * @notice Test that the function calls the verifyProof function from the WorldID contract
   */
  function test_callVerifyProof(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    // Encode the parameters
    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);

    // Mock
    _mockAndExpect(address(worldID), abi.encodeWithSelector(IWorldID.verifyProof.selector), abi.encode(0));

    // Cast the vote
    vm.prank(signer.addr);
    IMockGovernorWorldIdForTest(address(governor)).forTest_castVote(proposalId, signer.addr, SUPPORT, REASON, _params);
  }

  /**
   * @notice Test that the nullifier hash is stored
   */
  function test_storeNullifierHash(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    // Encode the parameters
    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);

    // Mock
    vm.mockCall(address(worldID), abi.encodeWithSelector(IWorldID.verifyProof.selector), abi.encode(0));

    // Cast the vote
    vm.prank(signer.addr);
    IMockGovernorWorldIdForTest(address(governor)).forTest_castVote(proposalId, signer.addr, SUPPORT, REASON, _params);

    // Check that the nullifier hash is stored
    bool _nullifierUsed = IMockGovernorWorldIdForTest(address(governor)).forTest_nullifierHashes(_nullifierHash);
    assertEq(_nullifierUsed, true);
  }

  /**
   * @notice Check that the function works as expected
   */
  function test_castVoteWithReasonAndParams(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
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
