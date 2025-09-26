// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract MockAAVE is ERC20 {
    constructor() ERC20("Mock Aave Token", "AAVE") {
        _mint(msg.sender, 100000 * 10**18);
    }
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract MockCOMP is ERC20 {
    constructor() ERC20("Mock Compound Token", "COMP") {
        _mint(msg.sender, 100000 * 10**18);
    }
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract MockCRV is ERC20 {
    constructor() ERC20("Mock Curve Token", "CRV") {
        _mint(msg.sender, 100000 * 10**18);
    }
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract MockYFI is ERC20 {
    constructor() ERC20("Mock Yearn Token", "YFI") {
        _mint(msg.sender, 10000 * 10**18);
    }
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}