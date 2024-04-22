// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {GovernorWorldIdForTest} from '../forTest/GovernorWorldIdForTest.sol';
import {GovernorSigUtils} from '../utils/GovernorSigUtils.sol';
import {InternalCallsWatcher} from './utils/CalledInternal.sol';
import {UnitUtils} from './utils/UnitUtils.sol';
import {Test, Vm} from 'forge-std/Test.sol';
import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';
import {IWorldIDIdentityManager} from 'interfaces/IWorldIDIdentityManager.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {ByteHasher} from 'libraries/ByteHasher.sol';
import {IGovernor} from 'open-zeppelin/governance/IGovernor.sol';
import {GovernorSettings} from 'open-zeppelin/governance/extensions/GovernorSettings.sol';
import {Strings} from 'open-zeppelin/utils/Strings.sol';

abstract contract Base is Test, UnitUtils {
  uint8 public constant SUPPORT = 1;
  uint256 public constant GROUP_ID = _GROUP_ID;
  string public constant REASON = '';
  string public constant APP_ID = _APP_ID;
  uint48 public constant INITIAL_VOTING_DELAY = 1 days;
  uint32 public constant INITIAL_VOTING_PERIOD = 3 days;
  uint256 public constant INITIAL_PROPOSAL_THRESHOLD = 0;
  uint256 public constant ROOT_EXPIRATION_THRESHOLD = 0;
  uint256 public constant RESET_GRACE_PERIOD = 13 days + 22 hours;
  uint256 public constant ROOT_HISTORY_EXPIRY = 1 weeks;
  uint128 public rootTimestamp = uint128(block.timestamp - 1);

  Vm.Wallet public signer = vm.createWallet('signer');
  address public user = makeAddr('user');

  GovernorWorldIdForTest public governor;
  IWorldIDRouter public worldIDRouter;
  IWorldIDIdentityManager public worldIDIdentityManager;
  GovernorSigUtils public sigUtils;
  address public watcher;

  uint256 public proposalId;
  bytes public signature;

  function setUp() public {
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
      abi.encode(ROOT_HISTORY_EXPIRY)
    );

    // Deploy governor
    GovernorWorldIdForTest.ConstructorArgs memory _cArgs = GovernorWorldIdForTest.ConstructorArgs(
      GROUP_ID,
      worldIDRouter,
      APP_ID,
      INITIAL_VOTING_DELAY,
      INITIAL_VOTING_PERIOD,
      INITIAL_PROPOSAL_THRESHOLD,
      ROOT_EXPIRATION_THRESHOLD
    );
    governor = new GovernorWorldIdForTest(_cArgs);

    watcher = address(governor.watcher());

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

contract GovernorWorldID_Unit_Constructor is Base {
  using ByteHasher for bytes;
  using Strings for *;

  /**
   * @notice Check that the constructor works as expected
   */
  function test_correctDeploy(uint32 _newVotingPeriod, uint256 _rootExpirationThreshold) public {
    vm.assume(_rootExpirationThreshold <= RESET_GRACE_PERIOD);
    vm.assume(_rootExpirationThreshold <= ROOT_HISTORY_EXPIRY);
    vm.assume(_newVotingPeriod != 0);
    vm.assume(_newVotingPeriod < RESET_GRACE_PERIOD - _rootExpirationThreshold);

    GovernorWorldIdForTest _governor = new GovernorWorldIdForTest(
      GovernorWorldIdForTest.ConstructorArgs(
        GROUP_ID,
        worldIDRouter,
        APP_ID,
        INITIAL_VOTING_DELAY,
        INITIAL_VOTING_PERIOD,
        INITIAL_PROPOSAL_THRESHOLD,
        _rootExpirationThreshold
      )
    );

    assertEq(address(_governor.WORLD_ID_ROUTER()), address(worldIDRouter));
    assertEq(_governor.GROUP_ID(), GROUP_ID);
    assertEq(_governor.APP_ID_HASH(), abi.encodePacked(APP_ID).hashToField());
    assertEq(_governor.appId(), APP_ID);
    assertEq(_governor.resetGracePeriod(), RESET_GRACE_PERIOD);
    assertEq(_governor.rootExpirationThreshold(), _rootExpirationThreshold);
    assertEq(_governor.votingDelay(), INITIAL_VOTING_DELAY);
    assertEq(_governor.votingPeriod(), INITIAL_VOTING_PERIOD);
    assertEq(_governor.proposalThreshold(), INITIAL_PROPOSAL_THRESHOLD);
    // Check the proposal's description uniqueness salt is properly set
    string memory _proposalUniquenessSalt = string.concat(
      ' ### Proposal Uniqueness Salt:',
      ' - **Chain ID:** ',
      block.chainid.toString(),
      ' - **Contract Address:** ',
      address(_governor).toHexString()
    );
    assertEq(_governor.proposalUniquenessSalt(), _proposalUniquenessSalt);
  }
}

contract GovernorWorldID_Unit_CheckVoteValidity_External is Base {
  function test_callCheckValidityVote(bytes memory _proofData) public {
    bool _callSuper = false;
    governor.setCallSuper(_callSuper);

    vm.expectCall(
      watcher,
      abi.encodeWithSelector(
        InternalCallsWatcher.calledInternal.selector,
        abi.encodeWithSignature('_checkVoteValidity(uint8,uint256,bytes)', SUPPORT, proposalId, _proofData)
      )
    );
    governor.checkVoteValidity(SUPPORT, proposalId, _proofData);
  }
}

contract GovernorWorldID_Unit_SetConfig_External is Base {
  function test_revertIfCalledByNonGovernance(address _sender) public {
    vm.assume(_sender != address(governor));
    vm.expectRevert(abi.encodeWithSelector(IGovernor.GovernorOnlyExecutor.selector, _sender));
    vm.startPrank(_sender);
    governor.setConfig(INITIAL_VOTING_PERIOD, RESET_GRACE_PERIOD, ROOT_EXPIRATION_THRESHOLD);
  }

  function test_callInternalSetConfig() public {
    // Set the callSuper to false since we are only testing that it calls the internal function correctly
    bool _callSuper = false;
    governor.setCallSuper(_callSuper);

    // Expect the internal function to be called
    vm.expectCall(
      watcher,
      abi.encodeWithSelector(
        InternalCallsWatcher.calledInternal.selector,
        abi.encodeWithSignature(
          '_setConfig(uint32,uint256,uint256)', INITIAL_VOTING_PERIOD, RESET_GRACE_PERIOD, ROOT_EXPIRATION_THRESHOLD
        )
      )
    );

    vm.prank(address(governor));
    governor.setConfig(INITIAL_VOTING_PERIOD, RESET_GRACE_PERIOD, ROOT_EXPIRATION_THRESHOLD);
  }
}

contract GovernorWorldID_Unit_CheckConfigValidity_External is Base {
  /**
   * @notice Test that the function properly calls `_checkConfigValidity`
   */
  function test_callCheckConfigValidity(
    uint32 _votingPeriod,
    uint256 _resetGracePeriod,
    uint256 _rootExpirationThreshold
  ) public {
    // Only testing the internal call
    bool _callSuper = false;
    governor.setCallSuper(_callSuper);

    vm.expectCall(
      watcher,
      abi.encodeWithSelector(
        InternalCallsWatcher.calledInternal.selector,
        abi.encodeWithSignature(
          '_checkConfigValidity(uint32,uint256,uint256)', _votingPeriod, _resetGracePeriod, _rootExpirationThreshold
        )
      )
    );
    governor.checkConfigValidity(_votingPeriod, _resetGracePeriod, _rootExpirationThreshold);
  }
}

contract GovernorWorldID_Unit_SetVotingPeriod is Base {
  /**
   * @notice Test that the function reverts if the caller is not the governance
   */
  function test_revertIfCalledByNonGovernance(address _sender) public {
    vm.assume(_sender != address(governor));
    vm.expectRevert(abi.encodeWithSelector(IGovernor.GovernorOnlyExecutor.selector, _sender));
    vm.startPrank(_sender);
    governor.setVotingPeriod(INITIAL_VOTING_PERIOD);
  }

  /**
   * @notice Test that the function properly calls `_checkConfigValidity`
   */
  function test_callCheckConfigValidity(uint32 _newVotingPeriod) public {
    vm.assume(_newVotingPeriod != 0);
    // Set the callSuper to false since we are only testing that it calls the internal function correctly
    bool _callSuper = false;
    governor.setCallSuper(_callSuper);

    // Expect the internal function to be called
    vm.expectCall(
      watcher,
      abi.encodeWithSelector(
        InternalCallsWatcher.calledInternal.selector,
        abi.encodeWithSignature(
          '_checkConfigValidity(uint32,uint256,uint256)',
          _newVotingPeriod,
          RESET_GRACE_PERIOD,
          ROOT_EXPIRATION_THRESHOLD
        )
      )
    );

    vm.prank(address(governor));
    governor.setVotingPeriod(_newVotingPeriod);
  }

  /**
   * @notice Test that the function properly calls the high-order function with super
   */
  function test_setVotingPeriod(uint32 _newVotingPeriod) public {
    vm.assume(_newVotingPeriod != 0);
    vm.assume(_newVotingPeriod < RESET_GRACE_PERIOD);

    vm.mockCall(
      address(worldIDRouter),
      abi.encodeWithSelector(IWorldIDRouter.routeFor.selector, GROUP_ID),
      abi.encode(address(worldIDIdentityManager))
    );

    uint256 _newRootExpirationThreshold = 0;
    vm.mockCall(
      address(worldIDIdentityManager),
      abi.encodeWithSelector(IWorldIDIdentityManager.rootHistoryExpiry.selector),
      abi.encode(_newRootExpirationThreshold)
    );

    vm.prank(address(governor));
    governor.setVotingPeriod(_newVotingPeriod);
    assertEq(governor.votingPeriod(), _newVotingPeriod);
  }
}

contract GovernorWorldID_Unit_CheckVoteValidity_Internal is Base {
  using ByteHasher for bytes;
  using Strings for uint256;

  /**
   * @notice Test that the function reverts if the nullifier is already used
   */
  function test_revertIfNullifierAlreadyUsed(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);

    governor.forTest_setNullifierHash(_nullifierHash, true);

    vm.expectRevert(IGovernorWorldID.GovernorWorldID_DuplicateNullifier.selector);
    vm.prank(user);
    governor.forTest_checkVoteValidity(SUPPORT, proposalId, _params);
  }

  /**
   * @notice Test that the function calls the latestRoot function from the Router contract
   */
  function test_callRouteFor(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    bytes memory _params =
      _mockWorlIDCalls(SUPPORT, proposalId, _root, _nullifierHash, _proof, ROOT_EXPIRATION_THRESHOLD, rootTimestamp);

    _mockAndExpect(
      address(worldIDRouter),
      abi.encodeWithSelector(IWorldIDRouter.routeFor.selector, GROUP_ID),
      abi.encode(address(worldIDIdentityManager))
    );

    vm.prank(user);
    governor.forTest_checkVoteValidity(SUPPORT, proposalId, _params);
  }

  /**
   * @notice Test that the function calls the latestRoot function from the IdentityManager contract
   */
  function test_callLatestRoot(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    // enforce threshold to be 0
    governor.forTest_setRootExpirationThreshold(0);

    // Encode the parameters
    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);

    vm.mockCall(
      address(worldIDRouter),
      abi.encodeWithSelector(IWorldIDRouter.routeFor.selector),
      abi.encode(address(worldIDIdentityManager))
    );

    _mockAndExpect(
      address(worldIDIdentityManager),
      abi.encodeWithSelector(IWorldIDIdentityManager.latestRoot.selector),
      abi.encode(_root)
    );

    vm.prank(user);
    governor.forTest_checkVoteValidity(SUPPORT, proposalId, _params);
  }

  /**
   * @notice Test that the function reverts if the root is outdated
   */
  function test_revertIfOutdatedRootWhenZeroThreshold(
    uint256 _root,
    uint256 _latestRoot,
    uint256 _nullifierHash,
    uint256[8] memory _proof
  ) public {
    vm.assume(_root != _latestRoot);

    governor.forTest_setRootExpirationThreshold(0);

    _mockAndExpect(
      address(worldIDIdentityManager),
      abi.encodeWithSelector(IWorldIDIdentityManager.latestRoot.selector),
      abi.encode(_latestRoot)
    );

    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);

    // Try to cast a vote with an outdated root
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_OutdatedRoot.selector);
    vm.prank(user);
    governor.forTest_checkVoteValidity(SUPPORT, proposalId, _params);
  }

  /**
   * @notice Test that the function calls the `rootHistoryExpiry` function from the IdentityManager contract
   */
  function test_callRootHistoryExpiry(
    uint128 _rootTimestamp,
    uint256 _root,
    uint256 _nullifierHash,
    uint256[8] memory _proof
  ) public {
    vm.warp(1_000_000);
    // Set a new root expiration threshold
    uint256 _rootExpirationThreshold = ROOT_EXPIRATION_THRESHOLD + 1;
    vm.assume(_rootTimestamp > block.timestamp - _rootExpirationThreshold);
    governor.forTest_setRootExpirationThreshold(_rootExpirationThreshold);

    vm.mockCall(
      address(worldIDRouter),
      abi.encodeWithSelector(IWorldIDRouter.routeFor.selector),
      abi.encode(address(worldIDIdentityManager))
    );

    _mockAndExpect(
      address(worldIDIdentityManager),
      abi.encodeWithSelector(IWorldIDIdentityManager.rootHistoryExpiry.selector),
      abi.encode(ROOT_HISTORY_EXPIRY)
    );

    vm.mockCall(
      address(worldIDIdentityManager),
      abi.encodeWithSelector(IWorldIDIdentityManager.rootHistory.selector),
      abi.encode(_rootTimestamp)
    );

    vm.prank(user);
    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);
    governor.forTest_checkVoteValidity(SUPPORT, proposalId, _params);
  }

  /**
   * @notice Test that the function calls the rootHistory function from the IdentityManager contract
   */
  function test_callRootHistory(
    uint128 _rootTimestamp,
    uint256 _root,
    uint256 _nullifierHash,
    uint256[8] memory _proof
  ) public {
    vm.warp(1_000_000);
    uint256 _rootExpirationThreshold = ROOT_EXPIRATION_THRESHOLD + 1;

    vm.assume(_rootTimestamp > block.timestamp - _rootExpirationThreshold);

    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);

    // Set a new root expiration threshold
    governor.forTest_setRootExpirationThreshold(_rootExpirationThreshold);

    vm.mockCall(
      address(worldIDRouter),
      abi.encodeWithSelector(IWorldIDRouter.routeFor.selector),
      abi.encode(address(worldIDIdentityManager))
    );

    vm.mockCall(
      address(worldIDIdentityManager),
      abi.encodeWithSelector(IWorldIDIdentityManager.rootHistoryExpiry.selector),
      abi.encode(ROOT_HISTORY_EXPIRY)
    );

    _mockAndExpect(
      address(worldIDIdentityManager),
      abi.encodeWithSelector(IWorldIDIdentityManager.rootHistory.selector, _root),
      abi.encode(_rootTimestamp)
    );

    vm.prank(user);
    governor.forTest_checkVoteValidity(SUPPORT, proposalId, _params);
  }

  /**
   * @notice Test that the function reverts if the root is outdated
   */
  function test_revertIfOutdatedRootWhenNonZeroThreshold(
    uint128 _rootTimestamp,
    uint256 _root,
    uint256 _nullifierHash,
    uint256[8] memory _proof
  ) public {
    vm.warp(1_000_000);
    uint256 _rootExpirationThreshold = ROOT_EXPIRATION_THRESHOLD + 1;

    vm.assume(_rootTimestamp < block.timestamp - _rootExpirationThreshold);

    _mockAndExpect(
      address(worldIDIdentityManager),
      abi.encodeWithSelector(IWorldIDIdentityManager.rootHistory.selector, _root),
      abi.encode(_rootTimestamp)
    );

    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);

    // Set a new root expiration threshold
    governor.forTest_setRootExpirationThreshold(_rootExpirationThreshold);

    // Try to cast a vote with an outdated root
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_OutdatedRoot.selector);
    vm.prank(user);
    governor.forTest_checkVoteValidity(SUPPORT, proposalId, _params);
  }

  /**
   * @notice Test that the function calls the verifyProof function from the WorldID contract
   */
  function test_callVerifyProof(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    governor.forTest_setRootExpirationThreshold(0);

    bytes memory _params = abi.encode(_root, _nullifierHash, _proof);

    vm.mockCall(
      address(worldIDRouter),
      abi.encodeWithSelector(IWorldIDRouter.routeFor.selector),
      abi.encode(address(worldIDIdentityManager))
    );

    vm.mockCall(
      address(worldIDIdentityManager),
      abi.encodeWithSelector(IWorldIDIdentityManager.latestRoot.selector),
      abi.encode(_root)
    );

    uint256 _signal = abi.encodePacked(uint256(SUPPORT).toString()).hashToField();
    uint256 _externalNullifier = abi.encodePacked(governor.APP_ID_HASH(), proposalId.toString()).hashToField();
    _mockAndExpect(
      address(worldIDRouter),
      abi.encodeWithSelector(
        IWorldIDRouter.verifyProof.selector, _root, GROUP_ID, _signal, _nullifierHash, _externalNullifier, _proof
      ),
      abi.encode(true)
    );

    vm.prank(user);
    governor.forTest_checkVoteValidity(SUPPORT, proposalId, _params);
  }

  /**
   * @notice Test that the function returns the nullifier hash
   */
  function test_returnNullifierHash(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    bytes memory _params =
      _mockWorlIDCalls(SUPPORT, proposalId, _root, _nullifierHash, _proof, ROOT_EXPIRATION_THRESHOLD, rootTimestamp);

    vm.prank(user);
    uint256 _returnedNullifierHash = governor.forTest_checkVoteValidity(SUPPORT, proposalId, _params);
    assertEq(_returnedNullifierHash, _nullifierHash);
  }
}

