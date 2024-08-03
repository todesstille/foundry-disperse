// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestDisperser {
    struct DisperseInfo {
        address token;
        address[] destinations;
        uint256[] amounts;
    }

    address immutable owner;

    constructor() {
        owner = msg.sender;
    }

    function disperse(DisperseInfo[] calldata infos) external {
        require(msg.sender == owner, "Ownable: not from owner");
        
        for (uint i = 0; i < infos.length; i++) {
            IERC20 token = IERC20(infos[i].token);
            for (uint j = 0; j < infos[i].destinations.length; j++) {
                if (token != IERC20(address(0))) {
                    token.transfer(infos[i].destinations[j], infos[i].amounts[j]);
                } else {
                    (bool ok,) = infos[i].destinations[j].call{value: infos[i].amounts[j]}("");
                    if (!ok) {
                        revert();
                    }
                }
            }
        }
    }

    receive() external payable {}
}