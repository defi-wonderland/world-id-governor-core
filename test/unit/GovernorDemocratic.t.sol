// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {MockERC20Votes} from '../mocks/MockERC20Votes.sol';
import {IMockGovernorDemocraticForTest, MockGovernorDemocratic} from '../mocks/MockGovernorDemocratic.sol';
import {Test} from 'forge-std/Test.sol';
import {UnitUtils} from './UnitUtils.sol';
import {IGovernor} from 'open-zeppelin/governance/IGovernor.sol';
import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';
import {IWorldID} from 'interfaces/IWorldID.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {IVotes} from 'open-zeppelin/governance/utils/IVotes.sol';
import {IERC20} from 'open-zeppelin/token/ERC20/IERC20.sol';

abstract contract Base is Test, UnitUtils {
  uint8 public constant SUPPORT = 1;
  uint256 public constant GROUP_ID = 1;
  string public constant REASON = '';
  uint256 public constant WEIGHT = 1;

  IERC20 public token;
  IGovernorWorldID public governor;
  IWorldIDRouter public worldIDRouter;
  IWorldID public worldID;

  uint256 public proposalId;
  address public user;

  function setUp() public virtual {
    vm.clearMockedCalls();

    user = makeAddr('user');

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
    governor = new MockGovernorDemocratic(GROUP_ID, worldIDRouter, _appId, _actionId, IVotes(address(token)));

    // Create proposal
    string memory _description = '0xDescription';
    proposalId = governor.propose(new address[](1), new uint256[](1), new bytes[](1), _description);

    // Advance time assuming 1 block == 1 second (this will make the proposal active)
    vm.warp(block.timestamp + governor.votingDelay() + 1);
    vm.roll(block.number + governor.votingDelay() + 1);
  }
}

contract GovernorDemocratic_Unit_GetVotes is Base {
  /**
   * @notice Check that the voting weight is 1
   */
  function test_returnsOne(address _account, uint256 _timepoint, bytes memory _params) public {
    uint256 _votes = IMockGovernorDemocraticForTest(address(governor)).forTest_getVotes(_account, _timepoint, _params);
    assertEq(_votes, 1);
  }
}

contract GovernorDemocratic_Unit_CastVoteWithReason is Base {
  /**
   * @notice Check that the function works as expected
   */
  function test_castVoteWithReason() public {
    vm.prank(user);
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_NotSupportedFunction.selector);
    IMockGovernorDemocraticForTest(address(governor)).forTest_castVote(proposalId, user, SUPPORT, REASON);
  }
}

contract GovernorDemocratic_Unit_CastVoteWithReasonAndParams is Base {
  /**
   * @notice Check that the function works as expected
   */
  function test_castVoteWithReasonAndParams(uint256 _root, uint256 _nullifierHash, uint256[8] memory _proof) public {
    bytes memory _params = _mockWorlIDCalls(worldID, _root, _nullifierHash, _proof);

    vm.expectEmit(true, true, true, true);
    emit IGovernor.VoteCastWithParams(user, proposalId, SUPPORT, WEIGHT, REASON, _params);

    // Cast the vote
    vm.prank(user);
    IMockGovernorDemocraticForTest(address(governor)).forTest_castVote(proposalId, user, SUPPORT, REASON, _params);
  }
}