contract GovernorWorldID_Unit_Propose is Base {
  function test_proposeWithDescriptionSalt() public {
    // Proposal Inputs
    address[] memory _targets = new address[](1);
    uint256[] memory _values = new uint256[](1);
    bytes[] memory _calldatas = new bytes[](1);
    string memory _inputDescription = 'This is my description.';
    // Concatenate the description with the salt and calculate the proposal id
    string memory _saltDescription = string.concat(_inputDescription, governor.proposalUniquenessSalt());
    uint256 _expectedProposalId =
      governor.hashProposal(_targets, _values, _calldatas, keccak256(bytes(_saltDescription)));

    vm.prank(user);
    uint256 _proposalId = governor.forTest_propose(_targets, _values, _calldatas, _inputDescription, user);

    // Assert the proposal id is the expected one
    assertEq(_proposalId, _expectedProposalId);
  }
}

contract GovernorWorldID_Unit_SetConfig_Internal is Base {
  /**
   * @notice Test that it reverts if the root expiration threshold is smaller than the reset grace period
   */
  function test_revertIfRootExpirationThresholdGreaterThanResetPeriod() public {
    // Add 1 to the reset grace period just in case it is change to 0
    uint256 _newResetGracePeriod = RESET_GRACE_PERIOD + 1;
    uint256 _newRootExpirationThreshold = _newResetGracePeriod + 1;
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_InvalidRootExpirationThreshold.selector);
    governor.forTest_setConfig(INITIAL_VOTING_PERIOD, _newResetGracePeriod, _newRootExpirationThreshold);
  }

  /**
   * @notice Test that it properly calls `_checkConfigValidity`. The root expiration threshold is set to 0 so there is
   * no need to mock other calls
   */
  function test_callCheckConfigValidity() public {
    // Ensure the root expiration threshold is 0 just in case the constant is updated in the future
    uint256 _newRootExpirationThreshold = 0;

    // Expect the internal function to be called
    vm.expectCall(
      watcher,
      abi.encodeWithSelector(
        InternalCallsWatcher.calledInternal.selector,
        abi.encodeWithSignature(
          '_checkConfigValidity(uint32,uint256,uint256)',
          INITIAL_VOTING_PERIOD,
          RESET_GRACE_PERIOD,
          _newRootExpirationThreshold
        )
      )
    );

    governor.forTest_setConfig(INITIAL_VOTING_PERIOD, RESET_GRACE_PERIOD, _newRootExpirationThreshold);
  }

  /**
   * @notice Test that it calls the `routeFor` function if the root expiration threshold is not 0
   */
  function test_callRouteFor() public {
    uint256 _newRootExpirationThreshold = 1;
    uint32 _newVotingPeriod = uint32(RESET_GRACE_PERIOD - _newRootExpirationThreshold - 1);

    _mockAndExpect(
      address(worldIDRouter),
      abi.encodeWithSelector(IWorldIDRouter.routeFor.selector, GROUP_ID),
      abi.encode(address(worldIDIdentityManager))
    );

    vm.mockCall(
      address(worldIDIdentityManager),
      abi.encodeWithSelector(IWorldIDIdentityManager.rootHistoryExpiry.selector),
      abi.encode(_newRootExpirationThreshold)
    );

    governor.forTest_setConfig(_newVotingPeriod, RESET_GRACE_PERIOD, _newRootExpirationThreshold);
  }

  /**
   * @notice Test that it correctly sets the voting period
   */
  function test_setVotingPeriod(uint32 _newVotingPeriod) public {
    vm.assume(_newVotingPeriod != 0);
    vm.assume(_newVotingPeriod < RESET_GRACE_PERIOD);

    vm.mockCall(
      address(worldIDRouter),
      abi.encodeWithSelector(IWorldIDRouter.routeFor.selector, GROUP_ID),
      abi.encode(address(worldIDIdentityManager))
    );

    uint256 _newRootExpirationThreshold = 0;
    vm.mockCall(
      address(worldIDIdentityManager),
      abi.encodeWithSelector(IWorldIDIdentityManager.rootHistoryExpiry.selector),
      abi.encode(_newRootExpirationThreshold)
    );

    governor.forTest_setConfig(_newVotingPeriod, RESET_GRACE_PERIOD, _newRootExpirationThreshold);
    assertEq(governor.votingPeriod(), _newVotingPeriod);
  }

  /**
   * @notice Test that it emits the `VotingPeriodSet` event
   */
  function test_emitVotingPeriodSetEvent(uint32 _newVotingPeriod) public {
    vm.assume(_newVotingPeriod != 0);
    vm.assume(_newVotingPeriod != INITIAL_VOTING_PERIOD);
    vm.assume(_newVotingPeriod < RESET_GRACE_PERIOD);

    vm.mockCall(
      address(worldIDRouter),
      abi.encodeWithSelector(IWorldIDRouter.routeFor.selector, GROUP_ID),
      abi.encode(address(worldIDIdentityManager))
    );

    uint256 _newRootExpirationThreshold = 0;
    vm.mockCall(
      address(worldIDIdentityManager),
      abi.encodeWithSelector(IWorldIDIdentityManager.rootHistoryExpiry.selector),
      abi.encode(_newRootExpirationThreshold)
    );

    vm.expectEmit(true, true, true, true);
    emit GovernorSettings.VotingPeriodSet(INITIAL_VOTING_PERIOD, _newVotingPeriod);
    governor.forTest_setConfig(_newVotingPeriod, RESET_GRACE_PERIOD, _newRootExpirationThreshold);
  }

  /**
   * @notice Test that it correctly sets the reset grace period
   */
  function test_setResetGracePeriod(uint256 _newResetGracePeriod) public {
    vm.assume(_newResetGracePeriod > INITIAL_VOTING_PERIOD);

    vm.mockCall(
      address(worldIDRouter),
      abi.encodeWithSelector(IWorldIDRouter.routeFor.selector, GROUP_ID),
      abi.encode(address(worldIDIdentityManager))
    );

    uint256 _newRootExpirationThreshold = 0;
    vm.mockCall(
      address(worldIDIdentityManager),
      abi.encodeWithSelector(IWorldIDIdentityManager.rootHistoryExpiry.selector),
      abi.encode(_newRootExpirationThreshold)
    );

    governor.forTest_setConfig(INITIAL_VOTING_PERIOD, _newResetGracePeriod, _newRootExpirationThreshold);
    assertEq(governor.resetGracePeriod(), _newResetGracePeriod);
  }

  /**
   * @notice Test that it emits the `ResetGracePeriodSet` event
   */
  function test_emitSetResetPeriodEvent(uint256 _newResetGracePeriod) public {
    vm.assume(_newResetGracePeriod != RESET_GRACE_PERIOD);
    vm.assume(_newResetGracePeriod > INITIAL_VOTING_PERIOD);

    vm.mockCall(
      address(worldIDRouter),
      abi.encodeWithSelector(IWorldIDRouter.routeFor.selector, GROUP_ID),
      abi.encode(address(worldIDIdentityManager))
    );

    uint256 _newRootExpirationThreshold = 0;
    vm.mockCall(
      address(worldIDIdentityManager),
      abi.encodeWithSelector(IWorldIDIdentityManager.rootHistoryExpiry.selector),
      abi.encode(_newRootExpirationThreshold)
    );

    vm.expectEmit(true, true, true, true);
    emit IGovernorWorldID.ResetGracePeriodSet(RESET_GRACE_PERIOD, _newResetGracePeriod);
    governor.forTest_setConfig(INITIAL_VOTING_PERIOD, _newResetGracePeriod, _newRootExpirationThreshold);
  }

  /**
   * @notice Test that it correctly sets the root expiration threshold
   */
  function test_setRootExpirationThreshold(uint256 _newRootExpirationThreshold) public {
    // Just in case the `RESET_GRACE_PERIOD` is set to 0
    uint256 _newResetGracePeriod = type(uint256).max;
    // Assume the new root expiration threshold is smaller than the reset grace period
    vm.assume(_newRootExpirationThreshold < _newResetGracePeriod - 1);
    // Set the new voting flow to a valid value
    uint32 _newVotingPeriod = uint32(bound(1, 1, _newResetGracePeriod - _newRootExpirationThreshold - 1));

    vm.mockCall(
      address(worldIDRouter),
      abi.encodeWithSelector(IWorldIDRouter.routeFor.selector, GROUP_ID),
      abi.encode(address(worldIDIdentityManager))
    );

    vm.mockCall(
      address(worldIDIdentityManager),
      abi.encodeWithSelector(IWorldIDIdentityManager.rootHistoryExpiry.selector),
      abi.encode(_newRootExpirationThreshold)
    );

    governor.forTest_setConfig(_newVotingPeriod, _newResetGracePeriod, _newRootExpirationThreshold);
    assertEq(governor.rootExpirationThreshold(), _newRootExpirationThreshold);
  }

  /**
   * @notice Test that it emits the `RootExpirationThresholdSet` event
   */
  function test_emitRootExpirationThresholdEvent(uint256 _newRootExpirationThreshold) public {
    // Ensure the event will be emitted
    vm.assume(_newRootExpirationThreshold != ROOT_EXPIRATION_THRESHOLD);
    // Just in case the `RESET_GRACE_PERIOD` is set to 0
    uint256 _newResetGracePeriod = type(uint256).max;
    // Assume the new root expiration threshold is smaller than the reset grace period
    vm.assume(_newRootExpirationThreshold < _newResetGracePeriod - 1);
    // Set the new voting flow to a valid value
    uint32 _newVotingPeriod = uint32(bound(1, 1, _newResetGracePeriod - _newRootExpirationThreshold - 1));

    vm.mockCall(
      address(worldIDRouter),
      abi.encodeWithSelector(IWorldIDRouter.routeFor.selector, GROUP_ID),
      abi.encode(address(worldIDIdentityManager))
    );

    vm.mockCall(
      address(worldIDIdentityManager),
      abi.encodeWithSelector(IWorldIDIdentityManager.rootHistoryExpiry.selector),
      abi.encode(_newRootExpirationThreshold)
    );

    vm.expectEmit(true, true, true, true);
    emit IGovernorWorldID.RootExpirationThresholdSet(ROOT_EXPIRATION_THRESHOLD, _newRootExpirationThreshold);
    governor.forTest_setConfig(_newVotingPeriod, _newResetGracePeriod, _newRootExpirationThreshold);
  }
}

