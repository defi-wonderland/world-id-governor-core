// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.23;

import {GoatsDAO} from 'contracts/example/GoatsDAO.sol';
import {Test} from 'forge-std/Test.sol';
import {IERC20} from 'open-zeppelin/token/ERC20/IERC20.sol';
import {Common} from 'test/Common.sol';

/* solhint-disable reentrancy */
contract E2EBase is Test, Common {
  /* DAO constant settings */
  uint256 public constant GOATS_DAO_QUORUM = 2;

  /* Proposal Data */
  address[] public targets;
  uint256[] public values;
  bytes[] public calldatas;
  string public description;

  // Contracts, addresses and other values
  GoatsDAO public governance;
  address public owner = makeAddr('owner');
  address public userOne = makeAddr('userOne');
  address public userTwo = makeAddr('userTwo');
  address public stranger = makeAddr('stranger');
  bytes public userOneProofData;
  bytes public userTwoProofData;

  function setUp() public virtual {
    vm.createSelectFork(vm.rpcUrl('optimism'), forkBlock);

    // Deploy a GoatsDAO instance
    vm.prank(owner);
    governance = new GoatsDAO(
      GROUP_ID,
      WORLD_ID_ROUTER,
      APP_ID,
      GOATS_DAO_QUORUM,
      INITIAL_VOTING_DELAY,
      INITIAL_VOTING_PERIOD,
      INITIAL_PROPOSAL_THRESHOLD,
      rootExpirationThreshold
    );

    // Transfer the amount from the holder to the DAO
    vm.prank(WLD_HOLDER);
    IERC20(WLD).transfer(address(governance), WLD_AMOUNT);

    // Set the proposal data
    targets = new address[](1);
    targets[0] = WLD;

    values = new uint256[](1);
    values[0] = 0;

    calldatas = new bytes[](1);
    calldatas[0] = abi.encodeWithSelector(IERC20.transfer.selector, GOAT_GUY, WLD_AMOUNT);

    description = 'Donate 250WLD tokens to the Goat guy, so he can buy some more goats and build a shelter';

    // Pack the all the proof data together
    userOneProofData = abi.encodePacked(ROOT_ONE, NULLIFIER_HASH_ONE, proofOne);
    userTwoProofData = abi.encodePacked(ROOT_TWO, NULLIFIER_HASH_TWO, proofTwo);
  }
}
