// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {DemocraticGovernance} from 'contracts/DemocraticGovernance.sol';
import {Script, console} from 'forge-std/Script.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';

contract DeploySepolia is Script {
  uint256 public constant GROUP_ID = 1;
  IWorldIDRouter public constant WORLD_ID_ROUTER = IWorldIDRouter(0x469449f251692E0779667583026b5A1E99512157);
  uint256 public constant QUORUM = 5;
  bytes public constant APP_ID = '';
  uint48 public constant INITIAL_VOTING_DELAY = 1 days;
  uint32 public constant INITIAL_VOTING_PERIOD = 3 days;
  uint256 public constant INITIAL_PROPOSAL_THRESHOLD = 1;

  address public deployer = vm.rememberKey(vm.envUint('DEPLOYER_SEPOLIA_PRIVATE_KEY'));

  function run() public {
    vm.startBroadcast(deployer);

    // Deploy DemocraticGovernance
    DemocraticGovernance _democraticGovernance =
    new DemocraticGovernance(GROUP_ID, WORLD_ID_ROUTER, APP_ID, QUORUM, INITIAL_VOTING_DELAY, INITIAL_VOTING_PERIOD, INITIAL_PROPOSAL_THRESHOLD);
    console.log('Democratic Governance deployed at:', address(_democraticGovernance));

    vm.stopBroadcast();
  }
}
