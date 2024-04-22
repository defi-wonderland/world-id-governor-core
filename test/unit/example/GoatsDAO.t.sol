// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {GoatsDAOForTest} from '../../forTest/GoatsDAOForTest.sol';
import {UnitUtils} from '../utils/UnitUtils.sol';
import {Test} from 'forge-std/Test.sol';
import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';
import {IWorldIDIdentityManager} from 'interfaces/IWorldIDIdentityManager.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {IGoatsDAO} from 'interfaces/example/IGoatsDAO.sol';
import {ByteHasher} from 'libraries/ByteHasher.sol';
import {Ownable} from 'open-zeppelin/access/Ownable.sol';
import {IGovernor} from 'open-zeppelin/governance/IGovernor.sol';
import {Time} from 'open-zeppelin/utils/types/Time.sol';

abstract contract Base is Test, UnitUtils {
  uint8 public constant SUPPORT = 1;
  uint256 public constant GROUP_ID = _GROUP_ID;
  string public constant REASON = '';
  uint256 public constant QUORUM = 5;
  uint256 public constant ONE = 1;
  string public constant APP_ID = _APP_ID;
  string public constant DESCRIPTION = '0xDescription';
  uint48 public constant INITIAL_VOTING_DELAY = 1 days;
  uint32 public constant INITIAL_VOTING_PERIOD = 3 days;
  uint256 public constant INITIAL_PROPOSAL_THRESHOLD = 0;
  uint256 public constant ROOT_EXPIRATION_THRESHOLD = 0;
  uint256 public constant RESET_GRACE_PERIOD = 13 days + 22 hours;
  uint256 public constant ROOT_HISTORY_EXPIRY = 1 weeks;
  uint128 public rootTimestamp = uint128(block.timestamp - 1);

  GoatsDAOForTest public governor;
  IWorldIDRouter public worldIDRouter;
  IWorldIDIdentityManager public worldIDIdentityManager;

  uint256 public proposalId;
  address public user;
  address public owner;

  function setUp() public {
    user = makeAddr('user');
    owner = makeAddr('owner');

    // Deploy mock worldIDRouter
    worldIDRouter = _worldIDRouter;
    vm.etch(address(worldIDRouter), new bytes(0x1));

    // Deploy mock worldIDIdentityManager
    worldIDIdentityManager = _worldIDIdentityManager;
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
    governor = new GoatsDAOForTest(
      GROUP_ID,
      worldIDRouter,
      APP_ID,
      QUORUM,
      INITIAL_VOTING_DELAY,
      INITIAL_VOTING_PERIOD,
      INITIAL_PROPOSAL_THRESHOLD,
      ROOT_EXPIRATION_THRESHOLD
    );

    // Create proposal
    vm.prank(owner);
    proposalId = governor.propose(new address[](1), new uint256[](1), new bytes[](1), DESCRIPTION);

    // Advance time assuming 1 block == 1 second (this will make the proposal active)
    vm.warp(block.timestamp + governor.votingDelay() + 1);
    vm.roll(block.number + governor.votingDelay() + 1);
  }
}

contract GoatsDAO_Unit_SetQuorum is Base {
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
    emit IGoatsDAO.QuorumSet(QUORUM, _newQuorumThreshold);

    vm.prank(address(governor));
    governor.setQuorum(_newQuorumThreshold);
  }
}

contract GoatsDAO_Unit_Constructor is Base {
  using ByteHasher for bytes;

  /**
   * @notice Check that the constructor works as expected
   */
  function test_correctDeploy(uint256 _rootExpirationThreshold) public {
    vm.assume(_rootExpirationThreshold <= RESET_GRACE_PERIOD);
    vm.assume(_rootExpirationThreshold <= ROOT_HISTORY_EXPIRY);

    governor = new GoatsDAOForTest(
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
    assertEq(governor.appId(), APP_ID);
    assertEq(governor.resetGracePeriod(), RESET_GRACE_PERIOD);
    assertEq(governor.rootExpirationThreshold(), _rootExpirationThreshold);
    assertEq(governor.quorumThreshold(), QUORUM);
    assertEq(governor.votingDelay(), INITIAL_VOTING_DELAY);
    assertEq(governor.votingPeriod(), INITIAL_VOTING_PERIOD);
    assertEq(governor.proposalThreshold(), INITIAL_PROPOSAL_THRESHOLD);
  }
}

contract GoatsDAO_Unit_Propose is Base {
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
  function test_propose(string memory _description) public {
    vm.assume(keccak256(abi.encode(_description)) != keccak256(abi.encode((DESCRIPTION))));

    address[] memory _targets = new address[](1);
    uint256[] memory _values = new uint256[](1);
    bytes[] memory _calldatas = new bytes[](1);
    string memory _expectedDescription = string.concat(_description, governor.proposalUniquenessSalt());
    uint256 _proposalId = governor.hashProposal(_targets, _values, _calldatas, keccak256(bytes(_expectedDescription)));

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
      _expectedDescription
    );

    vm.prank(owner);
    governor.propose(_targets, _values, _calldatas, _description);
  }

  /**
   * @notice Check that the function works as expected
   */
  function test_proposalsQuorumThreshold(string memory _description) public {
    vm.assume(keccak256(abi.encode(_description)) != keccak256(abi.encode((DESCRIPTION))));

    uint256 _quorumBefore = governor.quorum(block.number);

    vm.prank(owner);
    uint256 _proposalId = governor.propose(new address[](1), new uint256[](1), new bytes[](1), _description);

    uint256 _quorumAfter = governor.proposalsQuorumThreshold(_proposalId);
    assertEq(_quorumAfter, _quorumBefore);
  }

  /**
   * @notice Check that the function returns the correct proposalId
   */
  function test_returnsCorrectProposalId(string memory _description) public {
    vm.assume(keccak256(abi.encode(_description)) != keccak256(abi.encode((DESCRIPTION))));

    address[] memory _targets = new address[](1);
    uint256[] memory _values = new uint256[](1);
    bytes[] memory _calldatas = new bytes[](1);
    string memory _expectedDescription = string.concat(_description, governor.proposalUniquenessSalt());
    bytes32 _descriptionHash = keccak256(bytes(_expectedDescription));
    uint256 _proposalId = governor.hashProposal(_targets, _values, _calldatas, _descriptionHash);

    vm.prank(owner);
    uint256 _proposalIdCreated = governor.propose(_targets, _values, _calldatas, _description);

    assertEq(_proposalId, _proposalIdCreated);
  }
}

