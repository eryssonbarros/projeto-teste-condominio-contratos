const hre = require("hardhat");

async function main() {
  const Condominio = await hre.ethers.getContractFactory("Condominio");
  const condominio = await Condominio.deploy();
  await condominio.deployed();

  console.log("Condomínio implantado no endereço " + condominio.address);

  const Pleito = await hre.ethers.getContractFactory("Pleitos");
  const pleitos = await Pleito.deploy(condominio.address);
  await pleitos.deployed();

  console.log("Pleitos implantado no endereço " + pleitos.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
