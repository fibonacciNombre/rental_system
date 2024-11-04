// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./SoulContract.sol";

contract ReputationManager is ERC721URIStorage, AccessControl{
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    mapping(address => int256) public reputationsOld;

    event ReputationUpdated(address user, int256 change);
    event RewardGranted(address indexed user, int256 points);
    event PenaltyImposed(address indexed user, int256 points);

    struct Reputation {
        int256 value;
        string comment;
        uint256 timestamp;
        address soul;
    }

    // Lista de valores permitidos para los tokens de reputación
    int256[] public allowedValues = [-5, 1];

    SoulContract public soulContract;

    mapping(uint256 => Reputation) public reputationTokens;         // Almacenar todos los tokens de reputación

    // Contador para asignar IDs a los tokens
    uint256 public reputationCounter = 0; 

    event ReputationTokenNotMinted(address indexed soul, uint indexed reputationCount);
    event ReputationTokenMinted(uint256 indexed tokenId, address indexed soul, int256 value, uint256 timestamp, string comment);

    constructor(address _soulContractAddress) ERC721("ReputationToken", "RPT") {
        soulContract = SoulContract(_soulContractAddress);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function increaseReputation(address user, int256 amount, address _soul, string memory _comment) external {
        reputationsOld[user] += amount;
        mintReputationToken(_soul, amount, _comment);
        emit ReputationUpdated(user, reputationsOld[user]);
        emit RewardGranted(user, int256(amount));
    }

    function decreaseReputation(address user, int256 amount) external {
        require(reputationsOld[user] >= amount, "Reputation can't be negative");
        reputationsOld[user] -= amount;
        emit ReputationUpdated(user, reputationsOld[user]);
        emit PenaltyImposed(user, -int256(amount));
    }

    function getReputation(address user) external view returns (int256) {
        return reputationsOld[user];
    }


    function addAllowedValue(int256 _value) external onlyRole(ADMIN_ROLE) {
        allowedValues.push(_value);
    }

    function isAllowedValue(int256 _value) public view returns (bool) {
        for (uint256 i = 0; i < allowedValues.length; i++) {
            if (allowedValues[i] == _value) {
                return true;
            }
        }
        return false;
    }

    // Función para emitir un token de reputación (Soulbound)
    //function mintReputationToken(address _soul, int256 _value, string memory _comment) internal onlyRole(ADMIN_ROLE) {
    function mintReputationToken(address _soul, int256 _value, string memory _comment) internal {
        require(isAllowedValue(_value), "Reputation value is not allowed");

        uint256 tokenId = reputationCounter++;
        reputationTokens[tokenId] = Reputation({
            value: _value,
            comment: _comment,
            timestamp: block.timestamp,
            soul: _soul
        });

        _safeMint(_soul, tokenId);
        _setTokenURI(tokenId, _comment); 
        
        soulContract.addTokenReputationBySoul(_soul, tokenId);
        emit ReputationTokenMinted(tokenId, _soul, _value, block.timestamp, _comment);
    }

    function getReputationTokens(address _soulAddress) external view returns (Reputation[] memory) {
        //require(bytes(souls[_soulAddress].identity).length != 0, "Soul does not exist");

        uint256[] memory tokenIds = soulContract.getTokensBySoul(_soulAddress);//soulToReputationTokenIds[_soulAddress];
        Reputation[] memory reputationDetails = new Reputation[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            reputationDetails[i] = reputationTokens[tokenIds[i]];
        }

        return reputationDetails;
    }

    function getReputationToken(uint256 tokenId) external view returns (Reputation memory) {
        require(tokenId < reputationCounter, "Reputation token does not exist");
        return reputationTokens[tokenId];
    }

    function testMintReputationToken (address _soul, int256 _value, string memory _comment) external {
         mintReputationToken(_soul,_value,_comment);
    }


    // Deshabilitar transferencia de tokens para hacerlos SoulBound
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal {
        require(from == address(0), "Soulbound Token: non-transferable");
    }

    // Sobrescribir supportsInterface para resolver el conflicto entre AccessControl y ERC721
    function supportsInterface(bytes4 interfaceId) public view override(ERC721URIStorage, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Obtener los valores permitidos
    function getAllowedValues() external view returns (int256[] memory) {
        return allowedValues;
    }

}
