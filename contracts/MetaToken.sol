//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0 <0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC20WithPermit.sol";

contract MetaToken is ERC20WithPermit, Ownable {
    constructor(uint256 initialSupply) ERC20WithPermit("META Token", "META") {
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
