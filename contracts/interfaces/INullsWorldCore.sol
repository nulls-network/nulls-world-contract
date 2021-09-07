// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface INullsWorldCore {
    function newItem(uint256 sceneId, address pubkey) external returns (uint256 itemId);
    function newScene( address addr , string memory name ) external returns (uint sceneId);
    function getNonce(uint256 itemId, bytes32 hv, address player) external returns(uint256 nonce);
}