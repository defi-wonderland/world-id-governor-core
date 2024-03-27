// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IMockDemocraticGovernanceForTest, MockDemocraticGovernance} from '../mocks/MockDemocraticGovernance.sol';
import {MockERC20Votes} from '../mocks/MockERC20Votes.sol';
import {GovernorSigUtils} from '../utils/GovernorSigUtils.sol';
import {UnitUtils} from './UnitUtils.sol';
import {Test, Vm} from 'forge-std/Test.sol';
import {IDemocraticGovernance} from 'interfaces/IDemocraticGovernance.sol';
import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';
import {IWorldIDIdentityManager} from 'interfaces/IWorldIDIdentityManager.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {ByteHasher} from 'libraries/ByteHasher.sol';
import {Ownable} from 'open-zeppelin/access/Ownable.sol';
import {IGovernor} from 'open-zeppelin/governance/IGovernor.sol';
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
  uint256 public constant INITIAL_PROPOSAL_THRESHOLD = 1;

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

    // Deploy governor
    vm.prank(owner);
    governor = IGovernorWorldID(
      new MockDemocraticGovernance(GROUP_ID, worldIDRouter, APP_ID, QUORUM, INITIAL_VOTING_DELAY, INITIAL_VOTING_PERIOD, INITIAL_PROPOSAL_THRESHOLD)
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

contract DemocraticGovernance_Unit_WORLD_ID_ROUTER is Base {
  /**
   * @notice Test that the function returns the worldIDRouter instance
   */
  function test_returnWorldIDInstance() public {
    assertEq(address(governor.WORLD_ID_ROUTER()), address(worldIDRouter));
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

contract DemocraticGovernance_Unit_IsHuman is Base {
  //   /**
  //    * @notice Test that the function returns if the root is already verified
  //    */
  //   function test_returnIfAlreadyVerifiedOnLatestRoot(
  //     uint256 _root,
  //     uint256 _nullifierHash,
  //     uint256[8] memory _proof
  //   ) public {
  //     vm.mockCall(address(worldIDIdentityManager), abi.encodeWithSelector(IWorldIDIdentityManager.latestRoot.selector), abi.encode(_root));
  //     IMockDemocraticGovernanceForTest(address(governor)).forTest_setLatestRootPerVoter(user, _root);
  //     bytes memory _params = abi.encode(_root, _nullifierHash, _proof);

  //     // Since the function returns, no call is expected to `verifyProof`
  //     uint64 _methodCallsCounter = 0;
  //     vm.expectCall(address(worldIDIdentityManager), abi.encodeWithSelector(IWorldIDIdentityManager.verifyProof.selector), _methodCallsCounter);

  //     vm.prank(user);
  //     IMockDemocraticGovernanceForTest(address(governor)).forTest_isHuman(user, proposalId, _params);
  //   }

  //   /**
  //    * @notice Test that the function reverts if no proof data is provided
  //    */
  //   function test_revertIfNoProofData(uint256 _root) public {
  //     vm.assume(_root != 0);
  //     vm.mockCall(address(worldIDIdentityManager), abi.encodeWithSelector(IWorldIDIdentityManager.latestRoot.selector), abi.encode(_root));

  //     vm.expectRevert(IGovernorWorldID.GovernorWorldID_NoProofData.selector);
  //     vm.prank(user);
  //     bytes memory _emptyProofParams = '';
  //     IMockDemocraticGovernanceForTest(address(governor)).forTest_isHuman(user, proposalId, _emptyProofParams);
  //   }

  //   /**
  //    * @notice Test that the function reverts if the root is outdated
  //    */
  //   function test_revertIfOutdatedRoot(
  //     uint256 _currentRoot,
  //     uint256 _root,
  //     uint256 _nullifierHash,
  //     uint256[8] memory _proof
  //   ) public {
  //     vm.assume(_currentRoot != 0);
  //     vm.assume(_currentRoot != _root);

  //     // Set the current root
  //     vm.mockCall(address(worldIDIdentityManager), abi.encodeWithSelector(IWorldIDIdentityManager.latestRoot.selector), abi.encode(_currentRoot));

  //     // Try to cast a vote with an outdated root
  //     bytes memory _params = abi.encode(_root, _nullifierHash, _proof);
  //     vm.expectRevert(IGovernorWorldID.GovernorWorldID_OutdatedRoot.selector);
  //     vm.prank(user);
  //     IMockDemocraticGovernanceForTest(address(governor)).forTest_isHuman(user, proposalId, _params);
  //   }

  /**
   * @notice Test that the function calls the verifyProof function from the WorldID contract
   */
  function test_callVerifyProof(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    bytes memory _params = _mockWorlIDCalls(worldIDIdentityManager, _root, _nullifierHash, _proof);

    // Cast the vote
    vm.prank(user);
    IMockDemocraticGovernanceForTest(address(governor)).forTest_validateUniqueVote(SUPPORT, proposalId, _params);
  }

  //   /**
  //    * @notice Test that the latest root is stored
  //    */
  //   function test_storeLatestRootPerVoter(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
  //     bytes memory _params = _mockWorlIDCalls(worldIDIdentityManager, _root, _nullifierHash, _proof);

  //     // Cast the vote
  //     vm.prank(user);
  //     IMockDemocraticGovernanceForTest(address(governor)).forTest_isHuman(user, proposalId, _params);

  //     // Check that the latest root is stored
  //     uint256 _latestRootStored = governor.latestRootPerVoter(user);
  //     assertEq(_latestRootStored, _root);
  //   }
}

contract DemocraticGovernance_Unit_CastVote_WithParams is Base {
  /**
   * @notice Check that the function works as expected
   */
  function test_castVoteWithReasonAndParams(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    bytes memory _params = _mockWorlIDCalls(worldIDIdentityManager, _root, _nullifierHash, _proof);

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
    bytes memory _params = _mockWorlIDCalls(worldIDIdentityManager, _root, _nullifierHash, _proof);

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
    bytes memory _params = _mockWorlIDCalls(worldIDIdentityManager, _root, _nullifierHash, _proof);

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
   * @notice Check that only the owner can set the quorum
   */
  function test_revertWithNotOwner(uint256 _quorum) public {
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
    vm.prank(user);
    IDemocraticGovernance(address(governor)).setQuorum(_quorum);
  }

  /**
   * @notice Check that the function works as expected
   */
  function test_setQuorum(uint256 _quorum) public {
    vm.prank(owner);
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

    vm.prank(owner);
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

contract DemocraticGovernance_Unit_VotingDelay is Base {
  /**
   * @notice Test that the function returns the voting delay
   */
  function test_returnVotingDelay() public {
    uint256 _delay = 1 days;
    assertEq(governor.votingDelay(), _delay);
  }
}

contract DemocraticGovernance_Unit_VotingPeriod is Base {
  /**
   * @notice Test that the function returns the voting period
   */
  function test_returnVotingPeriod() public {
    uint256 _duration = 1 weeks;
    assertEq(governor.votingPeriod(), _duration);
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
