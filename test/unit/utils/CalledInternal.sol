// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

contract InternalCallsWatcher {
  function calledInternal(bytes memory _encodedCall) external view {}
}

contract InternalCallsWatcherExtension {
  InternalCallsWatcher public watcher;
  bool internal _callSuper = true;

  constructor() {
    watcher = new InternalCallsWatcher();
  }

  function setCallSuper(bool __callSuper) external {
    _callSuper = __callSuper;
  }

  function _calledInternal(bytes memory _encodedCall) internal view {
    watcher.calledInternal(_encodedCall);
  }
}
