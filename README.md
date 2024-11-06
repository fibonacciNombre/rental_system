# TFM
en el main TFM se encuentra la teoria de juegos sobre las recompensas del buen y mal comportamiento de un inquilino y el diagrama de flujo del desarrollo.


![image](https://github.com/GregoryAchong/TFM/assets/102753713/b8329050-47d2-4ad0-a674-adf3b1de92c0)

![alt text](image.png)

# draft rental system

Requisitos:

Instalar node.
Probar con:
```shell
npm --version

```

Crear el archivo .env , con el siguiente contenido:

```shell
SEPOLIA_PROJECT_ID=https://eth-sepolia.g.alchemy.com/v2/YOUR_ALCHEMY_API_KEY
MOONBASE_PROJECT_ID=https://rpc.api.moonbase.moonbeam.network
DEPLOYER_PRIVATE_KEY=0xac09iuegdiwged872378478cbijunhygtfrde7654322ff80

```


```shell
npm install

# Deploy local
npx hardhat compile
npx hardhat node
npx hardhat run scripts/deploy.js --network hardhat

# Execute Test Cases
npx hardhat test
REPORT_GAS=true npx hardhat test

# Deploy desde local
# Deploy sepolia
npx hardhat run scripts/deploy.js --network sepolia
# Deploy Moonbase
npx hardhat run scripts/deploy.js --network moonbase
```