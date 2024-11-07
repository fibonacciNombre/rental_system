// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract DigitalIdentity is OwnableUpgradeable {
    struct DIDDocument {
        address owner;
        string publicKey;
        string authenticationMethod;
        bool revoked;
        string identifier;
        // Other fields...
    }

    mapping(address => DIDDocument) public didDocuments;

    event DIDDocumentCreated(
        address indexed did,
        address indexed owner,
        string identifier
    );
    event DIDDocumentUpdated(
        address indexed did,
        string newPublicKey,
        string newAuthenticationMethod
    );

    function initialize() public initializer {
        // Initialize libs
        __Ownable_init(0x8625bAab5E0EbEd83A383E29C173D5569619Cb41);
    }

    function createDIDDocument(
        string memory publicKey,
        string memory authenticationMethod
    ) external {
        require(bytes(publicKey).length > 0, "Public key is required");
        require(
            bytes(authenticationMethod).length > 0,
            "Authentication method is required"
        );
        require(
            didDocuments[msg.sender].owner == address(0),
            "DID document already exists"
        );

        didDocuments[msg.sender] = DIDDocument({
            owner: msg.sender,
            identifier: generateDID(publicKey),
            publicKey: publicKey,
            authenticationMethod: authenticationMethod,
            revoked: false
            // Populate other fields...
        });

        emit DIDDocumentCreated(
            msg.sender,
            msg.sender,
            didDocuments[msg.sender].identifier
        );
    }

    function updateDIDDocument(
        string memory newPublicKey,
        string memory newAuthenticationMethod
    ) external onlyOwner {
        require(bytes(newPublicKey).length > 0, "New public key is required");
        require(
            bytes(newAuthenticationMethod).length > 0,
            "New authentication method is required"
        );
        require(
            didDocuments[msg.sender].revoked == false,
            "DID document already revoked"
        );

        DIDDocument storage doc = didDocuments[msg.sender];
        doc.publicKey = newPublicKey;
        doc.authenticationMethod = newAuthenticationMethod;
        // Update other fields...

        // Emit an event or perform additional actions as needed
        emit DIDDocumentUpdated(
            msg.sender,
            newPublicKey,
            newAuthenticationMethod
        );
    }

    function revokeDIDDocument() external onlyOwner {
        require(
            didDocuments[msg.sender].revoked == false,
            "DID document already revoked"
        );

        DIDDocument storage doc = didDocuments[msg.sender];
        doc.revoked = true;
        doc.publicKey = "0x";
    }

    // Verificacion + ZKP
    function getDIDDocument()
        external
        view
        onlyOwner
        returns (DIDDocument memory)
    {
        require(
            didDocuments[msg.sender].revoked == false,
            "DID document already revoked"
        );
        return didDocuments[msg.sender];
    }

    function compareHashes(string memory _a, string memory _b) public pure returns (bool) {
        return keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    function getDIDDocumentbyPK(
        string memory namePublicKey,
        address userAddress
    ) external view onlyOwner returns (DIDDocument memory did) {
        require(bytes(namePublicKey).length > 0, "public key name is required");
        require(didDocuments[userAddress].owner != address(0), "DID document does not exist");
        require(didDocuments[userAddress].revoked == false, "DID document already revoked");

        DIDDocument storage doc = didDocuments[userAddress];
        bool isMatch = compareHashes(doc.publicKey, namePublicKey);

        if (isMatch) {
            did = doc;
        } else {
            revert("Public key does not match");
        }

        return did;
    }


    function verifyDIDDocumentbyID(
        string memory identifier
    ) external view onlyOwner returns (DIDDocument memory did) {
        require(bytes(identifier).length > 0, "identifier key is required");
        require(
            didDocuments[msg.sender].revoked == false,
            "DID document already revoked"
        );

        DIDDocument storage doc = didDocuments[msg.sender];
        if (compareHashes(doc.identifier, identifier))
            did = didDocuments[msg.sender];

        return did;
    }

    function generateDID(string memory publicKey) internal pure returns (string memory) {
        bytes32 pubKeyHash = keccak256(abi.encodePacked(publicKey));
        return string(abi.encodePacked("did:ethr:", toHexString(pubKeyHash)));
    }

    function toHexString(bytes32 data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            str[2 * i] = alphabet[uint8(data[i] >> 4)];
            str[2 * i + 1] = alphabet[uint8(data[i] & 0x0f)];
        }
        return string(str);
    }
    // Other functions for resolving DIDs and additional features...
}