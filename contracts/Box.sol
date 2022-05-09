// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IAsset1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Box is Ownable {
    // params and mappings
    IAsset1155 private box;

    IERC721 private token;

    address private receiver;

    uint256 public unboxFee;

    mapping(address => uint256) public openBoxSigNonces;

    bytes32 public constant OPEN_BOX_WITH_SIG_TYPEHASH =
        keccak256(
            "ClaimAirDropWithSig(uint256 landId,uint256 nonce,uint256 deadline)"
        );

    // structs and events
    struct EIP712Signature {
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    event OpenBox(address _user, uint256 landId, uint256 amount);

    // constructor and functions
    constructor(
        address _boxAddress,
        address _tokenAddress,
        address _receiver,
        uint256 _unboxFee
    ) {
        box = IAsset1155(_boxAddress);
        token = IERC721(_tokenAddress);
        receiver = _receiver;
        unboxFee = _unboxFee;
    }

    function setBoxInfo(
        address _boxAddress,
        address _tokenAddress,
        address _receiver
    ) external onlyOwner {
        box = IAsset1155(_boxAddress);
        token = IERC721(_tokenAddress);
        receiver = _receiver;
    }

    function setUnboxFee(uint256 _unboxFee) external onlyOwner {
        unboxFee = _unboxFee;
    }

    function setReceiver(address _receiver) external onlyOwner {
        receiver = _receiver;
    }

    function openBox(uint256 _amount) external {
        box.mint(msg.sender, 1, _amount);
        token.transferFrom(msg.sender, receiver, unboxFee * _amount);
    }
}