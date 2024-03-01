// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test, Vm, console} from 'forge-std/Test.sol';
import {IERC20} from 'open-zeppelin/token/ERC20/IERC20.sol';
import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';
import {MockERC20Votes} from '../mocks/MockERC20Votes.sol';
import {MockGovernorWorldId} from '../mocks/MockGovernorWorldId.sol';
import {IWorldID} from 'interfaces/IWorldID.sol';
import {IVotes} from 'open-zeppelin/governance/utils/IVotes.sol';
import {EIP712} from 'open-zeppelin/utils/cryptography/EIP712.sol';
import {MessageHashUtils} from 'open-zeppelin/utils/cryptography/MessageHashUtils.sol';

contract GovernorSigUtils is EIP712 {
  using MessageHashUtils for bytes32;

  constructor() EIP712('Governor', '1') {}

  function getHash(uint256 _proposalId, uint8 _support, address _voter) public view returns (bytes32 _signedHash) {
    bytes32 _ballotTypehash = keccak256('Ballot(uint256 proposalId,uint8 support,address voter,uint256 nonce)');
    bytes32 _hash = _hashTypedDataV4(keccak256(abi.encode(_ballotTypehash, _proposalId, _support, _voter, 1)));
    _signedHash = _hash.toEthSignedMessageHash();
  }
}

abstract contract Base is Test {
  IERC20 public token;
  IGovernorWorldID public governor;
  IWorldID public worldID;
  GovernorSigUtils public sigUtils;

  uint256 public proposalId;
  bytes public signature;

  Vm.Wallet public signer;

  function setUp() public virtual {
    vm.clearMockedCalls();

    signer = vm.createWallet('voter');

    // Deploy sigUtils
    sigUtils = new GovernorSigUtils();

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

    // Generate signature
    bytes32 _hash = sigUtils.getHash(proposalId, 0, signer.addr);
    (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(signer.privateKey, _hash);
    signature = abi.encodePacked(_r, _s, _v);
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
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_NotSupportedFunction.selector);
    governor.castVoteBySig(proposalId, 0, signer.addr, signature);
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
    // Encode the parameters
    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);

    // Mock
    vm.mockCall(address(worldID), abi.encodeWithSelector(IWorldID.verifyProof.selector), abi.encode(0));

    // Cast the vote
    governor.castVoteWithReasonAndParamsBySig(proposalId, 0, signer.addr, '', _params, signature);
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
    uint256[8] memory _proof
  ) public {
    // Cast a vote
    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);
    vm.mockCall(address(worldID), abi.encodeWithSelector(IWorldID.verifyProof.selector), abi.encode(0));
    governor.castVoteWithReasonAndParams(proposalId, 0, '', _params);

    // Try to cast another vote with same nullifier
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_InvalidNullifier.selector);
    governor.castVoteWithReasonAndParamsBySig(proposalId, 0, signer.addr, '', _params, signature);
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
    governor.castVoteWithReasonAndParamsBySig(proposalId, 0, signer.addr, '', _params, signature);
  }
}
