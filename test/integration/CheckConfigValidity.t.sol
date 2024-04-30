// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IntegrationBase} from './IntegrationBase.sol';
import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';

contract Integration_CheckConfigValidity is IntegrationBase {
  /**
   * @notice Test the call doesn't revert when the parameters are valid
   */
  function test_callSucceeds(uint32 _votingPeriod, uint256 _resetGracePeriod, uint256 _rootExpirationThreshold) public {
    uint256 _rootHistoryExpiry = governance.WORLD_ID_ROUTER().routeFor(governance.GROUP_ID()).rootHistoryExpiry();
    // Set the `rootExpirationThreshold` to a valid value
    _rootExpirationThreshold = bound(_rootExpirationThreshold, 0, _rootHistoryExpiry);
    // Set the `resetGracePeriod` to a valid value
    _resetGracePeriod = bound(_resetGracePeriod, _rootExpirationThreshold + 2, type(uint256).max);
    // Set the `votingPeriod` to a valid value
    _votingPeriod = uint32(bound(_votingPeriod, 1, _resetGracePeriod - _rootExpirationThreshold - 1));

    // Call the function
    vm.prank(address(user));
    governance.checkConfigValidity(_votingPeriod, _resetGracePeriod, _rootExpirationThreshold);
  }

  /**
   * @notice Test reverts when `rootExpirationThreshold` is smaller than `rootHistoryExpiry`
   */
  function test_revertIfInvalidRootExpirationThreshold() public {
    // Set the reset grace period to the maximum value so we are able to test the `rootHistoryExpiry` check
    uint256 _newResetGracePeriod = type(uint256).max;
    uint32 _votingPeriod = uint32(governance.votingPeriod());

    // Set the `rootExpirationThreshold` to an invalid value
    uint256 _rootHistoryExpiry = governance.WORLD_ID_ROUTER().routeFor(governance.GROUP_ID()).rootHistoryExpiry();
    uint256 _rootExpirationThreshold = _rootHistoryExpiry + 1;

    vm.expectRevert(IGovernorWorldID.GovernorWorldID_InvalidRootExpirationThreshold.selector);
    vm.prank(address(user));
    governance.checkConfigValidity(_votingPeriod, _newResetGracePeriod, _rootExpirationThreshold);
  }

  /**
   * @notice Test reverts when `votingPeriod` is greater than `resetGracePeriod` minus `rootExpirationThreshold`
   */
  function test_revertIfInvalidVotingPeriod() public {
    // Set the `votingPeriod` to an invalid value
    uint256 _resetGracePeriod = governance.resetGracePeriod();
    uint256 _rootExpirationThreshold = governance.rootExpirationThreshold();
    uint256 _maxValidVotingPeriod = _resetGracePeriod - _rootExpirationThreshold - 1;
    uint32 _votingPeriod = uint32(_maxValidVotingPeriod + 1);

    // Expect the call to revert
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_InvalidVotingPeriod.selector);
    vm.prank(address(user));
    governance.checkConfigValidity(_votingPeriod, _resetGracePeriod, _rootExpirationThreshold);
  }
}
