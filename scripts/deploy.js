async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("deploy contrato con la account:", deployer.address);

  //SoulContract
  const SoulContract = await ethers.getContractFactory("SoulContract");
  const soulContract = await SoulContract.deploy();
  await soulContract.deployed();
  console.log("SoulContract address:", soulContract.address);

  //  ReputationManager
  const ReputationManager = await ethers.getContractFactory("ReputationManager");
  const reputationManager = await ReputationManager.deploy(
    soulContract.address
  );
  await reputationManager.deployed();
  console.log("ReputationManager address:", reputationManager.address);

  //  DepositManager
  const DepositManager = await ethers.getContractFactory("DepositManager");
  const depositManager = await DepositManager.deploy();
  await depositManager.deployed();
  console.log("DepositManager address:", depositManager.address);

  //  RecommendationManager
  const RecommendationManager = await ethers.getContractFactory("RecommendationManager");
  const recommendationManager = await RecommendationManager.deploy();
  await recommendationManager.deployed();
  console.log("RecommendationManager address:", recommendationManager.address);

  //  RentalSystem con los demas contracts
  const RentalSystem = await ethers.getContractFactory("RentalSystem");
  const rentalSystem = await RentalSystem.deploy(
    reputationManager.address,
    depositManager.address,
    recommendationManager.address,
    soulContract.address
  );
  await rentalSystem.deployed();
  console.log("RentalSystem address:", rentalSystem.address);

  // DigitalIdentity
  const DigitalIdentity = await ethers.getContractFactory("DigitalIdentity");
  const digitalIdentity = await DigitalIdentity.deploy();
  await digitalIdentity.deployed();
  console.log("DigitalIdentity address:", digitalIdentity.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });