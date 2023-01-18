const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { expect } = require("chai");

async function deploy(name, ...params) {
  const Contract = await ethers.getContractFactory(name);
  return await Contract.deploy(...params).then((f) => f.deployed());
}

describe("Condominio", function () {
  before(async function () {
    [
      sindicoDeployer,
      sindico,
      morador101,
      morador102,
      morador201,
      morador202,
      autorizado101,
      ...addrs
    ] = await ethers.getSigners();

    // Conta do síndico
    console.log("Conta do Síndico: ", sindico.address);

    // Deploy do contrato de Condominio
    condominio = await deploy("Condominio");
    console.log("Condominio instalado em", condominio.address, "\n");
  });

  describe("Deploy", function () {
    it("Deve ser síndico quem fez o deploy", async function () {
      expect(await condominio.sindico()).to.equal(sindicoDeployer.address);
    });
  });

  describe("Sindico", function () {
    it("Não deve poder alterar o síndico se não for o síndico", async function () {
      await expect(
        condominio.connect(addrs[0]).mudarSindico(addrs[1].address)
      ).to.be.revertedWith("Somente sindico");
    });

    it("Deve poder alterar o síndico se for o síndico", async function () {
      await expect(
        condominio.connect(sindicoDeployer).mudarSindico(sindico.address)
      ).to.emit(condominio, "NovoSindico");
    });
  });

  describe("Unidades", function () {
    it("Não deve poder incluir unidade se não for o síndico", async function () {
      await expect(
        condominio.connect(addrs[0]).adicionarUnidade(101, morador101.address)
      ).to.be.revertedWith("Somente sindico");
    });

    it("Não deve poder incluir unidade se endereço unidade for zero", async function () {
      await expect(
        condominio.connect(sindico).adicionarUnidade(0, morador101.address)
      ).to.be.revertedWith("Unidade invalida");
    });

    it("Não deve poder incluir unidade se conta do morador for 0x0", async function () {
      await expect(
        condominio
          .connect(sindico)
          .adicionarUnidade(101, ethers.constants.AddressZero)
      ).to.be.revertedWith("Morador invalido");
    });

    it("Deve poder incluir unidade se for o síndico", async function () {
      await expect(
        condominio.connect(sindico).adicionarUnidade(101, morador101.address)
      ).to.emit(condominio, "UnidadeAdicionada");

      expect((await condominio.unidades(101)).morador).to.equal(
        morador101.address
      );

      await expect(
        condominio.connect(sindico).adicionarUnidade(102, morador102.address)
      ).to.emit(condominio, "UnidadeAdicionada");

      expect((await condominio.unidades(102)).morador).to.equal(
        morador102.address
      );

      await expect(
        condominio.connect(sindico).adicionarUnidade(201, morador201.address)
      ).to.emit(condominio, "UnidadeAdicionada");

      expect((await condominio.unidades(201)).morador).to.equal(
        morador201.address
      );

      await expect(
        condominio.connect(sindico).adicionarUnidade(202, morador202.address)
      ).to.emit(condominio, "UnidadeAdicionada");

      expect((await condominio.unidades(202)).morador).to.equal(
        morador202.address
      );
    });

    it("Não deve poder incluir unidade se unidade já existe", async function () {
      await expect(
        condominio.connect(sindico).adicionarUnidade(101, morador101.address)
      ).to.be.revertedWith("Unidade existente");
    });

    it("Não deve excluir unidade se for não for o síndico", async function () {
      await expect(
        condominio.connect(addrs[0]).removerUnidade(101)
      ).to.be.revertedWith("Somente sindico");
    });

    it("Não deve excluir unidade se for morador", async function () {
      await expect(
        condominio.connect(morador101).removerUnidade(101)
      ).to.be.revertedWith("Somente sindico");
    });

    it("Deve excluir unidade se for o síndico", async function () {
      await condominio.connect(sindico).adicionarUnidade(999, addrs[0].address);

      await expect(condominio.connect(sindico).removerUnidade(999)).to.emit(
        condominio,
        "UnidadeRemovida"
      );

      expect((await condominio.unidades(999)).morador).to.equal(
        ethers.constants.AddressZero
      );
    });

    it("Não deve atualizar morador se não for o síndico", async function () {
      await expect(
        condominio.connect(addrs[0]).atualizarMorador(101, morador102.address)
      ).to.be.revertedWith("Somente sindico");
    });

    it("Deve atualizar morador se for o síndico", async function () {
      expect(
        await condominio
          .connect(sindico)
          .atualizarMorador(101, morador102.address)
      ).to.emit(condominio, "MoradorAtualizado");

      expect((await condominio.unidades(101)).morador).be.equal(
        morador102.address
      );

      // Revertendo
      await condominio
        .connect(sindico)
        .atualizarMorador(101, morador101.address);
    });
  });

  describe("Moradores", function () {
    it("Não deve autorizar endereço da unidade se não for morador", async function () {
      await expect(
        condominio.connect(addrs[0]).autorizarEndereco(101, addrs[0].address)
      ).to.be.revertedWith("Somente morador");
    });

    it("Não deve autorizar endereço da undiade se conta for 0x0", async function () {
      await expect(
        condominio
          .connect(morador101)
          .autorizarEndereco(101, ethers.constants.AddressZero)
      ).to.be.revertedWith("Endereco invalido");
    });

    it("Não deve autorizar endereço da unidade se for morador da unidade", async function () {
      await expect(
        condominio
          .connect(morador101)
          .autorizarEndereco(101, morador101.address)
      ).to.be.revertedWith("Morador nao pode se autorizar");
    });

    it("Deve autorizar endereço da unidade se for morador", async function () {
      await expect(
        condominio
          .connect(morador101)
          .autorizarEndereco(101, autorizado101.address)
      ).to.emit(condominio, "EnderecoAutorizado");

      expect((await condominio.unidades(101)).autorizado).to.equal(
        autorizado101.address
      );
    });

    it("Não deve autorizar endereço da unidade se já tiver sido autorizado", async function () {
      await expect(
        condominio
          .connect(morador101)
          .autorizarEndereco(101, autorizado101.address)
      ).to.be.revertedWith("Endereco ja autorizado");
    });

    it("Não deve desautorizar endereço da unidade se não for morador", async function () {
      await expect(
        condominio.connect(addrs[0]).desautorizarEndereco(101)
      ).to.be.revertedWith("Somente morador");
    });

    it("Deve desautorizar endereço da unidade se for morador", async function () {
      await expect(
        condominio.connect(morador101).desautorizarEndereco(101)
      ).to.emit(condominio, "EnderecoDesautorizado");

      expect((await condominio.unidades(101)).autorizado).to.equal(
        ethers.constants.AddressZero
      );
    });

    describe("Autorizados", function () {
      it("Não deve se desautorizar se não for autorizado", async function () {
        await expect(
          condominio.connect(morador101).desautorizarSe(101)
        ).to.be.revertedWith("Somente autorizado");
      });

      it("Autorizado deve poder se desautorizar", async function () {
        await condominio
          .connect(morador101)
          .autorizarEndereco(101, autorizado101.address);

        await expect(
          condominio.connect(autorizado101).desautorizarSe(101)
        ).to.emit(condominio, "EnderecoDesautorizouSe");

        expect((await condominio.unidades(101)).autorizado).to.equal(
          ethers.constants.AddressZero
        );
      });
    });
  });
});
