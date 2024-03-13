// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {DemocraticGovernance} from 'contracts/DemocraticGovernance.sol';
import {DemocraticToken} from 'contracts/DemocraticToken.sol';
import {Script, console} from 'forge-std/Script.sol';
import {IWorldIDRouter} from 'interfaces/IWorldIDRouter.sol';
import {IVotes} from 'open-zeppelin/governance/utils/IVotes.sol';

contract DeploySepolia is Script {
  uint256 public constant GROUP_ID = 1;
  IWorldIDRouter public constant WORLD_ID_ROUTER = IWorldIDRouter(0x469449f251692E0779667583026b5A1E99512157);
  string public constant APP_ID = '';
  string public constant ACTION_ID = '';

  address public deployer = vm.rememberKey(vm.envUint('DEPLOYER_SEPOLIA_PRIVATE_KEY'));

  function run() public {
    vm.startBroadcast(deployer);

    // Deploy Token
    DemocraticToken _token = new DemocraticToken();
    console.log('Token deployed at:', address(_token));

    // Deploy DemocraticGovernance
    DemocraticGovernance _democraticGovernance =
      new DemocraticGovernance(GROUP_ID, WORLD_ID_ROUTER, APP_ID, ACTION_ID, IVotes(address(_token)));
    console.log('Democratic Governance deployed at:', address(_democraticGovernance));

    vm.stopBroadcast();
  }
}
