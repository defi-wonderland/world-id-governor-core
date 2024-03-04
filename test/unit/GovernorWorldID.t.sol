// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Test, Vm} from 'forge-std/Test.sol';
import {IERC20} from 'open-zeppelin/token/ERC20/IERC20.sol';
import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';
import {MockERC20Votes} from '../mocks/MockERC20Votes.sol';
import {MockGovernorWorldId} from '../mocks/MockGovernorWorldId.sol';
import {IWorldID} from 'interfaces/IWorldID.sol';
import {IVotes} from 'open-zeppelin/governance/utils/IVotes.sol';
import {MessageHashUtils} from 'open-zeppelin/utils/cryptography/MessageHashUtils.sol';

contract GovernorSigUtils {
  using MessageHashUtils for bytes32;

  bytes32 public constant TYPE_HASH =
    keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');
  bytes32 public immutable DOMAIN_SEPARATOR;

  constructor(address _governorAddress) {
    bytes32 _hashedName = keccak256(bytes('Governor'));
    bytes32 _hashedVersion = keccak256(bytes('1'));
    DOMAIN_SEPARATOR = keccak256(abi.encode(TYPE_HASH, _hashedName, _hashedVersion, block.chainid, _governorAddress));
  }

  function getHash(uint256 _proposalId, uint8 _support, address _voter) public view returns (bytes32 _hash) {
    bytes32 _ballotTypehash = keccak256('Ballot(uint256 proposalId,uint8 support,address voter,uint256 nonce)');
    _hash = _hashTypedDataV4(keccak256(abi.encode(_ballotTypehash, _proposalId, _support, _voter, 0))); // NOTE: hardcoding the nonce to 0
  }

  function getHash(
    uint256 _proposalId,
    uint8 _support,
    address _voter,
    string memory _reason,
    bytes memory _params
  ) public view returns (bytes32 _hash) {
    bytes32 _extendedBallotTypehash = keccak256(
      'ExtendedBallot(uint256 proposalId,uint8 support,address voter,uint256 nonce,string reason,bytes params)'
    );
    _hash = _hashTypedDataV4(
      keccak256(
        abi.encode(
          _extendedBallotTypehash, _proposalId, _support, _voter, 0, keccak256(bytes(_reason)), keccak256(_params)
        )
      )
    ); // NOTE: hardcoding the nonce to 0
  }

  function _hashTypedDataV4(bytes32 _structHash) internal view virtual returns (bytes32) {
    return MessageHashUtils.toTypedDataHash(DOMAIN_SEPARATOR, _structHash);
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
  uint8 public support = 0;

  function setUp() public virtual {
    vm.clearMockedCalls();

    signer = vm.createWallet('voter');

    // Deploy token
    token = new MockERC20Votes();

    // Deploy mock worldID
    worldID = IWorldID(makeAddr('worldID'));
    vm.etch(address(worldID), new bytes(0x1));

    // Deploy governor
    governor = new MockGovernorWorldId(worldID, 'appId', 'actionId', IVotes(address(token)));

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

contract UnitGovernorWorldIDCastVoteDisabled is Base {
  function testCastVoteShouldBeDisabled() public {
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_NotSupportedFunction.selector);
    governor.castVote(proposalId, support);
  }

  function testCastVoteWithReasonShouldBeDisabled() public {
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_NotSupportedFunction.selector);
    governor.castVoteWithReason(proposalId, support, '');
  }

  function testCastVoteBySigShouldBeDisabled() public {
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_NotSupportedFunction.selector);
    governor.castVoteBySig(proposalId, support, signer.addr, signature);
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
    governor.castVoteWithReasonAndParams(proposalId, support, '', _params);
  }

  function testCastVoteWithReasonAndParamsBySigShouldWork(
    uint256 _root,
    uint256 _nullifierHash,
    uint256[8] memory _proof
  ) public {
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

  function testCastVoteWithReasonAndParamsShouldRevertIfNullifierAlreadyUsed(
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

  function testCastVoteWithReasonAndParamsBySigShouldRevertIfNullifierAlreadyUsed(
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
    governor.castVoteWithReasonAndParams(proposalId, support, '', _params);
  }

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

    // Sign
    bytes32 _hash = sigUtils.getHash(proposalId, support, signer.addr, '', _params);
    (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(signer.privateKey, _hash);
    bytes memory extendedBallotSignature = abi.encodePacked(_r, _s, _v);

    // Cast the vote
    vm.expectRevert(); // TODO: be more explicit
    governor.castVoteWithReasonAndParamsBySig(proposalId, support, signer.addr, '', _params, extendedBallotSignature);
  }
}
