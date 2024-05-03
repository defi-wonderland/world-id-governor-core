// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.23;

abstract contract Constants {
  uint256 public constant GROUP_ID = 1;
  uint256 public constant QUORUM = 100;
  uint48 public constant INITIAL_VOTING_DELAY = 0;
  uint32 public constant INITIAL_VOTING_PERIOD = 7 days;
  uint256 public constant INITIAL_PROPOSAL_THRESHOLD = 0;
}
