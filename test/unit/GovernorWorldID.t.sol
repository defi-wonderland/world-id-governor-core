// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test} from 'forge-std/Test.sol';
import {IERC20} from 'open-zeppelin/token/ERC20/IERC20.sol';
import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';
import {MockERC20Votes} from '../mocks/MockERC20Votes.sol';
import {MockGovernorWorldId} from '../mocks/MockGovernorWorldId.sol';
import {IWorldID} from 'interfaces/IWorldID.sol';
import {IVotes} from 'open-zeppelin/governance/utils/IVotes.sol';

abstract contract Base is Test {
  IERC20 public token;
  IGovernorWorldID public governor;
  IWorldID public worldID;
  uint256 public proposalId;

  function setUp() public virtual {
    vm.clearMockedCalls();

    // Deploy token
    token = new MockERC20Votes();

    // Deploy mock worldID
    worldID = IWorldID(makeAddr('worldID'));
    vm.etch(address(worldID), new bytes(0x1));

    // Deploy governor
    governor = new MockGovernorWorldId(worldID, 'appId', 'actionId', IVotes(address(token)));

    // Create proposal
    proposalId = governor.propose(new address[](1), new uint256[](1), new bytes[](1), '0x');

    // Advance time assuming 1 block == 1 second (this will make the proposal active)
    vm.warp(block.timestamp + governor.votingDelay() + 1);
    vm.roll(block.number + governor.votingDelay() + 1);
  }
}

contract UnitGovernorWorldIDCastVoteDisabled is Base {
  function testCastVoteShouldBeDisabled() public {
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_NotSupportedFunction.selector);
    governor.castVote(0, 0);
  }

  function testCastVoteWithReasonShouldBeDisabled() public {
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_NotSupportedFunction.selector);
    governor.castVoteWithReason(0, 0, '');
  }

  // TODO: fix this
  function testCastVoteBySigWithReasonShouldBeDisabled() public {
    // vm.expectRevert(IGovernorWorldID.GovernorWorldID_NotSupportedFunction.selector);
    // governor.castVoteBySig(0, 0, address(0), "");
  }
}

contract UnitGovernorWorldIDCastVoteWithParams is Base {
  function testCastVoteWithReasonAndParamsShouldWork(
    uint256 _root,
    uint256 _nullifierHash,
    uint256[8] memory _proof
  ) public {
    // Encode the parameters
    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);

    // Mock
    vm.mockCall(address(worldID), abi.encodeWithSelector(IWorldID.verifyProof.selector), abi.encode(0));

    // Cast the vote
    governor.castVoteWithReasonAndParams(proposalId, 0, '', _params);
  }

  // TODO: fix this
  function testCastVoteWithReasonAndParamsBySigShouldWork(
    uint256 _root,
    uint256 _nullifierHash,
    uint256[8] memory _proof
  ) public {
    // // Encode the parameters
    // bytes memory _params = abi.encode(_root, _nullifierHash, _proof);

    // // Mock
    // vm.mockCall(address(worldID), abi.encodeWithSelector(IWorldID.verifyProof.selector), abi.encode(0));

    // // Cast the vote
    // governor.castVoteWithReasonAndParamsBySig(proposalId, 0, address(this), '', _params, '');
  }

  function testCastVoteWithReasonAndParamsShouldRevertIfNullifierAlreadyUsed(
    uint256 _root,
    uint256 _nullifierHash,
    uint256[8] memory _proof
  ) public {
    // Cast a vote
    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);
    vm.mockCall(address(worldID), abi.encodeWithSelector(IWorldID.verifyProof.selector), abi.encode(0));
    governor.castVoteWithReasonAndParams(proposalId, 0, '', _params);

    // Try to cast another vote with same nullifier
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_InvalidNullifier.selector);
    governor.castVoteWithReasonAndParams(proposalId, 0, '', _params);
  }

  // TODO: fix this
  function testCastVoteWithReasonAndParamsBySigShouldRevertIfNullifierAlreadyUsed(
    uint256 _root,
    uint256 _nullifierHash,
    uint256[8] memory _proof,
    bytes memory _signature
  ) public {
    // // Cast a vote
    // bytes memory _params = abi.encode(_root, _nullifierHash, _proof);
    // vm.mockCall(address(worldID), abi.encodeWithSelector(IWorldID.verifyProof.selector), abi.encode(0));
    // governor.castVoteWithReasonAndParams(proposalId, 0, '', _params);

    // // Try to cast another vote with same nullifier
    // vm.expectRevert(IGovernorWorldID.GovernorWorldID_InvalidNullifier.selector);
    // governor.castVoteWithReasonAndParamsBySig(proposalId, 0, address(this), '', _params, _signature);
  }

  function testCastVoteWithReasonAndParamsShouldRevertIfProofIsNotValid(
    uint256 _root,
    uint256 _nullifierHash,
    uint256[8] memory _proof
  ) public {
    // Encode the parameters
    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);

    // Mock
    vm.mockCallRevert(
      address(worldID), abi.encodeWithSelector(IWorldID.verifyProof.selector), abi.encode('Invalid proof')
    );

    // Cast the vote
    vm.expectRevert(); // TODO: be more explicit
    governor.castVoteWithReasonAndParams(proposalId, 0, '', _params);
  }

  // TODO: fix this
  function testCastVoteWithReasonAndParamsBySigShouldRevertIfProofIsNotValid(
    uint256 _root,
    uint256 _nullifierHash,
    uint256[8] memory _proof,
    bytes memory _signature
  ) public {
    //   // Encode the parameters
    // bytes memory _params = abi.encode(_root, _nullifierHash, _proof);

    // // Mock
    // vm.mockCallRevert(
    //   address(worldID), abi.encodeWithSelector(IWorldID.verifyProof.selector), abi.encode('Invalid proof')
    // );

    // // Cast the vote
    // vm.expectRevert(); // TODO: be more explicit
    // governor.castVoteWithReasonAndParamsBySig(proposalId, 0, address(this), '', _params, _signature);
  }
}
