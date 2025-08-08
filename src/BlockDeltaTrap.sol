// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ITrap.sol";

contract BlockDeltaTrap is ITrap {
    uint256 public constant DELTA_THRESHOLD = 0;

    struct CollectOutput {
        uint256 blockNumber;
    }

    constructor() {}

    function collect() external view override returns (bytes memory) {
        return abi.encode(CollectOutput({
            blockNumber: block.number
        }));
    }

    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        if (data.length < 2) return (false, "Insufficient block history");

        CollectOutput memory current = abi.decode(data[0], (CollectOutput));
        CollectOutput memory previous = abi.decode(data[1], (CollectOutput));

        uint256 delta = current.blockNumber - previous.blockNumber;

        if (delta > DELTA_THRESHOLD) {
            return (
                true,
                abi.encode(current.blockNumber, previous.blockNumber)
            );
        }

        return (false, "");
    }
}
