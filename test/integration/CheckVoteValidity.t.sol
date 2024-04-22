// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.23;

import {IntegrationBase} from './IntegrationBase.sol';

contract Integration_CheckVoteValidity is IntegrationBase {
  /**
   * @notice Test the call to `checkVoteValidity` succeeds with a valid proof
   */
  function test_callSucceeds() public {
    // Use a valid vote to be checked
    vm.prank(user);
    uint256 _nullifierHash = governance.checkVoteValidity(FOR_SUPPORT, PROPOSAL_ID, proofData);
    // Assert the nullifier hash is the expected one
    assertEq(_nullifierHash, NULLIFIER_HASH);
  }
}
