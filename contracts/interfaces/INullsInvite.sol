// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface INullsInvite {
    function doAfter(address user, uint count) external ;
    function getInviteStatistics( address addr ) external view returns ( uint32 one , uint32 two , uint32 three , address superior , bool isPartner ) ;
} 