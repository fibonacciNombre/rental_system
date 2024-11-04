const { ethers } = require("hardhat");

async function main() {

  const rentAmount = ethers.utils.parseEther("1.0"); // 1 ETH
  const rentalPeriod = 30 * 24 * 60 * 60; // 30 días en segundos

  // Direcciones de contratos y cuenta proporcionadas
  const reputationManagerAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
  const depositManagerAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
  const recommendationManagerAddress = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";
  const rentalSystemAddress = "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9";
  const tenantAddress = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"; // Dirección del inquilino

  // Obtener las instancias del contrato
  const RentalSystem = await ethers.getContractFactory("RentalSystem");
  const rentalSystem = await RentalSystem.attach(rentalSystemAddress);

  // Asegúrate de que la cuenta ha sido conectada
  const tenant = await ethers.getSigner(tenantAddress);

  // Suscribir al inquilino en el contrato RentalSystem
  await rentalSystem.connect(tenant).subscribe(rentAmount, rentalPeriod, { value: rentAmount });
  console.log("Inquilino suscrito con éxito");
  
  // Consultar el mapping tenants para la dirección proporcionada
  const tenantInfo = await rentalSystem.tenants(tenantAddress);

  // Mostrar la información obtenida
  console.log("Información del inquilino:");
  console.log(`Dirección del inquilino: ${tenantInfo.tenantAddress}`);
  console.log(`Monto del alquiler (wei): ${tenantInfo.rentAmount.toString()}`);
  console.log(`Fecha del próximo pago: ${new Date(tenantInfo.nextPaymentDueDate.toNumber() * 1000).toLocaleString()}`);
  console.log(`Puntos de reputación: ${tenantInfo.points.toString()}`);
  console.log(`Suscripción activa: ${tenantInfo.active}`);
  console.log(`Monto pendiente (wei): ${tenantInfo.pendingAmount.toString()}`);
}

// Ejecutar el script de interacción con el contrato
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
