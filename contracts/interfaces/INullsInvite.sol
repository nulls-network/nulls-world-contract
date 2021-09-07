// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface INullsInvite {
    function onBuyEgg(address user, uint count) external;
    function getInvites(address user) external view returns(address one, uint8 oneType, address two, uint8 twoType, address three, uint threeType);
}