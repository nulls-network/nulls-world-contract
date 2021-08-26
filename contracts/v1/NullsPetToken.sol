// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../utils/Ownable.sol";
import "../utils/Counters.sol";
import "../ERC721.sol";

contract NullsPetToken is ERC721 , Ownable {
    
    using Counters for Counters.Counter;
    Counters.Counter private TokenIds;

    address Oper ;
    string BaseURI = "https://nulls.world/pets/";

    mapping( uint => uint8 ) public Types ;     //Pet type , 0xff is god pet.

    modifier onlyOper() {
        require( msg.sender == Oper , "NullsPetToken/No oper role." ) ;
        _ ;
    }

    constructor() ERC721("NullsPetToken" , "NullsPet"){
        Oper = msg.sender ;
    }

    function modifyOper( address oper ) external onlyOwner {
        Oper = oper ;
    }

    function mint( address player , uint8 tv ) external onlyOper returns ( uint tokenId ) {
        tokenId = _useToken()  ;
        Types[tokenId] = tv ;
        _mint( player , tokenId ) ;
    }

    function _useToken() internal returns ( uint tid ) {
        tid = TokenIds.current();
        TokenIds.increment();
    }

    function setBaseURI(string memory uri ) public onlyOwner {
        BaseURI = uri ;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BaseURI;
    }

}