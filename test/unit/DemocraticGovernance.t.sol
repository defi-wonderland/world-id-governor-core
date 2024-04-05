// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {DemocraticGovernanceForTest} from '../forTest/DemocraticGovernanceForTest.sol';
import {ERC20VotesForTest} from '../forTest/ERC20VotesForTest.sol';
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
  string public constant APP_ID = 'appId';
  string public constant DESCRIPTION = '0xDescription';
  uint48 public constant INITIAL_VOTING_DELAY = 1 days;
  uint32 public constant INITIAL_VOTING_PERIOD = 3 days;
  uint256 public constant INITIAL_PROPOSAL_THRESHOLD = 0;
  uint256 public constant ROOT_EXPIRATION_THRESHOLD = 0;
  uint256 public constant RESET_GRACE_PERIOD = 13 days + 22 hours;
  uint256 public constant ROOT_HISTORY_EXPIRY = 1 weeks;
  uint128 public rootTimestamp = uint128(block.timestamp - 1);

  IERC20 public token;
  DemocraticGovernanceForTest public governor;
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
    token = new ERC20VotesForTest();

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
    governor = new DemocraticGovernanceForTest(
      GROUP_ID,
      worldIDRouter,
      APP_ID,
      QUORUM,
      INITIAL_VOTING_DELAY,
      INITIAL_VOTING_PERIOD,
      INITIAL_PROPOSAL_THRESHOLD,
      ROOT_EXPIRATION_THRESHOLD
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
  using ByteHasher for bytes;

  /**
   * @notice Check that the constructor works as expected
   */
  function test_correctDeploy(uint256 _rootExpirationThreshold) public {
    vm.assume(_rootExpirationThreshold <= RESET_GRACE_PERIOD);
    vm.assume(_rootExpirationThreshold <= ROOT_HISTORY_EXPIRY);

    vm.prank(address(governor));
    governor = new DemocraticGovernanceForTest(
      GROUP_ID,
      worldIDRouter,
      APP_ID,
      QUORUM,
      INITIAL_VOTING_DELAY,
      INITIAL_VOTING_PERIOD,
      INITIAL_PROPOSAL_THRESHOLD,
      _rootExpirationThreshold
    );

    assertEq(address(governor.WORLD_ID_ROUTER()), address(worldIDRouter));
    assertEq(governor.GROUP_ID(), GROUP_ID);
    assertEq(governor.APP_ID_HASH(), abi.encodePacked(APP_ID).hashToField());
    assertEq(governor.resetGracePeriod(), RESET_GRACE_PERIOD);
    assertEq(governor.rootExpirationThreshold(), _rootExpirationThreshold);
    assertEq(governor.quorumThreshold(), QUORUM);
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

    uint256 _quorumBeforePropose = governor.quorum(block.number);

    vm.prank(owner);
    uint256 _proposalId = governor.propose(new address[](1), new uint256[](1), new bytes[](1), _description);

    uint256 _quorumFromProposal = governor.proposalsQuorumThreshold(_proposalId);
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
   * @notice Check that only the governance can set the quorum
   */
  function test_revertWithOnlyGovernance(uint256 _newQuorumThreshold) public {
    vm.expectRevert(abi.encodeWithSelector(IGovernor.GovernorOnlyExecutor.selector, user));
    vm.prank(user);
    governor.setQuorum(_newQuorumThreshold);
  }

  /**
   * @notice Check that the function works as expected
   */
  function test_setQuorum(uint256 _newQuorumThreshold) public {
    vm.prank(address(governor));
    governor.setQuorum(_newQuorumThreshold);
    uint256 _quorumFromGovernor = governor.quorum(block.number);
    assertEq(_quorumFromGovernor, _newQuorumThreshold);
  }

  /**
   * @notice Check that the function emits the QuorumSet event
   */
  function test_emitQuorumSet(uint256 _newQuorumThreshold) public {
    vm.expectEmit(true, true, true, true);
    emit IDemocraticGovernance.QuorumSet(_newQuorumThreshold);

    vm.prank(address(governor));
    governor.setQuorum(_newQuorumThreshold);
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

contract DemocraticGovernance_Unit_CLOCK_MODE is Base {
  /**
   * @notice Test that the function returns the clock mode
   */
  function test_returnClockMode() public {
    string memory _mode = 'mode=blocktimestamp&from=default';
    assertEq(governor.CLOCK_MODE(), _mode);
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

contract DemocraticGovernance_Unit_CastVote_WithParams is Base {
  /**
   * @notice Check that the function emits the VoteCastWithParams event
   */
  function test_emitEvent(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    bytes memory _params =
      _mockWorlIDCalls(SUPPORT, proposalId, _root, _nullifierHash, _proof, ROOT_EXPIRATION_THRESHOLD, rootTimestamp);

    vm.expectEmit(true, true, true, true);
    emit IGovernor.VoteCastWithParams(user, proposalId, SUPPORT, WEIGHT, REASON, _params);

    // Cast the vote
    vm.prank(user);
    governor.forTest_castVote(proposalId, user, SUPPORT, REASON, _params);
  }

  /**
   * @notice Check that the function returns the correct votingWeight
   */
  function test_returnsVotingWeight(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    bytes memory _params =
      _mockWorlIDCalls(SUPPORT, proposalId, _root, _nullifierHash, _proof, ROOT_EXPIRATION_THRESHOLD, rootTimestamp);

    // Cast the vote
    vm.prank(user);
    uint256 _votingWeight = governor.forTest_castVote(proposalId, user, SUPPORT, REASON, _params);
    assertEq(_votingWeight, WEIGHT);
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
    assertTrue(governor.forTest_quorumReached(_proposalId));
  }

  /**
   * @notice Test that the function returns if the quorum is not reached
   */
  function test_notReachedQuorum(string memory _description) public {
    vm.assume(keccak256(abi.encode(_description)) != keccak256(abi.encode((DESCRIPTION))));

    // Propose and vote
    uint256 _proposalId = _proposeAndVote(owner, _description, QUORUM - 1);

    // Check that the quorum is reached
    assertFalse(governor.forTest_quorumReached(_proposalId));
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
      governor.forTest_countVote(_proposalId, _randomVoter, SUPPORT, WEIGHT);
    }
  }
}

contract DemocraticGovernance_Unit_GetVotes is Base {
  /**
   * @notice Check that the voting weight is 1
   */
  function test_returnsOne(address _account, uint256 _timepoint, bytes memory _params) public {
    uint256 _votingWeight = governor.forTest_getVotes(_account, _timepoint, _params);
    assertEq(_votingWeight, ONE);
  }
}
