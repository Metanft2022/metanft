// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IAsset1155 is IERC1155 {
    function mint(address _to, uint256 _assetType, uint256 _amount) external;

    function burn(address _account, uint256 _id, uint256 _value) external;
}