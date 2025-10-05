// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @title KipuBank - Un contrato bancario seguro para gestionar depósitos y retiros de ETH
/// @notice Permite a los usuarios depositar y retirar ETH con un límite de retiro por transacción y un tope global de depósitos
contract KipuBank {
    // === Variables de Estado ===

    /// @notice Cantidad máxima de ETH que se puede retirar por transacción (inmutable)
    uint256 public immutable WITHDRAWAL_LIMIT;

    /// @notice Cantidad máxima total de ETH que el contrato puede contener (inmutable)
    uint256 public immutable BANK_CAP;

    /// @notice Mapeo de direcciones de usuarios a sus saldos en la bóveda personal
    mapping(address => uint256) private userBalances;

    /// @notice Cantidad total de ETH actualmente depositada en el contrato
    uint256 public totalDeposited;

    /// @notice Contador del número total de depósitos realizados
    uint256 public depositCount;

    /// @notice Contador del número total de retiros realizados
    uint256 public withdrawalCount;

    // === Errores ===

    /// @notice Lanzado cuando el monto del depósito es cero
    error ZeroDeposit();

    /// @notice Lanzado cuando el depósito excedería la capacidad del banco
    error BankCapExceeded();

    /// @notice Lanzado cuando el monto del retiro es cero
    error ZeroWithdrawal();

    /// @notice Lanzado cuando el monto del retiro excede el límite
    error WithdrawalLimitExceeded();

    /// @notice Lanzado cuando el usuario no tiene saldo suficiente
    error InsufficientBalance();

    // === Eventos ===

    /// @notice Emitido cuando un usuario deposita ETH exitosamente
    /// @param user La dirección del usuario que depositó
    /// @param amount La cantidad de ETH depositada
    event Deposited(address indexed user, uint256 amount);

    /// @notice Emitido cuando un usuario retira ETH exitosamente
    /// @param user La dirección del usuario que retiró
    /// @param amount La cantidad de ETH retirada
    event Withdrawn(address indexed user, uint256 amount);

    // === Modificadores ===

    /// @notice Asegura que el depósito no exceda la capacidad del banco
    modifier checkBankCap(uint256 amount) {
        if (totalDeposited + amount > BANK_CAP) {
            revert BankCapExceeded();
        }
        _;
    }

    // === Constructor ===

    /// @notice Inicializa el contrato con un límite de retiro y capacidad del banco
    /// @param _withdrawalLimit La cantidad máxima de ETH por retiro
    /// @param _bankCap La cantidad máxima total de ETH que el contrato puede contener
    constructor(uint256 _withdrawalLimit, uint256 _bankCap) {
        WITHDRAWAL_LIMIT = _withdrawalLimit;
        BANK_CAP = _bankCap;
    }

    // === Funciones Externas ===

    /// @notice Permite a un usuario depositar ETH en su bóveda personal
    /// @dev Actualiza el saldo del usuario y el total depositado, emite el evento Deposited
    function deposit() external payable checkBankCap(msg.value) {
        if (msg.value == 0) {
            revert ZeroDeposit();
        }

        // Patrón checks-effects-interactions
        userBalances[msg.sender] += msg.value;
        totalDeposited += msg.value;
        depositCount++;

        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Permite a un usuario retirar ETH de su bóveda personal
    /// @param amount La cantidad de ETH a retirar
    /// @dev Asegura que el retiro esté dentro de los límites y que el usuario tenga saldo suficiente, emite el evento Withdrawn
    function withdraw(uint256 amount) external {
        if (amount == 0) {
            revert ZeroWithdrawal();
        }
        if (amount > WITHDRAWAL_LIMIT) {
            revert WithdrawalLimitExceeded();
        }
        if (userBalances[msg.sender] < amount) {
            revert InsufficientBalance();
        }

        // Patrón checks-effects-interactions
        userBalances[msg.sender] -= amount;
        totalDeposited -= amount;
        withdrawalCount++;

        emit Withdrawn(msg.sender, amount);

        // Transferencia segura de ETH
        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) {
            revert("Transfer failed");
        }
    }

    // === Funciones de Vista ===

    /// @notice Retorna el saldo de la bóveda personal de un usuario
    /// @param user La dirección del usuario a consultar
    /// @return El saldo actual del usuario en wei
    function getBalance(address user) external view returns (uint256) {
        return userBalances[user];
    }

    // === Funciones Privadas ===

    /// @notice Función interna para validar el estado del contrato (ejemplo para requisito de función privada)
    /// @dev Actualmente es un placeholder para demostrar una función privada
    function _validateState() private view {
        // Placeholder para lógica de validación interna
    }
}