contract GovernorWorldID_Unit_CastVote_WithParams is Base {
  /**
   * @notice Check that the function stores the nullifier as used
   */
  function test_nullifierIsStored(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    bytes memory _params =
      _mockWorlIDCalls(SUPPORT, proposalId, _root, _nullifierHash, _proof, ROOT_EXPIRATION_THRESHOLD, rootTimestamp);

    // Cast the vote
    vm.prank(user);
    governor.forTest_castVote(proposalId, user, SUPPORT, REASON, _params);
    assertTrue(governor.nullifierHashes(_nullifierHash));
  }

  /**
   * @notice Check that the function works as expected
   */
  function test_castVoteWithReasonAndParams(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    uint256 _weight = governor.getVotes(address(user), block.timestamp);
    bytes memory _params =
      _mockWorlIDCalls(SUPPORT, proposalId, _root, _nullifierHash, _proof, ROOT_EXPIRATION_THRESHOLD, rootTimestamp);

    vm.expectEmit(true, true, true, true);
    emit IGovernor.VoteCastWithParams(user, proposalId, SUPPORT, _weight, REASON, _params);

    // Cast the vote
    vm.prank(user);
    governor.forTest_castVote(proposalId, user, SUPPORT, REASON, _params);
  }
}

contract GovernorWorldID_Unit_CastVote_WithoutParams is Base {
  function test_revertWhenCalled() public {
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_NotSupportedFunction.selector);
    vm.startPrank(user);
    governor.forTest_castVote(proposalId, user, SUPPORT, REASON);
  }
}

