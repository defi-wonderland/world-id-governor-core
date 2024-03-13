// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {MockERC20Votes} from '../mocks/MockERC20Votes.sol';
import {IMockGovernorDemocraticForTest, MockGovernorDemocratic} from '../mocks/MockGovernorDemocratic.sol';
import {UnitUtils} from './UnitUtils.sol';
import {Test} from 'forge-std/Test.sol';
import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';
import {IWorldID} from 'interfaces/IWorldID.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {IVotes} from 'open-zeppelin/governance/utils/IVotes.sol';
import {IERC20} from 'open-zeppelin/token/ERC20/IERC20.sol';

abstract contract Base is Test, UnitUtils {
  uint256 public constant GROUP_ID = 1;
  uint256 public constant ONE = 1;

  IERC20 public token;
  IGovernorWorldID public governor;
  IWorldIDRouter public worldIDRouter;
  IWorldID public worldID;

  address public user;

  function setUp() public {
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
  }
}

contract GovernorDemocratic_Unit_GetVotes is Base {
  /**
   * @notice Check that the voting weight is 1
   */
  function test_returnsOne(address _account, uint256 _timepoint, bytes memory _params) public {
    uint256 _votingWeight =
      IMockGovernorDemocraticForTest(address(governor)).forTest_getVotes(_account, _timepoint, _params);
    assertEq(_votingWeight, ONE);
  }
}
