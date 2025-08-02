// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BlockAlertReceiver {
    event Alert(string message);

    function logBlockChange(uint256 currentBlock, uint256 previousBlock) external {
        string memory message = string(
            abi.encodePacked(
                "Block changed from #",
                uintToString(previousBlock),
                " to #",
                uintToString(currentBlock)
            )
        );
        emit Alert(message);
    }

    function uintToString(uint256 v) internal pure returns (string memory str) {
        if (v == 0) return "0";
        uint256 maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint256 i = 0;
        while (v != 0) {
            uint8 remainder = uint8(v % 10);
            v = v / 10;
            reversed[i++] = bytes1(48 + remainder);
        }
        bytes memory s = new bytes(i);
        for (uint256 j = 0; j < i; j++) {
            s[j] = reversed[i - j - 1];
        }
        str = string(s);
    }
}
