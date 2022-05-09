// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VirtualPropertyRight is ERC20, Ownable {
    constructor() ERC20("VirtualPropertyRight", "VPR") {
        _mint(msg.sender, 20000000000 * 10**decimals());
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}