contract GovernorWorldID_Unit_CheckConfigValidity_Internal is Base {
  /**
   * @notice Test that it doesn't call the `rootHistoryExpiry` function if the root expiration threshold is 0
   */
  function test_dontCallRootHistoryExpiryIfZero() public {
    uint32 _newVotingPeriod = uint32(RESET_GRACE_PERIOD - 1);
    uint256 _newRootExpirationThreshold = 0;
    vm.expectCall(
      address(worldIDIdentityManager), abi.encodeWithSelector(IWorldIDIdentityManager.rootHistoryExpiry.selector), 0
    );
    governor.forTest_checkConfigValidity(_newVotingPeriod, RESET_GRACE_PERIOD, _newRootExpirationThreshold);
  }

  /**
   * @notice Test that it calls the `routeFor` function if the root expiration threshold is not 0
   */
  function test_callRouteFor() public {
    uint256 _newRootExpirationThreshold = 1;
    uint32 _newVotingPeriod = uint32(RESET_GRACE_PERIOD - _newRootExpirationThreshold - 1);

    _mockAndExpect(
      address(worldIDRouter),
      abi.encodeWithSelector(IWorldIDRouter.routeFor.selector, GROUP_ID),
      abi.encode(address(worldIDIdentityManager))
    );

    vm.mockCall(
      address(worldIDIdentityManager),
      abi.encodeWithSelector(IWorldIDIdentityManager.rootHistoryExpiry.selector),
      abi.encode(_newRootExpirationThreshold)
    );

    governor.forTest_checkConfigValidity(_newVotingPeriod, RESET_GRACE_PERIOD, _newRootExpirationThreshold);
  }

  /**
   * @notice Check that the function calls the `rootHistoryExpiry` function from the IdentityManager contract if
   * the root expiration threshold is not 0
   */
  function test_callRootHistoryExpiry(uint256 _rootExpirationThreshold) public {
    vm.assume(_rootExpirationThreshold <= RESET_GRACE_PERIOD);
    vm.assume(_rootExpirationThreshold <= ROOT_HISTORY_EXPIRY);
    vm.assume(_rootExpirationThreshold != 0);

    vm.mockCall(
      address(worldIDRouter),
      abi.encodeWithSelector(IWorldIDRouter.routeFor.selector, GROUP_ID),
      abi.encode(address(worldIDIdentityManager))
    );

    _mockAndExpect(
      address(worldIDIdentityManager),
      abi.encodeWithSelector(IWorldIDIdentityManager.rootHistoryExpiry.selector),
      abi.encode(ROOT_HISTORY_EXPIRY)
    );

    governor.forTest_checkConfigValidity(INITIAL_VOTING_PERIOD, RESET_GRACE_PERIOD, _rootExpirationThreshold);
  }

  /**
   * @notice Test that it reverts if the root expiration threshold is greater than the root history expiry
   */
  function test_revertIfRootExpirationThresholdGreaterThanRotHistoryExpiry(uint256 _newRootExpirationThreshold) public {
    vm.assume(_newRootExpirationThreshold != 0);
    // Set the reset grace period to the max value so it doesn't revert on that check
    uint256 _newResetGracePeriod = type(uint256).max;

    _mockAndExpect(
      address(worldIDRouter),
      abi.encodeWithSelector(IWorldIDRouter.routeFor.selector, GROUP_ID),
      abi.encode(address(worldIDIdentityManager))
    );

    uint256 _rootHistoryExpiry = _newRootExpirationThreshold - 1;
    _mockAndExpect(
      address(worldIDIdentityManager),
      abi.encodeWithSelector(IWorldIDIdentityManager.rootHistoryExpiry.selector),
      abi.encode(_rootHistoryExpiry)
    );

    vm.expectRevert(IGovernorWorldID.GovernorWorldID_InvalidRootExpirationThreshold.selector);
    governor.forTest_checkConfigValidity(INITIAL_VOTING_PERIOD, _newResetGracePeriod, _newRootExpirationThreshold);
  }

  /**
   * @notice Test that it reverts if the voting period is greater than the reset grace period minus
   * the root expiration threshold
   */
  function test_revertIfInvalidVotingPeriod(uint32 _newVotingPeriod, uint256 _newRootExpirationThreshold) public {
    uint256 _newResetGracePeriod = (type(uint256).max - 1);
    _newRootExpirationThreshold = bound(_newRootExpirationThreshold, 0, _newResetGracePeriod);
    vm.assume(_newVotingPeriod > _newResetGracePeriod - _newRootExpirationThreshold);
    // Set the reset grace period to the max value so it doesn't revert on that check

    vm.mockCall(
      address(worldIDRouter),
      abi.encodeWithSelector(IWorldIDRouter.routeFor.selector, GROUP_ID),
      abi.encode(address(worldIDIdentityManager))
    );

    vm.mockCall(
      address(worldIDIdentityManager),
      abi.encodeWithSelector(IWorldIDIdentityManager.rootHistoryExpiry.selector),
      abi.encode(_newRootExpirationThreshold)
    );

    vm.expectRevert(IGovernorWorldID.GovernorWorldID_InvalidVotingPeriod.selector);
    governor.forTest_checkConfigValidity(_newVotingPeriod, _newResetGracePeriod, _newRootExpirationThreshold);
  }
}
