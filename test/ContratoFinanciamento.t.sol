// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/ContratoFinanciamento.sol";
import "../src/MockBRZ.sol";
import "../src/MockOraculo.sol";

contract ContratoFinanciamentoDNFTTest is Test {
    ContratoFinanciamentoDNFT contrato;
    MockBRZ brz;
    MockOraculo oraculo;

    address dono = address(this);
    address torcedor1 = address(0x1111);
    address torcedor2 = address(0x2222);

    function setUp() public {
        // Deploy do Mock BRZ e do contrato principal
        brz = new MockBRZ();
        contrato = new ContratoFinanciamentoDNFT(address(brz), "TorcidaNFT", "TNFT");

        // Deploy do mock do oráculo
        oraculo = new MockOraculo(address(contrato));
        contrato.definirOraculo(address(oraculo));

        // Transferir BRZ para torcedores
        brz.transfer(torcedor1, 2000 ether);
        brz.transfer(torcedor2, 2000 ether);

        // Criar camisas
        contrato.adicionarCamisa("Camisa Comum", ContratoFinanciamentoDNFT.Raridade.Comum);
        contrato.adicionarCamisa("Camisa Rara", ContratoFinanciamentoDNFT.Raridade.Rara);
        contrato.adicionarCamisa("Camisa Muito Rara", ContratoFinanciamentoDNFT.Raridade.MuitoRara);
    }

    // ------------------------
    // Testes de mint
    // ------------------------
    function testMintPrimeiraDoacao() public {
        vm.startPrank(torcedor1);
        brz.approve(address(contrato), 100 ether);

        uint256 tokenId = contrato.cunharComDoacao(100 ether);

        assertEq(contrato.ownerOf(tokenId), torcedor1);
        assertEq(contrato.balanceOf(torcedor1), 1);

        ContratoFinanciamentoDNFT.DadosDoador memory dd = contrato.obterDadosDoador(tokenId);
        assertEq(dd.totalDoado, 100 ether);
        assertEq(dd.qtdDoacoes, 1);

        vm.stopPrank();
    }

    function testApenasUmNFTPorUsuario() public {
        vm.startPrank(torcedor1);
        brz.approve(address(contrato), 500 ether);

        uint256 tokenId1 = contrato.cunharComDoacao(100 ether);
        uint256 tokenId2 = contrato.cunharComDoacao(200 ether);

        assertEq(tokenId1, tokenId2); // Mesmo tokenId
        assertEq(contrato.balanceOf(torcedor1), 1);

        vm.stopPrank();
    }

    // ------------------------
    // Testes de oráculo
    // ------------------------
    function testAdicionarJogosEGastosViaMockOraculo() public {
        vm.startPrank(torcedor1);
        brz.approve(address(contrato), 500 ether);
        uint256 tokenId = contrato.cunharComDoacao(100 ether);
        vm.stopPrank();

        // Usando MockOraculo
        oraculo.adicionarJogo(tokenId);
        oraculo.adicionarGasto(tokenId, 300 ether);

        ContratoFinanciamentoDNFT.DadosDoador memory dd = contrato.obterDadosDoador(tokenId);

        assertEq(dd.jogosAssistidos, 1);
        assertEq(dd.gastoEmProdutos, 300 ether);
        assertEq(uint256(dd.nivel), uint256(ContratoFinanciamentoDNFT.NivelDoador.Bronze));
    }

    // ------------------------
    // Testes de eventos
    // ------------------------
    function testEventoNFTCunhado() public {
        vm.startPrank(torcedor2);
        brz.approve(address(contrato), 100 ether);

        vm.expectEmit(true, true, true, false);
        emit ContratoFinanciamentoDNFT.NFTCunhado(1, torcedor2, 100 ether, 1);

        contrato.cunharComDoacao(100 ether);
        vm.stopPrank();
    }

    function testEventoCamisaCriada() public {
        vm.expectEmit(true, true, true, true);
        emit ContratoFinanciamentoDNFT.CamisaAdicionada(4, "Camisa Nova", ContratoFinanciamentoDNFT.Raridade.Comum);

        contrato.adicionarCamisa("Camisa Nova", ContratoFinanciamentoDNFT.Raridade.Comum);
    }

    // ------------------------
    // Testes administrativos
    // ------------------------
    function testDefinirLimites() public {
        contrato.definirLimites(100, 500, 1000);
        assertEq(contrato.limiteBronze(), 100);
        assertEq(contrato.limitePrata(), 500);
        assertEq(contrato.limiteOuro(), 1000);
    }

    function testSacarBRZ() public {
        vm.startPrank(torcedor1);
        brz.approve(address(contrato), 500 ether);
        contrato.cunharComDoacao(200 ether);
        vm.stopPrank();

        uint256 saldoInicial = brz.balanceOf(address(this));
        contrato.sacarBRZ(address(this), 200 ether);
        assertEq(brz.balanceOf(address(this)), saldoInicial + 200 ether);
    }

    // ------------------------
    // Testes de edge cases
    // ------------------------
    function testFalhaNenhumaCamisa() public {
        ContratoFinanciamentoDNFT contratoVazio = new ContratoFinanciamentoDNFT(address(brz), "EmptyNFT", "ENFT");
        vm.startPrank(torcedor1);
        brz.approve(address(contratoVazio), 100 ether);
        vm.expectRevert("Nenhuma camisa cadastrada");
        contratoVazio.cunharComDoacao(100 ether);
        vm.stopPrank();
    }

    function testFalhaAdicionarJogoSemNFT() public {
        vm.expectRevert("NFT inexistente");
        oraculo.adicionarJogo(999);
    }

    function testFalhaAdicionarGastoSemNFT() public {
        vm.expectRevert("NFT inexistente");
        oraculo.adicionarGasto(999, 100 ether);
    }

    // ------------------------
    // Teste de reset automático de nível
    // ------------------------
    function testResetNivelAutomatico() public {
        vm.startPrank(torcedor1);
        brz.approve(address(contrato), 1000 ether);
        uint256 tokenId = contrato.cunharComDoacao(500 ether);

        oraculo.adicionarGasto(tokenId, 300 ether);
        oraculo.adicionarJogo(tokenId);
        vm.stopPrank();

        // Confirma nível atualizado
        ContratoFinanciamentoDNFT.DadosDoador memory dd = contrato.obterDadosDoador(tokenId);
        assertEq(uint256(dd.nivel), uint256(ContratoFinanciamentoDNFT.NivelDoador.Bronze));

        // Avança 91 dias
        vm.warp(block.timestamp + 91 days);

        // Chama reset manual
        contrato.resetNivelInativos();

        dd = contrato.obterDadosDoador(tokenId);
        assertEq(uint256(dd.nivel), uint256(ContratoFinanciamentoDNFT.NivelDoador.Nenhum));
    }

    // ------------------------
    // Teste de seleção ponderada de camisas
    // ------------------------
    function testDistribuicaoCamisas() public {
        // Adiciona camisas usando a instância do contrato
        contrato.adicionarCamisa("Camisa Comum", ContratoFinanciamentoDNFT.Raridade.Comum);
        contrato.adicionarCamisa("Camisa Rara", ContratoFinanciamentoDNFT.Raridade.Rara);
        contrato.adicionarCamisa("Camisa Muito Rara", ContratoFinanciamentoDNFT.Raridade.MuitoRara);

        uint256 totalComum = 0;
        uint256 totalRara = 0;
        uint256 totalMuitoRara = 0;

        // Simula 1000 pseudo-aleatoriedades
        for (uint256 i = 0; i < 1000; i++) {
            uint256 seed = i + 1; // seeds simples e previsíveis

            // Chama a função pública de teste no contrato
            uint256 camisaId = contrato.selecionarCamisaPonderadaTeste(seed);
            (, ContratoFinanciamentoDNFT.Raridade raridade, ) = contrato.camisas(camisaId);

            if (raridade == ContratoFinanciamentoDNFT.Raridade.Comum) totalComum++;
            else if (raridade == ContratoFinanciamentoDNFT.Raridade.Rara) totalRara++;
            else totalMuitoRara++;
        }

        emit log_named_uint("Total Comum", totalComum);
        emit log_named_uint("Total Rara", totalRara);
        emit log_named_uint("Total Muito Rara", totalMuitoRara);

        // Verifica distribuição aproximada com tolerância de 10%
        assertApproxEqRel(totalComum, 700, 0.1e18);     // 70% do total
        assertApproxEqRel(totalRara, 250, 0.1e18);      // 25% do total
        assertApproxEqRel(totalMuitoRara, 50, 0.1e18);  // 5% do total
    }
}

