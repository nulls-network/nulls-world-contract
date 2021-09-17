// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../utils/Ownable.sol";
import "../interfaces/ITransferProxy.sol";

// ERC20、ERC721转账代理合约
// 此合约作为统一授权代理合约
contract ErcProxy is Ownable, ITransferProxy  {

    // 允许调用此合约的合约名单
    mapping(address => bool) WhiteList;

    function addWhiteList(address addr) external onlyOwner {
        WhiteList[addr] = true;
    }

    function removeWhileList(address addr) external onlyOwner {
        delete WhiteList[addr];
    }

    modifier onlyWhiteList() {
        require(WhiteList[msg.sender], "ErcProxy/No access.");
        _;
    }

    function _safeTransferFrom(address contractAddr, address sender, address recipient, uint256 amountOrTokenId) internal {
        // 23b872dd  =>  transferFrom(address,address,uint256)  
        (bool success, bytes memory data) = contractAddr.call(abi.encodeWithSelector(0x23b872dd, sender, recipient, amountOrTokenId));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function erc20TransferFrom(address contractAddr, address sender, address recipient, uint256 amount) external override onlyWhiteList {
        _safeTransferFrom(contractAddr, sender, recipient, amount);
    }

    function erc721TransferFrom(address contractAddr, address sender, address recipient, uint tokenId) external override onlyWhiteList {
        _safeTransferFrom(contractAddr, sender, recipient, tokenId);
    }
}