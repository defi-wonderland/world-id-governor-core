// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IntegrationBase} from './IntegrationBase.sol';
import {IGovernorWorldID} from 'interfaces/IGovernorWorldID.sol';

contract Integration_SetConfig is IntegrationBase {
  /**
   * @notice Test `votingPeriod`, `resetGracePeriod`, and `rootExpirationThreshold` are correctly updated
   */
  function test_setConfig(
    uint32 _newVotingPeriod,
    uint256 _newResetGracePeriod,
    uint256 _newRootExpirationThreshold
  ) public {
    // Check the `rootExpirationThreshold` is valid
    vm.assume(_newRootExpirationThreshold < _newResetGracePeriod);
    uint256 _rootHistoryExpiry = governance.WORLD_ID_ROUTER().routeFor(governance.GROUP_ID()).rootHistoryExpiry();
    vm.assume(_newRootExpirationThreshold < _rootHistoryExpiry);
    // Set the `votingPeriod` to a valid value
    _newVotingPeriod = uint32(bound(_newVotingPeriod, 1, _newResetGracePeriod - _newRootExpirationThreshold));

    vm.prank(address(governance));
    governance.setConfig(_newVotingPeriod, _newResetGracePeriod, _newRootExpirationThreshold);
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
    uint256 _newRootExpirationThreshold = _rootHistoryExpiry + 1;

    vm.expectRevert(IGovernorWorldID.GovernorWorldID_InvalidRootExpirationThreshold.selector);
    vm.prank(address(governance));
    governance.setConfig(_votingPeriod, _newResetGracePeriod, _newRootExpirationThreshold);
  }

  /**
   * @notice Test reverts when `votingPeriod` is greater than `resetGracePeriod` minus `rootExpirationThreshold`
   */
  function test_revertIfInvalidVotingPeriod() public {
    uint256 _newResetGracePeriod = governance.resetGracePeriod();
    uint256 _newRootExpirationThreshold = governance.rootExpirationThreshold();
    // Set the `votingPeriod` to an invalid value
    uint32 _newVotingPeriod = uint32(_newResetGracePeriod - _newRootExpirationThreshold + 1);

    vm.prank(address(governance));
    vm.expectRevert(IGovernorWorldID.GovernorWorldID_InvalidVotingPeriod.selector);
    governance.setConfig(_newVotingPeriod, _newResetGracePeriod, _newRootExpirationThreshold);
  }
}
