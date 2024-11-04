const { expect } = require("chai");
const { ethers } = require("hardhat");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs"); // Importa anyValue


describe("RentalSystem", function () {
  let rentalSystem, reputationManager, depositManager, recommendationManager, soulContract;
  let landlord, tenant;

  before(async () => {
    // Obtener los signers (cuentas) del entorno de pruebas
    [landlord, tenant] = await ethers.getSigners();
    //console.log("1 landlord: ", landlord);
    //console.log("1 tenant: ", tenant);

    // Desplegar SoulContract
    const SoulContract = await ethers.getContractFactory("SoulContract");
    soulContract = await SoulContract.deploy();
    await soulContract.deployed();

    // Desplegar ReputationManager
    const ReputationManager = await ethers.getContractFactory("ReputationManager");
    reputationManager = await ReputationManager.deploy(
        soulContract.address
    );
    await reputationManager.deployed();

    // Desplegar DepositManager
    const DepositManager = await ethers.getContractFactory("DepositManager");
    depositManager = await DepositManager.deploy();
    await depositManager.deployed();

    // Desplegar RecommendationManager
    const RecommendationManager = await ethers.getContractFactory("RecommendationManager");
    recommendationManager = await RecommendationManager.deploy();
    await recommendationManager.deployed();

    // Desplegar RentalSystem usando los contratos de Reputation, Deposit y Recommendation
    const RentalSystem = await ethers.getContractFactory("RentalSystem");
    rentalSystem = await RentalSystem.deploy(
      reputationManager.address,
      depositManager.address,
      recommendationManager.address,
      soulContract.address
    );
    await rentalSystem.deployed();
  });

  it("Debería permitir a un arrendador suscribirse", async function () {
    await expect(rentalSystem.connect(landlord).subscribeLandlord())
      .to.emit(rentalSystem, "LandlordSubscribed")
      .withArgs(landlord.address);

    const landlordInfo = await rentalSystem.landlords(landlord.address);
    expect(landlordInfo.landlordAddress).to.equal(landlord.address);
    expect(landlordInfo.active).to.be.true;
  });

  it("Debería permitir a un inquilino suscribirse", async function () {
    // First, landlord subscribes
    //await rentalSystem.connect(landlord).subscribeLandlord();

    const rentAmount = ethers.utils.parseEther("1.0"); // 1 ETH
    const rentalPeriod = 30 * 24 * 60 * 60; // 30 days in seconds

    await expect(rentalSystem.connect(tenant).subscribe(rentAmount, rentalPeriod, landlord.address, { value: rentAmount }))
      .to.emit(rentalSystem, "Subscribed")
      .withArgs(tenant.address, rentAmount, anyValue);

    const tenantInfo = await rentalSystem.tenants(tenant.address);
    expect(tenantInfo.tenantAddress).to.equal(tenant.address);
    expect(tenantInfo.landlordAddress).to.equal(landlord.address);
    expect(tenantInfo.rentAmount).to.equal(rentAmount);
    expect(tenantInfo.active).to.be.true;
  });

  it("Debería permitir a un inquilino suscribirse como arrendador", async function () {
    await expect(rentalSystem.connect(tenant).subscribeLandlord())
      .to.emit(rentalSystem, "LandlordSubscribed")
      .withArgs(tenant.address);

    const landlordInfo = await rentalSystem.landlords(tenant.address);
    expect(landlordInfo.landlordAddress).to.equal(tenant.address);
    expect(landlordInfo.active).to.be.true;
  });

  it("Debería permitir a un arrendador suscribirse como inquilino", async function () {
    // First, landlord subscribes
    //await rentalSystem.connect(landlord).subscribeLandlord();

    const rentAmount = ethers.utils.parseEther("1.0"); // 1 ETH
    const rentalPeriod = 30 * 24 * 60 * 60; // 30 days in seconds

    await expect(rentalSystem.connect(landlord).subscribe(rentAmount, rentalPeriod, tenant.address, { value: rentAmount }))
      .to.emit(rentalSystem, "Subscribed")
      .withArgs(landlord.address, rentAmount, anyValue);

    const tenantInfo = await rentalSystem.tenants(landlord.address);
    expect(tenantInfo.tenantAddress).to.equal(landlord.address);
    expect(tenantInfo.landlordAddress).to.equal(tenant.address);
    expect(tenantInfo.rentAmount).to.equal(rentAmount);
    expect(tenantInfo.active).to.be.true;
  });

  it("Debería devolver todos los inquilinos de un arrendador", async function () {
    // First, landlord subscribes
    //await rentalSystem.connect(landlord).subscribeLandlord();
  
    const rentAmount = ethers.utils.parseEther("1.0"); // 1 ETH
    //const rentalPeriod = 30 * 24 * 60 * 60; // 30 days in seconds
  
    // Tenant subscribes
    //await rentalSystem.connect(tenant).subscribe(rentAmount, rentalPeriod, landlord.address, { value: rentAmount });
  
    // Fetch tenants of landlord
    //const tenants = await rentalSystem.getTenantsByLandlord(landlord.address);
    const tenants = await rentalSystem.getTenantsByLandlord(landlord.address);
    console.log(tenants)
    // Verify tenant details
    expect(tenants.length).to.equal(1);
    expect(tenants[0].tenantAddress).to.equal(tenant.address);
    expect(tenants[0].landlordAddress).to.equal(landlord.address);
    expect(tenants[0].rentAmount).to.equal(rentAmount);
    expect(tenants[0].active).to.be.true;
  });


  it("Debería permitir al inquilino pagar la renta", async function () {
    const rentAmount = ethers.utils.parseEther("1.0"); // 1 ETH

    // Adelantar el tiempo hasta que el pago del alquiler esté vencido
    await ethers.provider.send("evm_increaseTime", [30 * 24 * 60 * 60]); // Adelanta 30 días
    await ethers.provider.send("evm_mine", []); // Minar el siguiente bloque

    console.log("4 tenant: ", tenant);

    // Pagar la renta
    await expect(rentalSystem.connect(tenant).payRent({ value: rentAmount }))
      .to.emit(rentalSystem, "RentPaid")
      .withArgs(tenant.address, rentAmount, await ethers.provider.getBlock("latest").then(block => block.timestamp + 30 * 24 * 60 * 60));

    // Verificar la reputación del inquilino
    const reputation = await reputationManager.getReputation(tenant.address);
    expect(reputation).to.equal(1); // Debería haber ganado 1 punto de reputación por pagar a tiempo
  });

  it("Debería penalizar al inquilino por pagar tarde", async function () {
    const rentAmount = ethers.utils.parseEther("1.0"); // 1 ETH

    // Adelantar el tiempo 2 días después de la fecha de vencimiento
    await ethers.provider.send("evm_increaseTime", [32 * 24 * 60 * 60]); // Adelanta 32 días
    await ethers.provider.send("evm_mine", []); // Minar el siguiente bloque

    console.log("5 tenant: ", tenant);

    // Pagar la renta tarde
    await expect(rentalSystem.connect(tenant).payRent({ value: rentAmount }))
      .to.emit(rentalSystem, "RentPaid");

    // Comparar los timestamps con una tolerancia
    const actualNextPaymentDueDate = (await rentalSystem.tenants(tenant.address)).nextPaymentDueDate;
    const expectedNextPaymentDueDate = (await ethers.provider.getBlock("latest")).timestamp + 30 * 24 * 60 * 60;
    expect(actualNextPaymentDueDate).to.be.closeTo(expectedNextPaymentDueDate, 100); // tolerancia de 2 segundos

    // Verificar la reputación del inquilino después de pagar tarde
    const reputation = await reputationManager.getReputation(tenant.address);
    console.log(reputation)
    expect(reputation).to.equal(0); // La reputación debería haber bajado a 0
  });

  it("Debería permitir al arrendador finalizar la relación con el inquilino", async function () {
    // El arrendador termina la relación con el inquilino
    console.log("2 landlord: ", landlord);
    await expect(rentalSystem.connect(landlord).endRelationship(tenant.address))
      .to.emit(rentalSystem, "RelationshipEnded")
      .withArgs(tenant.address);

    const tenantInfo = await rentalSystem.tenants(tenant.address);
    expect(tenantInfo.active).to.be.false;
  });

  it("Deberia mint un reputationToken", async function () {
    await soulContract.connect(landlord).createSoul(tenant.address, "Test Identity");
    await reputationManager.connect(landlord).testMintReputationToken(tenant.address, 1, "Payment transfer");

    const reputation = await reputationManager.getReputationToken(1);
    console.log("reputation : ", reputation);
    expect(reputation.value).to.equal(1);
    expect(reputation.comment).to.equal("Payment transfer");
    expect(reputation.soul).to.equal(tenant.address);
  });

  it("Deberia consultar todos los reputationTokens for a soul", async function () {
    await soulContract.connect(landlord).createSoul(tenant.address, "Test Identity");
    await reputationManager.connect(landlord).testMintReputationToken(tenant.address, 1, "Payment transfer");
    await reputationManager.connect(landlord).testMintReputationToken(tenant.address, -5, "Bad Behavior");

    const reputationTokens = await reputationManager.getReputationTokens(tenant.address);
    console.log("reputationTokens : ", reputationTokens);
    //expect(reputationTokens.length).to.equal(2);
    expect(reputationTokens[0].value).to.equal(1);
    //expect(reputationTokens[1].value).to.equal(-5);
  });

  it("Deberia consultar tokens por Soul", async function () {
    const tokens = await soulContract.getTokensBySoul(tenant.address);
    console.log("tokens by soul: ", tokens)
    expect(tokens.map(t => t.toNumber())).to.deep.equal([0,1, 2, 3,4]);
  })

});
