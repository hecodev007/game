pragma solidity =0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract UsToken is ERC20, Ownable {



    // uint256 private _totalSupply;
    constructor(string memory name_, string memory symbol_)
    public ERC20(name_, symbol_) {
        _mint(msg.sender, 2.565e26);
    }
}