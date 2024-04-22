// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {GovernorDemocraticForTest} from '../forTest/GovernorDemocraticForTest.sol';
import {UnitUtils} from './utils/UnitUtils.sol';
import {Test} from 'forge-std/Test.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';

abstract contract Base is Test, UnitUtils {
  string public constant APP_ID = 'appId';
  uint256 public constant GROUP_ID = 1;
  uint256 public constant ONE = 1;
  uint48 public constant INITIAL_VOTING_DELAY = 1 days;
  uint32 public constant INITIAL_VOTING_PERIOD = 3 days;
  uint256 public constant INITIAL_PROPOSAL_THRESHOLD = 1;
  uint256 public constant ROOT_EXPIRATION_THRESHOLD = 0;

  GovernorDemocraticForTest public governor;
  IWorldIDRouter public worldIDRouter;

  address public user;

  function setUp() public {
    // Instance the user and contracts addresses
    user = makeAddr('user');
    worldIDRouter = IWorldIDRouter(makeAddr('worldIDRouter'));

    // Deploy governor
    governor = new GovernorDemocraticForTest(
      GROUP_ID,
      worldIDRouter,
      APP_ID,
      INITIAL_VOTING_DELAY,
      INITIAL_VOTING_PERIOD,
      INITIAL_PROPOSAL_THRESHOLD,
      ROOT_EXPIRATION_THRESHOLD
    );
  }
}

contract GovernorDemocratic_Unit_GetVotes is Base {
  /**
   * @notice Test that the returned voting weight is always 1
   */
  function test_returnsOne(address _account, uint256 _timepoint, bytes memory _params) public {
    uint256 _votingWeight = governor.forTest_getVotes(_account, _timepoint, _params);
    assertEq(_votingWeight, ONE);
  }
}