contract GoatsDAO_Unit_Quorum is Base {
  /**
   * @notice Test that the function returns the current quorum, independently of the given argument
   */
  function test_returnQuorum(uint256 _randomNumber) public {
    assertEq(governor.quorum(_randomNumber), QUORUM);
  }
}

contract GoatsDAO_Unit_Clock is Base {
  using Time for *;

  /**
   * @notice Test that the function returns the clock
   */
  function test_returnClock() public {
    assertEq(governor.clock(), Time.timestamp());
  }
}

contract GoatsDAO_Unit_VotingDelay is Base {
  /**
   * @notice Check that the function works as expected
   */
  function test_VotingDelay() public {
    assertEq(governor.votingDelay(), INITIAL_VOTING_DELAY);
  }
}

contract GoatsDAO_Unit_VotingPeriod is Base {
  /**
   * @notice Check that the function works as expected
   */
  function test_VotingPeriod() public {
    assertEq(governor.votingPeriod(), INITIAL_VOTING_PERIOD);
  }
}

contract GoatsDAO_Unit_ProposalThreshold is Base {
  /**
   * @notice Check that the function works as expected
   */
  function test_ProposalThreshold() public {
    assertEq(governor.proposalThreshold(), INITIAL_PROPOSAL_THRESHOLD);
  }
}

contract GoatsDAO_Unit_CLOCK_MODE is Base {
  /**
   * @notice Test that the function returns the clock mode
   */
  function test_returnClockMode() public {
    string memory _mode = 'mode=blocktimestamp&from=default';
    assertEq(governor.CLOCK_MODE(), _mode);
  }
}

contract GoatsDAO_Unit_CastVote_WithoutParams is Base {
  /**
   * @notice Check that the function is disabled and reverts
   */
  function test_revertWithNotSupportedFunction() public {
    vm.prank(user);
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_NotSupportedFunction.selector);
    governor.castVote(proposalId, SUPPORT);
  }
}

contract GoatsDAO_Unit_CastVote_WithParams is Base {
  /**
   * @notice Check that the function emits the VoteCastWithParams event
   */
  function test_emitEvent(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    bytes memory _params =
      _mockWorlIDCalls(SUPPORT, proposalId, _root, _nullifierHash, _proof, ROOT_EXPIRATION_THRESHOLD, rootTimestamp);

    vm.expectEmit(true, true, true, true);
    emit IGovernor.VoteCastWithParams(user, proposalId, SUPPORT, ONE, REASON, _params);

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
    assertEq(_votingWeight, ONE);
  }
}

contract GoatsDAO_Unit_QuorumReached is Base {
  /**
   * @notice Test that the function returns if the quorum is reached
   */
  function test_reachedQuorum(string memory _description) public {
    // Prevent the same proposal id as `proposalId`
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
    // Prevent the same proposal id as `proposalId`
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
      uint8 _support = i % 2 == 0 ? 1 : 2; // If even support, if odd abstain
      vm.prank(_randomVoter);
      governor.forTest_countVote(_proposalId, _randomVoter, _support, ONE);
    }
  }
}

contract GoatsDAO_Unit_GetVotes is Base {
  /**
   * @notice Check that returns is 1
   */
  function test_returnsOne(address _account, uint256 _timepoint, bytes memory _params) public {
    uint256 _votingWeight = governor.forTest_getVotes(_account, _timepoint, _params);
    assertEq(_votingWeight, ONE);
  }
}
