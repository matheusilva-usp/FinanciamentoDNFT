# Contrato Inteligente com dNFTs para Financiamento Coletivo no Futebol: Transparência e Engajamento via Blockchain

Este documento serve como guia e referência para o repositório do projeto.

---

### Visão Geral do Projeto

Este trabalho propõe e valida um **contrato inteligente baseado em tokens não fungíveis dinâmicos (dNFTs)** para campanhas de financiamento coletivo no setor do futebol. Implementado na rede **Polygon** e na linguagem **Solidity**, o contrato utiliza oráculos para atualizar dinamicamente os tokens com base em eventos do mundo real, como resultados de jogos e a presença de torcedores. O modelo visa solucionar a falta de transparência e o baixo engajamento de plataformas tradicionais, oferecendo uma alternativa com maior auditoria e rastreabilidade.

---

### Principais Características

* **Viabilidade Econômica:** O custo médio por doação na rede Polygon foi de aproximadamente **R$ 0,018**, um valor drasticamente inferior às taxas cobradas por plataformas tradicionais.
* **Alta Eficiência:** O contrato é altamente performático, com tempo de compilação de **1,25 segundos** e uma suíte de 12 testes unitários e de integração executada em menos de **300 milissegundos**.
* **Transparência Total:** Todas as transações são registradas de forma pública e imutável na blockchain, garantindo total rastreabilidade.
* **Engajamento Dinâmico:** Os dNFTs evoluem com a participação do torcedor, servindo como um histórico vivo de suas contribuições e engajamento com o clube.

---

### Tecnologias Utilizadas

* **Solidity:** Linguagem de programação para contratos inteligentes.
* **Foundry:** Ambiente de desenvolvimento para compilação e testes.
* **Polygon:** Rede blockchain de segunda camada, escolhida por sua eficiência e baixas taxas.
* **OpenZeppelin:** Biblioteca de contratos inteligentes auditados e seguros.

---

### Como Configurar o Ambiente de Desenvolvimento

Para rodar o projeto, você precisará ter o **Foundry** instalado. O Foundry é um conjunto de ferramentas robusto e rápido para desenvolvimento de contratos inteligentes.

1.  **Instalação do Foundry**

    Abra seu terminal e execute o seguinte comando:
    ```
    curl -L https://foundry.paradigm.xyz | bash
    ```
    Siga as instruções para completar a instalação e certifique-se de que as ferramentas `forge` e `anvil` estão disponíveis no seu PATH.

2.  **Clonar o Repositório**

    Clone este repositório para sua máquina local.
    ```
    git clone https://github.com/matheusilva-usp/FinanciamentoDNFT.git
    ```
3.  **Instalação de Dependências**

    O projeto utiliza contratos padronizados da biblioteca **OpenZeppelin** para segurança e confiabilidade. Dentro do diretório do projeto, instale as dependências com o seguinte comando:
    ```
    forge install OpenZeppelin/openzeppelin-contracts@v5.3.0
    ```
---

### Como Rodar os Testes

Para garantir que o contrato está funcionando corretamente, você pode executar a suíte de testes unitários e de integração utilizando o `forge test`. O projeto também permite simular a rede Polygon localmente para uma validação mais realista.

1.  **Inicie uma rede local (Anvil) com uma cópia da rede Polygon**

    Abra um terminal e execute:
    ```
    anvil --fork-url https://polygon-rpc.com -p 8545
    ```
2.  **Execute os testes do contrato**

    Abra um novo terminal, navegue até a pasta do projeto e execute os testes, apontando para a rede local que você acabou de iniciar:
    ```
    forge test --fork-url http://127.0.0.1:8545 --gas-report
    ```
    O parâmetro `--gas-report` irá gerar um relatório detalhado do consumo de gas de cada função do contrato.

---

### Trabalhos Futuros

Conforme mencionado no estudo, este projeto serve como base para futuros desenvolvimentos, que podem incluir:

* Integração com oráculos descentralizados da Chainlink.
* Desenvolvimento de uma interface web para interação com usuários.
* Criação de modelos de governança descentralizada.
