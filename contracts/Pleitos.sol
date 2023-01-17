// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Condominio.sol";

contract Pleitos {
    Condominio public condominio;

    uint256 public pleitoId;

    modifier somenteSindico() {
        require(msg.sender == condominio.sindico(), "Somente sindico");
        _;
    }

    event NovoPleito(uint256 id, address sindico);
    event NovoVoto(uint256 pleitoId, uint256 unidade, bool voto);

    constructor(Condominio _condominio) {
        condominio = _condominio;
    }

    struct Pleito {
        uint256 id;
        string titulo;
        uint256 dataCriacao;
        uint256 dataLimite;
        uint256 votosSim;
        uint256 votosNao;
        mapping(uint256 => bool) votos;
    }

    mapping(uint256 => Pleito) public pleitos;

    function novoPleito(
        string memory _titulo,
        uint256 _dataLimite
    ) public somenteSindico {
        pleitos[pleitoId].id = pleitoId;
        pleitos[pleitoId].titulo = _titulo;
        pleitos[pleitoId].dataCriacao = block.timestamp;
        pleitos[pleitoId].dataLimite = _dataLimite;
        pleitos[pleitoId].votosSim = 0;
        pleitos[pleitoId].votosNao = 0;

        emit NovoPleito(pleitoId, msg.sender);

        pleitoId++;
    }

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
            "Votante da unidade invalido"
        );

        pleitos[_pleitoId].votos[_unidade] = true;

        if (_voto) {
            pleitos[_pleitoId].votosSim++;
        } else {
            pleitos[_pleitoId].votosNao++;
        }
    }

    function resultado(uint256 _pleitoId) public view returns (string memory) {
        require(
            pleitos[_pleitoId].dataLimite < block.timestamp,
            "Pleito ainda nao encerrado"
        );

        require(
            pleitos[_pleitoId].votosSim > 0 && pleitos[_pleitoId].votosNao > 0,
            "Pleito sem votos"
        );

        if (pleitos[_pleitoId].votosSim > pleitos[_pleitoId].votosNao)
            return "Aprovado";

        if (pleitos[_pleitoId].votosSim < pleitos[_pleitoId].votosNao)
            return "Reprovado";

        return "Empate";
    }
}
