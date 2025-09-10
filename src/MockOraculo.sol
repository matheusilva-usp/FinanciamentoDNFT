// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ContratoFinanciamento.sol";

contract MockOraculo {
    ContratoFinanciamentoDNFT public contrato;

    constructor(address contratoAddr) {
        contrato = ContratoFinanciamentoDNFT(contratoAddr);
    }

    function adicionarJogo(uint256 tokenId) external {
        contrato.oraculoAdicionarJogo(tokenId);
    }

    function adicionarGasto(uint256 tokenId, uint256 valor) external {
        contrato.oraculoAdicionarGastoProdutos(tokenId, valor);
    }
}

