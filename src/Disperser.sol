// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Disperser {
    bytes32 constant transferSelector = hex"a9059cbb00000000000000000000000000000000000000000000000000000000";
    address immutable owner;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    fallback() external payable {
        uint256 calldataCounter = 1;
        require(msg.sender == owner);

        assembly {
            mstore(0, transferSelector)

            let tokensNumber := byte(0, calldataload(0))
            for {let i := 0} lt(i, tokensNumber) {i := add(i, 1)} {
                
                let token := calldataload(calldataCounter)
                token := shr(96, token)
                calldataCounter := add(calldataCounter, 20)

                let destinationsNumber := byte(0, calldataload(calldataCounter))
                calldataCounter := add(calldataCounter, 1)
                
                for {let j := 0} lt(j, destinationsNumber) {j := add(j, 1)} {
                    let destination := calldataload(calldataCounter)
                    destination := shr(96, destination)
                    calldataCounter := add(calldataCounter, 20)

                    let amount := calldataload(calldataCounter)
                    calldataCounter := add(calldataCounter, 32)

                    if eq(token, 0) {
                        let success := call(gas(), destination, amount, 0, 0, 0, 0)
                        if iszero(success) {
                            revert(0, 0)
                        }
                    }

                    if iszero(eq(token, 0)) {
                        mstore(4, destination)
                        mstore(36, amount)

                        let success := call(gas(), token, 0, 0, 68, 0, 0)

                        if iszero(success) {
                            revert(0, 0)
                        }
                    }
                }
            }
        }
    }
}
