// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {MockERC20Votes} from '../mocks/MockERC20Votes.sol';
import {MockGovernorWorldId} from '../mocks/MockGovernorWorldId.sol';
import {GovernorSigUtils} from '../utils/GovernorSigUtils.sol';
import {Test, Vm} from 'forge-std/Test.sol';
import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';
import {IWorldID} from 'interfaces/IWorldID.sol';
import {IVotes} from 'open-zeppelin/governance/utils/IVotes.sol';
import {IERC20} from 'open-zeppelin/token/ERC20/IERC20.sol';

abstract contract Base is Test {
  IERC20 public token;
  IGovernorWorldID public governor;
  IWorldID public worldID;
  GovernorSigUtils public sigUtils;

  uint256 public proposalId;
  bytes public signature;

  Vm.Wallet public signer;
  uint8 public support = 0;
  uint256 public groupId = 1;

  function setUp() public virtual {
    vm.clearMockedCalls();

    signer = vm.createWallet('voter');

    // Deploy token
    token = new MockERC20Votes();

    // Deploy mock worldID
    worldID = IWorldID(makeAddr('worldID'));
    vm.etch(address(worldID), new bytes(0x1));

    // Deploy governor
    governor = new MockGovernorWorldId(groupId, worldID, 'appId', 'actionId', IVotes(address(token)));

    // Deploy sigUtils
    sigUtils = new GovernorSigUtils(address(governor));

    // Create proposal
    proposalId = governor.propose(new address[](1), new uint256[](1), new bytes[](1), '0x');

    // Advance time assuming 1 block == 1 second (this will make the proposal active)
    vm.warp(block.timestamp + governor.votingDelay() + 1);
    vm.roll(block.number + governor.votingDelay() + 1);

    // Generate signature
    bytes32 _hash = sigUtils.getHash(proposalId, support, signer.addr);
    (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(signer.privateKey, _hash);
    signature = abi.encodePacked(_r, _s, _v);
  }
}

contract GovernorWorldID_Unit_CastVote is Base {
  /**
   * @notice Check that the function is disabled and reverts
   */
  function test_shouldBeDisabled() public {
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_NotSupportedFunction.selector);
    governor.castVote(proposalId, support);
  }
}

contract GovernorWorldID_Unit_CastVoteWithReason is Base {
  /**
   * @notice Check that the function is disabled and reverts
   */
  function test_shouldBeDisabled() public {
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_NotSupportedFunction.selector);
    governor.castVoteWithReason(proposalId, support, '');
  }
}

contract GovernorWorldID_Unit_CastVoteBySig is Base {
  /**
   * @notice Check that the function is disabled and reverts
   */
  function test_shouldBeDisabled() public {
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_NotSupportedFunction.selector);
    governor.castVoteBySig(proposalId, support, signer.addr, signature);
  }
}

contract GovernorWorldID_Unit_CastVoteWithReasonAndParams is Base {
  /**
   * @notice Check that the function works as expected
   */
  function test_shouldWork(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    // Encode the parameters
    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);

    // Mock
    vm.mockCall(address(worldID), abi.encodeWithSelector(IWorldID.verifyProof.selector), abi.encode(0));

    // Cast the vote
    governor.castVoteWithReasonAndParams(proposalId, support, '', _params);
  }

  /**
   * @notice Test that the function reverts if the nullifier has already been used
   */
  function test_shouldRevertIfNullifierAlreadyUsed(
    uint256 _root,
    uint256 _nullifierHash,
    uint256[8] memory _proof
  ) public {
    // Cast a vote
    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);
    vm.mockCall(address(worldID), abi.encodeWithSelector(IWorldID.verifyProof.selector), abi.encode(0));
    governor.castVoteWithReasonAndParams(proposalId, support, '', _params);

    // Try to cast another vote with same nullifier
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_InvalidNullifier.selector);
    governor.castVoteWithReasonAndParams(proposalId, support, '', _params);
  }

  /**
   * @notice Test that the function reverts if the proof is not valid
   */
  function test_shouldRevertIfProofIsNotValid(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    // Encode the parameters
    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);

    // Mock
    vm.mockCallRevert(
      address(worldID), abi.encodeWithSelector(IWorldID.verifyProof.selector), abi.encode('Invalid proof')
    );

    // Cast the vote
    vm.expectRevert(); // TODO: be more explicit
    governor.castVoteWithReasonAndParams(proposalId, support, '', _params);
  }
}

contract GovernorWorldID_Unit_CastVoteWithReasonAndParamsBySig is Base {
  /**
   * @notice Check that the function works as expected
   */
  function test_shouldWork(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    // Encode the parameters
    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);

    // Mock
    vm.mockCall(address(worldID), abi.encodeWithSelector(IWorldID.verifyProof.selector), abi.encode(0));

    // Sign
    bytes32 _hash = sigUtils.getHash(proposalId, support, signer.addr, '', _params);
    (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(signer.privateKey, _hash);
    bytes memory extendedBallotSignature = abi.encodePacked(_r, _s, _v);

    // Cast the vote
    governor.castVoteWithReasonAndParamsBySig(proposalId, support, signer.addr, '', _params, extendedBallotSignature);
  }

  /**
   * @notice Test that the function reverts if the nullifier has already been used
   */
  function test_shouldRevertIfNullifierAlreadyUsed(
    uint256 _root,
    uint256 _nullifierHash,
    uint256[8] memory _proof
  ) public {
    // Cast a vote
    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);
    vm.mockCall(address(worldID), abi.encodeWithSelector(IWorldID.verifyProof.selector), abi.encode(0));
    governor.castVoteWithReasonAndParams(proposalId, support, '', _params);

    // Sign
    bytes32 _hash = sigUtils.getHash(proposalId, support, signer.addr, '', _params);
    (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(signer.privateKey, _hash);
    bytes memory extendedBallotSignature = abi.encodePacked(_r, _s, _v);

    // Try to cast another vote with same nullifier
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_InvalidNullifier.selector);
    governor.castVoteWithReasonAndParamsBySig(proposalId, support, signer.addr, '', _params, extendedBallotSignature);
  }

  /**
   * @notice Test that the function reverts if the proof is not valid
   */
  function test_shouldRevertIfProofIsNotValid(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    // Encode the parameters
    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);

    // Mock
    vm.mockCallRevert(
      address(worldID), abi.encodeWithSelector(IWorldID.verifyProof.selector), abi.encode('Invalid proof')
    );

    // Sign
    bytes32 _hash = sigUtils.getHash(proposalId, support, signer.addr, '', _params);
    (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(signer.privateKey, _hash);
    bytes memory extendedBallotSignature = abi.encodePacked(_r, _s, _v);

    // Cast the vote
    vm.expectRevert(); // TODO: be more explicit
    governor.castVoteWithReasonAndParamsBySig(proposalId, support, signer.addr, '', _params, extendedBallotSignature);
  }
}
