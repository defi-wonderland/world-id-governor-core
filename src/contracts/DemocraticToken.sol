// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC20} from 'open-zeppelin/token/ERC20/ERC20.sol';

/**
 * @title DemocraticToken
 * @notice Implementation of the DemocraticToken contract
 */
contract DemocraticToken is ERC20 {
  constructor() ERC20('DemocraticToken', 'DTKN') {}
}
