// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title KipuBank
 * @dev Este contrato simula un banco donde los usuarios pueden depositar
 * y retirar Ether.
 * Aplica límites de retiro por transacción y un límite global de depósito.
 */
contract KipuBank {
    /*
     *VARIABLES INMUTABLES Y CONSTANTES*
     */

    /// @dev La cantidad máxima de Ether que se puede retirar en una sola transacción.
    /// Es una variable inmutable, fijada en el constructor.
    /// Se establece en 0.1 ETH.
    uint256 public immutable WITHDRAWAL_LIMIT;

    /// @dev El límite de depósito total que el contrato puede contener (Bank Cap).
    /// Es una variable inmutable, fijada en el constructor.
    uint256 public immutable bankCap;

    /*
* VARIABLES DE ALMACENAMIENTO*
     */

    /// @dev Dirección del propietario del contrato, que puede ser utilizada para funciones de administración (no requerida aquí, pero buena práctica).
    address private immutable i_owner;

    /// @dev El balance total de Ether depositado en el banco.
    uint256 public totalDeposited;

    /// @dev Contador de la cantidad total de depósitos exitosos.
    uint256 public depositCount;

    /// @dev Contador de la cantidad total de retiros exitosos.
    uint256 public withdrawalCount;

    /*
     * MAPPING*
     */

    /// @dev Mapeo de la dirección del usuario a su balance personal de Ether.
    mapping(address => uint256) private s_balances;

    /*
     *EVENTOS*
     */

    /// @dev Se emite cuando un depósito es exitoso.
    event DepositSuccessful(address indexed user, uint256 amount, uint256 newBalance);

    /// @dev Se emite cuando un retiro es exitoso.
    event WithdrawalSuccessful(address indexed user, uint256 amount, uint256 newBalance);

    /*
    ERRORES PERSONALIZADOS
     */

    /// @dev Se revierte si el depósito excede el límite global del banco.
    error CapExceeded(uint256 availableSpace, uint256 depositAttempt);

    /// @dev Se revierte si el usuario intenta retirar más de lo que tiene.
    error InsufficientBalance(uint256 requested, uint256 available);

    /// @dev Se revierte si el retiro excede el límite de retiro por transacción.
    error WithdrawalLimitExceeded(uint256 requested, uint256 limit);

    /// @dev Se revierte si la transferencia nativa de Ether falla.
    error TransferFailed();

    /// @dev Se revierte si la cantidad de depósito es cero.
    error ZeroDeposit();

    /*
 MODIFICADORES
     */

    /// @dev Verifica si el depósito propuesto no excede el límite total del banco (bankCap).
    modifier notAboveCap(uint256 _amount) {
        if (totalDeposited + _amount > bankCap) {
            revert CapExceeded({
                availableSpace: bankCap - totalDeposited,
                depositAttempt: _amount
            });
        }
        _;
    }

    /*
     * CONSTRUCTOR   
     */

    /**
     * @dev Inicializa el contrato con el límite global de depósito.
     * @param _bankCap El límite máximo de Ether que el contrato puede mantener.
     */
    constructor(uint256 _bankCap) {
        i_owner = msg.sender;
        bankCap = _bankCap;
        // Establecer el límite de retiro en 0.1 Ether
        WITHDRAWAL_LIMIT = 100_000_000_000_000_000; // 0.1 ETH en Wei
    }

    /*
 FUNCIONES EXTERNALES 
     */

    /**
     * @notice Permite a un usuario depositar Ether en su bóveda personal.
     * @dev Es una función `external` y `payable`.
     * Aplica el modificador `notAboveCap` y sigue el patrón Checks-Effects-Interactions.
     */
    function deposit() external payable notAboveCap(msg.value) {
        // --- Checks ---
        if (msg.value == 0) {
            revert ZeroDeposit();
        }

        // --- Effects ---
        // 1. Actualiza el balance del usuario
        s_balances[msg.sender] += msg.value;
        // 2. Actualiza el balance total del banco
        totalDeposited += msg.value;
        // 3. Incrementa el contador de depósitos
        depositCount++;

        // --- Interactions / Events ---
        emit DepositSuccessful(msg.sender, msg.value, s_balances[msg.sender]);
    }

    /**
     * @notice Permite a un usuario retirar Ether de su bóveda.
     * @dev Es una función `external`.
     * Aplica el límite de retiro por transacción y maneja la transferencia de forma segura.
     * @param _amount La cantidad de Ether a retirar.
     */
    function withdraw(uint256 _amount) external {
        // --- Checks ---
        // 1. Verificar que la cantidad no exceda el límite por transacción
        if (_amount > WITHDRAWAL_LIMIT) {
            revert WithdrawalLimitExceeded({
                requested: _amount,
                limit: WITHDRAWAL_LIMIT
            });
        }
        // 2. Verificar que el usuario tenga fondos suficientes
        if (_amount > s_balances[msg.sender]) {
            revert InsufficientBalance({
                requested: _amount,
                available: s_balances[msg.sender]
            });
        }

        // --- Effects ---
        // 1. Reduce el balance del usuario
        s_balances[msg.sender] -= _amount;
        // 2. Reduce el balance total del banco
        totalDeposited -= _amount;
        // 3. Incrementa el contador de retiros
        withdrawalCount++;

        // --- Interactions / Events ---
        // 4. Envía el Ether al usuario (Interacción)
        _safeTransferEther(msg.sender, _amount);
        // 5. Emite el evento
        emit WithdrawalSuccessful(msg.sender, _amount, s_balances[msg.sender]);
    }

    /**
     * @notice Devuelve el balance de Ether de un usuario.
     * @dev Es una función `external view` que retorna el saldo personal.
     * @param _user La dirección del usuario cuyo balance se desea consultar.
     * @return El balance de Ether del usuario en Wei.
     */
    function getBalance(address _user) external view returns (uint256) {
        return _getPrivateBalance(_user);
    }

    /*
     * 
     *FUNCIONES PRIVADAS 
     */

    /**
     * @dev Función privada para obtener el balance de un usuario.
     * Se utiliza internamente, por ejemplo, en `getBalance`.
     * @param _user La dirección del usuario.
     * @return El balance de Ether del usuario en Wei.
     */
    function _getPrivateBalance(address _user) private view returns (uint256) {
        return s_balances[_user];
    }

    /**
   * @param _to La dirección a la que se enviará el Ether.
     * @param _amount La cantidad de Ether a enviar en Wei.
     */
    function _safeTransferEther(address _to, uint256 _amount) private {
        (bool success, ) = payable(_to).call{value: _amount}("");
        if (!success) {
            // Si la transferencia falla, revertir y usar el error personalizado
            revert TransferFailed();
        }
    }
}
