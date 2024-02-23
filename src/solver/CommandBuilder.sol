// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// solhint-disable no-inline-assembly

// slither-disable-start assembly,cyclomatic-complexity,dead-code

library CommandBuilder {
    uint256 public constant IDX_VARIABLE_LENGTH = 0x80;
    uint256 public constant IDX_VALUE_MASK = 0x7f;
    uint256 public constant IDX_END_OF_ARGS = 0xff;
    uint256 public constant IDX_USE_STATE = 0xfe;

    // Error thrown when dynamic state variables is not a multiple of 32 bytes
    error DynamicStateVariableLengthInvalid();
    // Error thrown when static state variables is not 32 bytes
    error StaticStateVariableLengthInvalid();
    // Error thrown when more than one return value is encountered for a variable-length return
    error SingleReturnValuePermittedVariable();
    // Error thrown when more than one return value is encountered for a static return
    error SingleReturnValuePermittedStatic();

    function buildInputs(
        bytes[] memory state,
        bytes4 selector,
        bytes32 indices
    ) internal view returns (bytes memory ret) {
        uint256 count; // Number of bytes in whole ABI encoded message
        uint256 free; // Pointer to first free byte in tail part of message
        bytes memory stateData; // Optionally encode the current state if the call requires it

        uint256 idx;

        // Determine the length of the encoded data
        for (uint256 i; i < 32;) {
            idx = uint8(indices[i]);
            if (idx == IDX_END_OF_ARGS) break;

            if (idx & IDX_VARIABLE_LENGTH != 0) {
                if (idx == IDX_USE_STATE) {
                    if (stateData.length == 0) {
                        stateData = abi.encode(state);
                    }
                    count += stateData.length;
                } else {
                    // Add the size of the value, rounded up to the next word boundary, plus space for pointer and
                    // length
                    uint256 arglen = state[idx & IDX_VALUE_MASK].length;
                    if (arglen % 32 != 0) {
                        revert DynamicStateVariableLengthInvalid();
                    }
                    count += arglen + 32;
                }
            } else {
                if (state[idx & IDX_VALUE_MASK].length != 32) {
                    revert StaticStateVariableLengthInvalid();
                }
                count += 32;
            }
            unchecked {
                free += 32;
            }
            unchecked {
                ++i;
            }
        }

        // Encode it
        ret = new bytes(count + 4);
        assembly {
            mstore(add(ret, 32), selector)
        }
        count = 0;
        for (uint256 i; i < 32;) {
            idx = uint8(indices[i]);
            if (idx == IDX_END_OF_ARGS) break;

            if (idx & IDX_VARIABLE_LENGTH != 0) {
                if (idx == IDX_USE_STATE) {
                    assembly {
                        mstore(add(add(ret, 36), count), free)
                    }
                    memcpy(stateData, 32, ret, free + 4, stateData.length - 32);
                    free += stateData.length - 32;
                } else {
                    bytes memory stateVar = state[idx & IDX_VALUE_MASK];
                    uint256 arglen = stateVar.length;

                    // Variable length data; put a pointer in the slot and write the data at the end
                    assembly {
                        mstore(add(add(ret, 36), count), free)
                    }
                    memcpy(stateVar, 0, ret, free + 4, arglen);
                    free += arglen;
                }
            } else {
                // Fixed length data; write it directly
                bytes memory stateVal = state[idx & IDX_VALUE_MASK];
                assembly {
                    mstore(add(add(ret, 36), count), mload(add(stateVal, 32)))
                }
            }
            unchecked {
                count += 32;
            }
            unchecked {
                ++i;
            }
        }
    }

    function writeOutputs(
        bytes[] memory state,
        bytes1 index,
        bytes memory output
    ) internal pure returns (bytes[] memory) {
        uint256 idx = uint8(index);
        if (idx == IDX_END_OF_ARGS) return state;

        if (idx & IDX_VARIABLE_LENGTH != 0) {
            if (idx == IDX_USE_STATE) {
                state = abi.decode(output, (bytes[]));
            } else {
                // Check the first field is 0x20 (because we have only a single return value)
                uint256 argptr;
                assembly {
                    argptr := mload(add(output, 32))
                }
                if (argptr != 32) {
                    revert SingleReturnValuePermittedVariable();
                }

                assembly {
                    // Overwrite the first word of the return data with the length - 32
                    mstore(add(output, 32), sub(mload(output), 32))
                    // Insert a pointer to the return data, starting at the second word, into state
                    mstore(add(add(state, 32), mul(and(idx, IDX_VALUE_MASK), 32)), add(output, 32))
                }
            }
        } else {
            // Single word
            if (output.length != 32) {
                revert SingleReturnValuePermittedStatic();
            }

            state[idx & IDX_VALUE_MASK] = output;
        }

        return state;
    }

    function writeTuple(bytes[] memory state, bytes1 index, bytes memory output) internal view {
        uint256 idx = uint256(uint8(index));
        if (idx == IDX_END_OF_ARGS) return;

        bytes memory entry = state[idx] = new bytes(output.length + 32);
        memcpy(output, 0, entry, 32, output.length);
        assembly {
            let l := mload(output)
            mstore(add(entry, 32), l)
        }
    }

    function memcpy(bytes memory src, uint256 srcidx, bytes memory dest, uint256 destidx, uint256 len) internal view {
        assembly {
            pop(staticcall(gas(), 4, add(add(src, 32), srcidx), len, add(add(dest, 32), destidx), len))
        }
    }
}
// slither-disable-end assembly,cyclomatic-complexity,dead-code
