// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockBRZ is ERC20 {
    constructor() ERC20("Brazilian Digital Token", "BRZ") {
        // Cunha 1 milhão de tokens para o criador do contrato
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }

    function cunhar(address para, uint256 valor) external {
        _mint(para, valor);
    }
}

