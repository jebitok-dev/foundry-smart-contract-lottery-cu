// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract LinkToken is ERC20 {
    constructor() ERC20("LinkToken", "LINK") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}
