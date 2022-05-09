// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./interface/IAsset1155.sol";

contract Asset1155 is
    ERC1155,
    AccessControl,
    ERC1155Pausable,
    ERC1155Burnable,
    ERC1155Supply,
    IAsset1155
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant APPR_ROLE = keccak256("APPR_ROLE");
    mapping(address => bool) public approvalWhitelists;
    mapping(uint256 => uint256) public upgradeablePrice;

    constructor(string memory _uri) ERC1155(_uri) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        upgradeablePrice[1] = 8;
        upgradeablePrice[2] = 8;
        upgradeablePrice[3] = 8;
    }

    function setURI(string memory newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newuri);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(
        address _to,
        uint256 _assetType,
        uint256 _amount
    ) public onlyRole(MINTER_ROLE) {
        require(_to != address(0), "Invalid address");
        require(_assetType > 0, "Invalid asset type");

        _mint(_to, _assetType, _amount, "");
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) override(IAsset1155, ERC1155Burnable) public {
        super.burn(account, id, value);
    }

    function mintBatch(
        address _to,
        uint256[] memory _assetTypes,
        uint256[] memory _amounts
    ) public onlyRole(MINTER_ROLE) {
        require(_to != address(0), "Invalid address");

        _mintBatch(_to, _assetTypes, _amounts, "");
    }

    function setUpgradePrice(uint256 _assetType, uint256 _price)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_assetType >= 1 && _assetType <= 3, "invalid land type");
        upgradeablePrice[_assetType] = _price;
    }

    function upgradeLand(uint256 _landType) public {
        require(_landType >= 1 && _landType <= 3, "invalid land type");
        burn(_msgSender(), _landType, upgradeablePrice[_landType]);
        _mint(_msgSender(), _landType + 1, 1, "");
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply, ERC1155Pausable) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override(ERC1155, IERC1155)
        returns (bool)
    {
        if (hasRole(APPR_ROLE, _msgSender())) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, IERC165, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
