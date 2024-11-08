// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts4/access/AccessControl.sol";

contract SoulContract is AccessControl {

    struct Soul {
        string identity;        // Identidad única del usuario
        uint256 createdAt;      // Fecha de creación del Soul
    }

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    mapping(address => Soul) private souls;
    mapping(address => uint256[]) private soulToReputationTokenIds; // ID de tokens de reputación asociados a cada Soul
    mapping(string => address) private identityToSoulAddress;       // Para buscar por identidad (identity)

    // Eventos para la trazabilidad
    event SoulCreated(address indexed soulAddress, string identity, uint256 createdAt);
    event TokenReputationBySoulAdded(uint256 indexed tokenId, address indexed soulAddress);

    constructor() {
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    // Crear un nuevo Soul asegurando que la identidad (identity) sea única
    //function createSoul(address _soulAddress, string memory _identity) external onlyRole(ADMIN_ROLE) {
    function createSoul(address _soulAddress, string memory _identity) external {
        require(identityToSoulAddress[_identity] == address(0), "Identity already in use");
        if (bytes(souls[_soulAddress].identity).length != 0) {
            // Si ya existe un Soul, actualizar la identidad
            souls[_soulAddress].identity = string(abi.encodePacked(souls[_soulAddress].identity, " | ", _identity));
        } else {
            // Crear un nuevo Soul
            Soul storage newSoul = souls[_soulAddress];
            newSoul.identity = _identity;
            newSoul.createdAt = block.timestamp;

            // Asignar la identidad al address del Soul
            identityToSoulAddress[_identity] = _soulAddress;

            emit SoulCreated(_soulAddress, _identity, block.timestamp);
        }
    }

    // Añadir reputación a un Soul basado en la dirección (soulAddress)
    //function addTokenReputationBySoul(address _soulAddress, uint256 _tokenId) external onlyRole(ADMIN_ROLE) {
    function addTokenReputationBySoul(address _soulAddress, uint256 _tokenId) external {
        require(bytes(souls[_soulAddress].identity).length != 0, "Soul does not exist");

        // Asociar el token de reputación al Soul
        soulToReputationTokenIds[_soulAddress].push(_tokenId);

        emit TokenReputationBySoulAdded(_tokenId, _soulAddress);
    }

    // Obtener la información completa de un Soul por su dirección
    function getSoul(address _soulAddress) external view returns (Soul memory) {
        require(bytes(souls[_soulAddress].identity).length != 0, "Soul does not exist");
        return souls[_soulAddress];
    }

    // Obtener la dirección de un Soul utilizando la identidad (identity)
    function getSoulByIdentity(string memory _identity) external view returns (Soul memory) {
        address soulAddress = identityToSoulAddress[_identity];
        require(bytes(souls[soulAddress].identity).length != 0, "Soul does not exist");
        return souls[soulAddress];
    }

    // Obtener todos los tokens de reputación (con detalles) de un Soul
    function getTokensBySoul(address _soulAddress) external view returns (uint256[] memory) {
        require(bytes(souls[_soulAddress].identity).length != 0, "Soul does not exist");

        uint256[] memory tokenIds = soulToReputationTokenIds[_soulAddress];

        return tokenIds;
    }

}