// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {DemocraticGovernance} from 'contracts/DemocraticGovernance.sol';
import {Script, console} from 'forge-std/Script.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';

contract DeploySepolia is Script {
  uint256 public constant GROUP_ID = 1;
  IWorldIDRouter public constant WORLD_ID_ROUTER = IWorldIDRouter(0x469449f251692E0779667583026b5A1E99512157);
  uint256 public constant QUORUM = 5;
  string public constant APP_ID = '';
  string public constant ACTION_ID = '';

  address public deployer = vm.rememberKey(vm.envUint('DEPLOYER_SEPOLIA_PRIVATE_KEY'));

  function run() public {
    vm.startBroadcast(deployer);

    // Deploy DemocraticGovernance
    DemocraticGovernance _democraticGovernance =
      new DemocraticGovernance(GROUP_ID, WORLD_ID_ROUTER, APP_ID, ACTION_ID, QUORUM);
    console.log('Democratic Governance deployed at:', address(_democraticGovernance));

    vm.stopBroadcast();
  }
}