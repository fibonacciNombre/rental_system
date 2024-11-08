const { ethers } = require("hardhat");

async function main() {

  // Direcciones de contratos y cuenta proporcionadas
  const reputationManagerAddress = "0x0aF2901216f9FeAfC79E439DA6ffD5e2AF37C77c";

  // Obtener las instancias del contrato
  const ReputationManager = await ethers.getContractFactory("ReputationManager");
  const reputationManager = await ReputationManager.attach(reputationManagerAddress);

  // Obtener el signer
  const [deployer, user] = await ethers.getSigners();

  // Obtener la reputación del usuario
  console.log(`Obteniendo la reputación para el usuario: ${user.address}`);
  const reputation = await reputationManager.getReputation(user.address);
  console.log("Reputación del usuario:", reputation.toString());

  // Obtener todos los tokens de reputación asociados con el usuario
  console.log(`Obteniendo tokens de reputación para el usuario: ${user.address}`);
  const reputationTokenIds = await reputationManager.getReputationTokens(user.address);

  console.log("Tokens de reputación del usuario:", reputationTokenIds.map(token => token.toString()));

}

// Ejecutar el script
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
