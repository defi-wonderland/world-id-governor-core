// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.23;

import {GoatsDAO} from 'contracts/example/GoatsDAO.sol';
import {Test} from 'forge-std/Test.sol';
import {IERC20} from 'open-zeppelin/token/ERC20/IERC20.sol';
import {Common} from 'test/Common.sol';

/* solhint-disable reentrancy */
contract IntegrationBase is Test, Common {
  // Contracts, addresses and other values
  GoatsDAO public governance;
  address public owner = makeAddr('owner');
  address public user = makeAddr('user');
  address public userTwo = makeAddr('userTwo');
  address public stranger = makeAddr('stranger');
  bytes public proofDataOne;
  bytes public proofDataTwo;

  function setUp() public virtual {
    vm.createSelectFork(vm.rpcUrl('optimism'), forkBlock);

    // Deploy a GoatsDAO instance
    vm.prank(owner);
    governance = new GoatsDAO(
      GROUP_ID,
      WORLD_ID_ROUTER,
      APP_ID,
      QUORUM,
      INITIAL_VOTING_DELAY,
      INITIAL_VOTING_PERIOD,
      INITIAL_PROPOSAL_THRESHOLD,
      rootExpirationThreshold
    );

    // Create a proposal to donate 250 WLD tokens
    address[] memory targets = new address[](1);
    targets[0] = WLD;
    uint256[] memory values = new uint256[](1);
    values[0] = 0;
    bytes[] memory calldatas = new bytes[](1);
    calldatas[0] = abi.encodeWithSelector(IERC20.transfer.selector, GOAT_GUY, WLD_AMOUNT);
    string memory description =
      'Donate 250WLD tokens to the Goat guy, so he can buy some more goats and build a shelter';

    // Create the proposal and assert is the same as the one used as action id while generating proofs
    vm.prank(owner);
    uint256 _proposalId = governance.propose(targets, values, calldatas, description);
    assert(_proposalId == PROPOSAL_ID);

    // Advance the time to make the proposal active
    vm.warp(block.timestamp + INITIAL_VOTING_DELAY + 1);

    // Pack all the first proof data together
    proofDataOne = abi.encodePacked(ROOT_ONE, NULLIFIER_HASH_ONE, proofOne);
    // Pack all the second proof data together
    proofDataTwo = abi.encodePacked(ROOT_TWO, NULLIFIER_HASH_TWO, proofTwo);
  }
}
