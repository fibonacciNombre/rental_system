const { ethers } = require("hardhat");

async function main() {

  // Direcciones de contratos y cuenta proporcionadas
  const reputationManagerAddress = "0xd75E4EA9Cf5F20611BfA7E03E41219e8BD5b8D54";

  // Obtener las instancias del contrato
  const reputationManager = await ethers.getContractFactory("ReputationManager")
    .then(factory => factory.attach(reputationManagerAddress));

  // Asegúrate de que la cuenta ha sido conectada
  const [deployer, user] = await ethers.getSigners();
  const ratings = [
    { amount: 1, comment: "Property left in good condition" },
    { amount: 1, comment: "Good performance" },
    { amount: -1, comment: "Bad communication" },
    { amount: 1, comment: "Smooth check-in process" },
    { amount: 1, comment: "Tenant was very accommodating" },
    { amount: 1, comment: "Check-out was timely and smooth" },
    { amount: 1, comment: "Respectful and friendly tenant" },
    { amount: -5, comment: "Property left in poor condition, stolen furniture" },
    { amount: 1, comment: "Consistently paid rent on time" },
    { amount: 1, comment: "Left the property in clean condition" },
    { amount: 1, comment: "Property left in good condition" },
    { amount: 1, comment: "Good performance" },
    { amount: -1, comment: "Complaints from neighbors" },
    { amount: 1, comment: "Tenant was very accommodating" },
    { amount: 1, comment: "Check-out was timely and smooth" },
    { amount: 1, comment: "Check-out was timely and smooth" },
  ];
  

  for (const rating of ratings) {
    const { amount, comment } = rating;

    if (amount > 0) {
      // Incrementar reputación si `amount` es positivo
      console.log(`Incrementando reputación para el usuario: ${user.address} con valor: ${amount}, comentario: "${comment}"`);
      const txIncrease = await reputationManager.connect(deployer).increaseReputation(
        user.address, // El destinatario de la reputación
        amount,
        user.address,
        comment
      );
      await txIncrease.wait();
      console.log("Reputación incrementada!");
    } else {
      // Disminuir reputación si `amount` es negativo
      console.log(`Disminuyendo reputación para el usuario: ${user.address} con valor: ${amount}, comentario: "${comment}"`);
      const txDecrease = await reputationManager.connect(deployer).decreaseReputation(   
        user.address, // El destinatario de la reputación
        Math.abs(amount),
        user.address,
        comment);
      await txDecrease.wait();
      console.log("Reputación disminuida!");
    }

    // Consultar la reputación actual después de cada cambio
    const currentReputation = await reputationManager.getReputation(user.address);
    console.log("Reputación actual del usuario:", currentReputation.toString());
  }
}

// Ejecutar el script de interacción con el contrato
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });