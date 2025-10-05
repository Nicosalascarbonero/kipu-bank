# KipuBank Smart Contract

## Descripción
KipuBank es un contrato inteligente en Solidity que permite a los usuarios depositar y retirar ETH en bóvedas personales, con un límite fijo por retiro y un tope global de depósitos.

## Estructura del Contrato
- **Archivo**: `contracts/KipuBank.sol`
- **Componentes**:
  - **Variables inmutables**: WITHDRAWAL_LIMIT, BANK_CAP
  - **Variables de almacenamiento**: totalDeposited, depositCount, withdrawalCount
  - **Mapping**: userBalances
  - **Eventos**: Deposited, Withdrawn
  - **Errores personalizados**: ZeroDeposit, BankCapExceeded, etc.
  - **Constructor**: Inicializa límites
  - **Modificador**: checkBankCap
  - **Función external payable**: deposit
  - **Función external**: withdraw
  - **Función external view**: getBalance
  - **Función private**: _validateState

## Instrucciones de Despliegue
1. Usa Remix (remix.ethereum.org)
2. En Remix:
   - Crea nuevo archivo con el código de KipuBank.sol.
   - En "Deploy & Run", ingresa parámetros del constructor 1 ETH para límite de retiro: 1000000000000000000, 100 ETH para bankCap.
   - Despliega en una testnet como Sepolia
3. Verifica en explorer como sepolia.etherscan.io.

## Cómo Interactuar
- **Depositar**: Llama `deposit()` con valor ETH.
- **Retirar**: Llama `withdraw(amount)` con amount en wei (<= WITHDRAWAL_LIMIT).
- **Ver saldo**: Llama `getBalance(address)`.


## Licencia
MIT License.
