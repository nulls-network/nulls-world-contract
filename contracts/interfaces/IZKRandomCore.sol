// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IZKRandomCore {
    function regist(
        string memory name,
        address oper,
        uint256 depositAmt
    ) external returns (uint256 projectId);

    function accept(
        address callback,
        uint256 itemId,
        bytes32 hv
    ) external returns (bytes32 requestKey);

    function generateRandom(
        bytes32 key,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bytes32 rv);

    function newItem(
        uint256 projectId,
        address caller,
        address pubkey
    ) external returns (uint256 itemId);
}
