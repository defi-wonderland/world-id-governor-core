// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.23;

abstract contract Constants {
  uint256 constant GROUP_ID = 1;
  uint256 constant QUORUM = 5;
  uint48 constant INITIAL_VOTING_DELAY = 1;
  uint32 constant INITIAL_VOTING_PERIOD = 3 days;
  uint256 constant INITIAL_PROPOSAL_THRESHOLD = 0;
}
