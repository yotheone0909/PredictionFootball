// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {

     constructor(string memory nameToken, string memory symbol) ERC20(nameToken, symbol) {

     }

     function _mint(uint256 initialSupply) public onlyOwner {
         _mint(msg.sender, initialSupply);
     }

}