// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../utils/Ownable.sol";
import "../utils/Counters.sol";
import "../ERC721.sol";
import "./NullWorldMarket.sol";

contract NullsPetToken is ERC721, Ownable, NullWorldMarket {
    using Counters for Counters.Counter;
    Counters.Counter private TokenIds;

    address Oper;
    string BaseURI = "https://nulls.world/pets/";

    mapping(uint256 => uint8) public Types; //Pet type , 0xff is god pet.

    modifier onlyOper() {
        require(msg.sender == Oper, "NullsPetToken/No oper role.");
        _;
    }

    constructor() ERC721("NullsPetToken", "NullsPet") {
        Oper = msg.sender;
    }

    function modifyOper(address oper) external onlyOwner {
        Oper = oper;
    }

    function mint(address player, uint8 tv)
        external
        onlyOper
        returns (uint256 tokenId)
    {
        tokenId = _useToken();
        Types[tokenId] = tv;
        _mint(player, tokenId);
    }

    function _useToken() internal returns (uint256 tid) {
        tid = TokenIds.current();
        TokenIds.increment();
    }

    function setBaseURI(string memory uri) public onlyOwner {
        BaseURI = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BaseURI;
    }

    function _SellApproved(uint256 petId) internal override {
        if (getApproved(petId) != address(this)) {
            approve(address(this), petId);
        }
    }

    function _MarketBuy(
        address from,
        address to,
        uint256 petId
    ) internal override {
        require(
            getApproved(petId) == address(this),
            "NullsPetTrade/Current pet is not approved."
        );
        _transfer(from, to, petId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 petId
    ) internal override {
        _unSellPet(petId);
    }
}
