// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IOnlineRouter {
    event NewGame(address game, address mng, uint256 gameId, string gameName);

    event NewGameScene(
        uint256 gameId,
        uint256 sceneId,
        string sceneName,
        address sender
    );

    event NewGameItem(
        uint256 sceneId,
        uint256 itemId,
        address pubkey,
        address sender
    );

    event PublishPrivateKey(uint256 itemId, bytes privateKey, address sender);

    event GameWrite(uint256 itemId, address player, bytes32 hv, bytes rv);

    function registGame(
        address game,
        string memory name,
        address oper
    ) external returns (uint256 gameId);

    function addScene(uint256 gameId, string memory name)
        external
        returns (uint256 sceneId);

    function addItem(uint256 sceneId, address pubkey)
        external
        returns (uint256 itemId);

    function publistAndNewItem(
        uint256 sceneId,
        uint256 oldItemId,
        bytes memory privateKey,
        address newPubKey
    ) external returns (uint256 newItemId);

    function nonces(uint256 itemId) external view returns (uint256);

    function gameinfo(uint256 itemId)
        external
        view
        returns (address gameAddr, address pubkey);

    function play(
        uint256 itemId,
        bytes32 hv,
        uint256 deadline,
        uint8[] calldata vs,
        bytes32[] calldata rs,
        bytes32[] calldata ss
    ) external returns (bytes memory rv);
}
