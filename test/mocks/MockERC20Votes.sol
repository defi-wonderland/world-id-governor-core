// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC20} from 'open-zeppelin/token/ERC20/ERC20.sol';
import {ERC20Permit} from 'open-zeppelin/token/ERC20/extensions/ERC20Permit.sol';
import {ERC20Votes} from 'open-zeppelin/token/ERC20/extensions/ERC20Votes.sol';
import {Nonces} from 'open-zeppelin/utils/Nonces.sol';

contract MockERC20Votes is ERC20, ERC20Permit, ERC20Votes {
  constructor() ERC20('MyToken', 'MTK') ERC20Permit('MyToken') {}

  function mint(address to, uint256 amount) public {
    _mint(to, amount);
  }

  function nonces(address owner) public view override(ERC20Permit, Nonces) returns (uint256) {
    return super.nonces(owner);
  }

  function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
    super._update(from, to, value);
  }
}
