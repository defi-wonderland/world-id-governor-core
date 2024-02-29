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

  function setUp() public virtual {
    // Deploy token
    token = new MockERC20Votes();

    // Deploy governor
    governor = new MockGovernorWorldId(IWorldID(address(this)), 'appId', 'actionId', IVotes(address(token)));
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
  function testcastVoteBySigWithReasonShouldBeDisabled() public {
    // vm.expectRevert(IGovernorWorldID.GovernorWorldID_NotSupportedFunction.selector);
    // governor.castVoteBySig(0, 0, address(0), "");
  }
}
