// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BlockDeltaTrap {
    event BlockDelta(uint256 previousBlock, uint256 currentBlock);

    uint256 public lastBlock;

    constructor() {
        lastBlock = block.number;
    }

    function checkBlockDelta() public {
        uint256 delta = block.number - lastBlock;
        emit BlockDelta(lastBlock, block.number);
        lastBlock = block.number;
    }
}
