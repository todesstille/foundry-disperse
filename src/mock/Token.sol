// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("Mock Token", "MCK") {
        _mint(msg.sender, 10 ** (6 + decimals()));
    }
}