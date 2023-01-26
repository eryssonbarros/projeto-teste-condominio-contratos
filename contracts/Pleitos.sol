// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Condominio.sol";

contract Pleitos {
    // @info Endereço do contrato de condominio
    Condominio public condominio;

    // @info Id do pleito, incrementável
    uint256 public pleitoId;

    // @info Modificador para somente sindico
    modifier somenteSindico() {
        require(msg.sender == condominio.sindico(), "Somente sindico");
        _;
    }

    // @info Evento de criação de pleito
    event NovoPleito(uint256 id, address sindico);

    // @info Evento de voto
    event NovoVoto(uint256 pleitoId, uint256 unidade, bool voto);

    // @info Contrato de condomínio é indicando no deploy
    constructor(Condominio _condominio) {
        condominio = _condominio;
    }

    // @info Estrutura de pleito
    struct Pleito {
        uint256 id;
        string titulo;
        uint256 dataCriacao;
        uint256 dataLimite;
        uint256 votosSim;
        uint256 votosNao;
        mapping(uint256 => bool) votos;
    }

    // @info Mapeamento de pleitos
    mapping(uint256 => Pleito) public pleitos;

    // @info Criação de pleito
    function novoPleito(
        string memory _titulo,
        uint256 _dataLimite
    ) public somenteSindico {
        require(bytes(_titulo).length > 0, "Titulo invalido");
        require(_dataLimite > block.timestamp, "Data limite invalida");

        pleitos[pleitoId].id = pleitoId;
        pleitos[pleitoId].titulo = _titulo;
        pleitos[pleitoId].dataCriacao = block.timestamp;
        pleitos[pleitoId].dataLimite = _dataLimite;
        pleitos[pleitoId].votosSim = 0;
        pleitos[pleitoId].votosNao = 0;

        emit NovoPleito(pleitoId, msg.sender);

        pleitoId++;
    }

    // @info Votação
    function vota(uint256 _pleitoId, uint256 _unidade, bool _voto) external {
        require(
            pleitos[_pleitoId].dataLimite > block.timestamp,
            "Pleito encerrado"
        );

        require(
            pleitos[_pleitoId].votos[_unidade] == false,
            "Unidade ja votou"
        );

        require(
            msg.sender == condominio.retornaVotante(_unidade),
            "Votante invalido"
        );

        pleitos[_pleitoId].votos[_unidade] = true;

        if (_voto) {
            pleitos[_pleitoId].votosSim++;
        } else {
            pleitos[_pleitoId].votosNao++;
        }
    }

    function votou(uint256 _pleitoId, uint256 _unidade) external view returns (bool) {
        return pleitos[_pleitoId].votos[_unidade];
    }

    // @info Resultado do pleito
    function resultado(uint256 _pleitoId) public view returns (string memory) {
        require(
            pleitos[_pleitoId].votosSim > 0 && pleitos[_pleitoId].votosNao > 0,
            "Pleito sem votos"
        );
        
        require(
            pleitos[_pleitoId].dataLimite < block.timestamp,
            "Pleito ainda nao encerrado"
        );

        if (pleitos[_pleitoId].votosSim > pleitos[_pleitoId].votosNao)
            return "Aprovado";

        if (pleitos[_pleitoId].votosSim < pleitos[_pleitoId].votosNao)
            return "Reprovado";

        return "Empate";
    }
}
