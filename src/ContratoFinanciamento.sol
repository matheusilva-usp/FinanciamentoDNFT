// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
ContratoFinanciamentoDNFT.sol
dNFT para financiamento coletivo esportivo
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ContratoFinanciamentoDNFT is ERC721, Ownable {
    uint256 private contadorIds;

    enum NivelDoador { Nenhum, Bronze, Prata, Ouro }

    struct DadosDoador {
        uint256 totalDoado;
        uint256 qtdDoacoes;
        uint256 ultimaDoacao;
        uint16 jogosAssistidos;
        uint256 ultimaDataJogo;
        uint256 gastoEmProdutos;
        uint256 tokenIdCamisa;
        NivelDoador nivel;
    }

    enum Raridade { Comum, Rara, MuitoRara }

    struct Camisa {
        string nome;
        Raridade raridade;
        bool existe;
    }

    IERC20 public tokenBRZ;
    address public oraculo;

    // Mapeamentos principais
    mapping(uint256 => DadosDoador) private _doadores;
    mapping(address => uint256) public torcedorParaToken; // garante 1 NFT por usuário
    mapping(uint256 => Camisa) public camisas;
    mapping(uint256 => uint256) public tokenParaCamisa;

    uint256 public qtdCamisas;

    // Limites de classificação
    uint256 public limiteBronze;
    uint256 public limitePrata;
    uint256 public limiteOuro;

    // URI base
    string private _uriBase;

    // Eventos
    event NFTCunhado(uint256 indexed tokenId, address indexed dono, uint256 valor, uint256 camisaId);
    event DoacaoRealizada(uint256 indexed tokenId, address indexed doador, uint256 valor);
    event OraculoAtualizado(address indexed novoOraculo);
    event DadoExternoAtualizado(uint256 indexed tokenId, string campo, uint256 valor);
    event CamisaAdicionada(uint256 indexed camisaId, string nome, Raridade raridade);

    constructor(
        address enderecoBRZ,
        string memory nome_,
        string memory simbolo_
    ) ERC721(nome_, simbolo_) Ownable(msg.sender) {
        require(enderecoBRZ != address(0), "Endereco BRZ invalido");
        tokenBRZ = IERC20(enderecoBRZ);

        limiteBronze = 50 * 10**18;
        limitePrata = 200 * 10**18;
        limiteOuro = 500 * 10**18;

        qtdCamisas = 0;
    }

    // ========== Camisas ==========
    function adicionarCamisa(string calldata nome, Raridade raridade) external onlyOwner {
        qtdCamisas++;
        camisas[qtdCamisas] = Camisa({nome: nome, raridade: raridade, existe: true});
        emit CamisaAdicionada(qtdCamisas, nome, raridade);
    }

    function _selecionarCamisaPonderada(uint256 salt) internal view returns (uint256) {
        require(qtdCamisas > 0, "Nenhuma camisa cadastrada");

        uint256 totalPeso = 0;
        for (uint256 i = 1; i <= qtdCamisas; i++) {
            if (!camisas[i].existe) continue;
            if (camisas[i].raridade == Raridade.Comum) totalPeso += 70;
            else if (camisas[i].raridade == Raridade.Rara) totalPeso += 25;
            else totalPeso += 5;
        }

        uint256 aleatorio = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, salt))) % totalPeso;
        uint256 acumulado = 0;

        for (uint256 i = 1; i <= qtdCamisas; i++) {
            if (!camisas[i].existe) continue;
            uint256 peso = (camisas[i].raridade == Raridade.Comum) ? 70 :
                           (camisas[i].raridade == Raridade.Rara) ? 25 : 5;
            acumulado += peso;
            if (aleatorio < acumulado) {
                return i;
            }
        }

        return 1;
    }

    // ========== Mint & Doações ==========
    function cunharComDoacao(uint256 valor) external returns (uint256) {
        require(qtdCamisas > 0, "Nenhuma camisa cadastrada");
        require(valor > 0, "Valor invalido");

        // Transfere BRZ do usuário para o contrato
        require(tokenBRZ.transferFrom(msg.sender, address(this), valor), "Falha transferencia BRZ");

        uint256 tokenId = torcedorParaToken[msg.sender];

        // Se não houver NFT, cria um novo
        if (tokenId == 0) {
            contadorIds += 1;
            tokenId = contadorIds;
            _safeMint(msg.sender, tokenId);
            torcedorParaToken[msg.sender] = tokenId;
        }

        // Atualiza dados do doador
        DadosDoador storage dd = _doadores[tokenId];
        dd.totalDoado += valor;
        dd.qtdDoacoes += 1;
        dd.ultimaDoacao = block.timestamp;
        _atualizarNivel(dd);

        // Seleciona camisa usando pseudo-aleatoriedade
        if (tokenParaCamisa[tokenId] == 0) { // só se ainda não tiver camisa
            uint256 salt = uint256(keccak256(abi.encodePacked(block.timestamp, tokenId, msg.sender)));
            tokenParaCamisa[tokenId] = _selecionarCamisaPonderadaComSeed(salt);
        }

        emit NFTCunhado(tokenId, msg.sender, valor, tokenParaCamisa[tokenId]);

        return tokenId;
    }

    // Função interna que faz toda a lógica ponderada sem VRF
    function _selecionarCamisaPonderadaComSeed(uint256 seed) private view returns (uint256) {
        uint256 totalPeso = 0;
        for (uint256 i = 1; i <= qtdCamisas; i++) {
            if (!camisas[i].existe) continue;
            if (camisas[i].raridade == Raridade.Comum) totalPeso += 70;
            else if (camisas[i].raridade == Raridade.Rara) totalPeso += 25;
            else totalPeso += 5;
        }

        uint256 aleatorio = seed % totalPeso;
        uint256 acumulado = 0;

        for (uint256 i = 1; i <= qtdCamisas; i++) {
            if (!camisas[i].existe) continue;
                uint256 peso = (camisas[i].raridade == Raridade.Comum) ? 70 :
                       (camisas[i].raridade == Raridade.Rara) ? 25 : 5;
                acumulado += peso;
            if (aleatorio < acumulado) {
                return i;
            }
        }

        return 1; // fallback
    }
    
    function selecionarCamisaPonderadaTeste(uint256 seed) public view returns (uint256) {
        return _selecionarCamisaPonderadaComSeed(seed);
    }
 
    // ========== Oráculo ==========
    modifier apenasOraculoOuDono() {
        require(msg.sender == oraculo || msg.sender == owner(), "Nao autorizado");
        _;
    }

    function definirOraculo(address novoOraculo) external onlyOwner {
        oraculo = novoOraculo;
        emit OraculoAtualizado(novoOraculo);
    }

    function oraculoAdicionarJogo(uint256 tokenId) external apenasOraculoOuDono {
        require(existeNFT(tokenId), "NFT inexistente");
        DadosDoador storage dd = _doadores[tokenId];
        dd.jogosAssistidos += 1;
        dd.ultimaDataJogo = block.timestamp;
        _atualizarNivel(dd);
        emit DadoExternoAtualizado(tokenId, "jogosAssistidos", dd.jogosAssistidos);
    }

    function oraculoAdicionarGastoProdutos(uint256 tokenId, uint256 valor) external apenasOraculoOuDono {
        require(existeNFT(tokenId), "NFT inexistente");
        _doadores[tokenId].gastoEmProdutos += valor;
        _atualizarNivel(_doadores[tokenId]);
        emit DadoExternoAtualizado(tokenId, "gastoEmProdutos", valor);
    }

    // ========== Atualização de nível ==========
    function _atualizarNivel(DadosDoador storage dd) internal {
        if (
            dd.totalDoado >= limiteOuro &&
            block.timestamp - dd.ultimaDoacao <= 30 days &&
            block.timestamp - dd.ultimaDataJogo <= 30 days &&
            dd.gastoEmProdutos >= 1000 * 10**18
        ) {
            dd.nivel = NivelDoador.Ouro;
        } else if (
            dd.totalDoado >= limitePrata &&
            block.timestamp - dd.ultimaDoacao <= 60 days &&
            dd.gastoEmProdutos >= 500 * 10**18
        ) {
            dd.nivel = NivelDoador.Prata;
        } else if (
            dd.totalDoado >= limiteBronze &&
            dd.gastoEmProdutos > 0
        ) {
            dd.nivel = NivelDoador.Bronze;
        } else {
            dd.nivel = NivelDoador.Nenhum;
        }
    }

    function resetNivelInativos() external onlyOwner {
        for (uint256 tokenId = 1; tokenId <= contadorIds; tokenId++) {
            if (!existeNFT(tokenId)) continue;
        
            DadosDoador storage dd = _doadores[tokenId];
            uint256 ultimaAtividade = dd.ultimaDoacao;
            if (dd.ultimaDataJogo > ultimaAtividade) ultimaAtividade = dd.ultimaDataJogo;

            if (block.timestamp - ultimaAtividade > 90 days) {
            dd.nivel = NivelDoador.Nenhum;
            emit DadoExternoAtualizado(tokenId, "nivelReset", 0);
        }
    }
}


    // ========== Consultas ==========
    function obterDadosDoador(uint256 tokenId) external view returns (DadosDoador memory) {
        require(existeNFT(tokenId), "NFT inexistente");
        return _doadores[tokenId];
    }

    // ========== NFT intransferível ==========
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);
        require(from == address(0), "NFT intransferivel");
        return super._update(to, tokenId, auth);
    }

    function approve(address, uint256) public pure override {
        revert("Approve desabilitado");
    }

    function setApprovalForAll(address, bool) public pure override {
        revert("setApprovalForAll desabilitado");
    }

    // ========== Administração ==========
    function definirLimites(uint256 bronze, uint256 prata, uint256 ouro) external onlyOwner {
        require(bronze <= prata && prata <= ouro, "Limites invalidos");
        limiteBronze = bronze;
        limitePrata = prata;
        limiteOuro = ouro;
    }

    function definirBaseURI(string calldata novaURI) external onlyOwner {
        _uriBase = novaURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uriBase;
    }

    function sacarBRZ(address destino, uint256 valor) external onlyOwner {
        require(destino != address(0), "Destino invalido");
        bool ok = tokenBRZ.transfer(destino, valor);
        require(ok, "Falha na transferencia BRZ");
    }

    // ========== Util ==========
    function existeNFT(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }
}

