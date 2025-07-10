
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Condominio {
    // @info Endereço do síndico
    address public sindico;

    struct Unidade {
        address proprietario;
        address autorizado;
    }

    // @info Mapeamento de unidades
    mapping(uint256 => Unidade) public unidades;

    // @info Mapeamento dos proprietários > unidades (um proprietário pode ter várias unidades)
    mapping(address => uint256[]) public proprietarios;

    // @info Modificador para somente síndico
    modifier somenteSindico() {
        require(msg.sender == sindico, "Somente sindico");
        _;
    }

    // @info Evento de mudança de síndico
    event NovoSindico(address indexed sindicoAntigo, address indexed sindicoNovo);

    // @info Evento de adição de unidade
    event UnidadeAdicionada(uint256 indexed unidade, address indexed proprietario, address indexed sindico);

    // @info Evento de atualização de proprietário da unidade
    event ProprietarioAtualizado(uint256 indexed unidade, address indexed proprietarioAntigo, address indexed proprietarioNovo, address sindico);

    // @info Evento de remoção de unidade
    event UnidadeRemovida(uint256 indexed unidade, address indexed sindico);

    // @info Evento de autorização de endereço
    event EnderecoAutorizado(uint256 indexed unidade, address indexed proprietario, address indexed autorizado);

    // @info Evento de desautorização de endereço
    event EnderecoDesautorizado(uint256 indexed unidade, address indexed proprietario, address indexed antigoAutorizado);

    // @info Evento de auto desautorização
    event EnderecoDesautorizouSe(uint256 indexed unidade, address indexed antigoAutorizado);

    // @info O deployer do contrato é o síndico
    constructor() {
        _mudarSindico(msg.sender);
    }

    // @info Função para mudar o síndico
    // @dev Acionada somente pelo síndico atual
    // @param _novoSindico Endereço do novo síndico
    function mudarSindico(address _novoSindico) external somenteSindico {
        _mudarSindico(_novoSindico);
    }

    // @info Função interna para mudar o síndico
    // @param _novoSindico Endereço do novo síndico
    function _mudarSindico(address _novoSindico) internal {
        sindico = _novoSindico;
        emit NovoSindico(msg.sender, _novoSindico);
    }

    // @info Função para adicionar uma unidade
    // @dev Somente o síndico pode adicionar uma unidade
    // @param _unidade Número da unidade
    // @param _proprietario Endereço do proprietário
    function adicionarUnidade(
        uint256 _unidade,
        address _proprietario
    ) public somenteSindico {
        require(_unidade > 0, "Unidade invalida");
        require(_proprietario != address(0), "Proprietario invalido");
        require(unidades[_unidade].proprietario == address(0), "Unidade existente");

        unidades[_unidade] = Unidade(_proprietario, address(0));
        proprietarios[_proprietario].push(_unidade);

        emit UnidadeAdicionada(_unidade, _proprietario, msg.sender);
    }

    // @info Função para atualizar o proprietário de uma unidade
    // @dev Somente o síndico pode atualizar o proprietário de uma unidade
    // @param _unidade Número da unidade
    // @param _proprietarioNovo Endereço do novo proprietário
    function atualizarProprietario(
        uint256 _unidade,
        address _proprietarioNovo
    ) public somenteSindico {
        address proprietarioAntigo = unidades[_unidade].proprietario;

        unidades[_unidade].proprietario = _proprietarioNovo;

        // @dev Remove a unidade da lista do antigo proprietário
        uint256[] storage antigasUnidades = proprietarios[proprietarioAntigo];
        for (uint i = 0; i < antigasUnidades.length; i++) {
            if (antigasUnidades[i] == _unidade) {
                antigasUnidades[i] = antigasUnidades[antigasUnidades.length - 1];
                antigasUnidades.pop();
                break;
            }
        }

        // @dev Adiciona a unidade ao novo proprietário
        proprietarios[_proprietarioNovo].push(_unidade);

        emit ProprietarioAtualizado(_unidade, proprietarioAntigo, _proprietarioNovo, msg.sender);
    }

    // @info Função para remover uma unidade
    // @dev Somente o síndico pode remover uma unidade
    // @param _unidade Número da unidade
    function removerUnidade(uint256 _unidade) public somenteSindico {
        require(unidades[_unidade].proprietario != address(0), "Unidade inexistente");

        address proprietario = unidades[_unidade].proprietario;

        // @dev Remove a unidade da lista do proprietário
        uint256[] storage lista = proprietarios[proprietario];
        for (uint i = 0; i < lista.length; i++) {
            if (lista[i] == _unidade) {
                lista[i] = lista[lista.length - 1];
                lista.pop();
                break;
            }
        }

        delete unidades[_unidade];

        emit UnidadeRemovida(_unidade, msg.sender);
    }

    // @info Função para autorizar um endereço
    // @dev Somente o proprietário pode autorizar um endereço
    // @param _unidade Número da unidade
    // @param _autorizado Endereço a ser autorizado
    function autorizarEndereco(uint256 _unidade, address _autorizado) public {
        Unidade storage unidade = unidades[_unidade];
        require(unidade.proprietario != address(0), "Unidade inexistente");
        require(unidade.proprietario == msg.sender, "Somente proprietario");
        require(_autorizado != address(0), "Endereco invalido");
        require(_autorizado != unidade.proprietario, "Proprietario nao pode se autorizar");
        require(_autorizado != unidade.autorizado, "Endereco ja autorizado");

        unidade.autorizado = _autorizado;
        emit EnderecoAutorizado(_unidade, msg.sender, _autorizado);
    }

    // @info Função para desautorizar um endereço
    // @dev Somente o proprietário pode desautorizar um endereço
    // @param _unidade Número da unidade
    function desautorizarEndereco(uint256 _unidade) public {
        Unidade storage unidade = unidades[_unidade];
        require(unidade.proprietario != address(0), "Unidade inexistente");
        require(unidade.proprietario == msg.sender, "Somente proprietario");

        address antigo = unidade.autorizado;
        unidade.autorizado = address(0);

        emit EnderecoDesautorizado(_unidade, msg.sender, antigo);
    }

    // @info Função para desautorizar-se
    // @dev Somente o autorizado pode desautorizar-se
    // @param _unidade Número da unidade
    function desautorizarSe(uint256 _unidade) public {
        Unidade storage unidade = unidades[_unidade];
        require(unidade.proprietario != address(0), "Unidade inexistente");
        require(unidade.autorizado == msg.sender, "Somente autorizado");

        unidade.autorizado = address(0);

        emit EnderecoDesautorizouSe(_unidade, msg.sender);
    }

    // @info Função para retornar o votante (proprietário ou autorizado) de uma unidade
    // @param _unidade Número da unidade
    // @return Proprietário ou autorizado da unidade
    function retornaVotante(uint256 _unidade) public view returns (address) {
        Unidade storage unidade = unidades[_unidade];
        return unidade.autorizado == address(0)
            ? unidade.proprietario
            : unidade.autorizado;
    }

    // @info Função que retorna todas as unidades de um proprietário (carteira)
    // @param carteira Endereço da carteira
    // @return Lista de unidades
    function unidadesDoProprietario(address carteira) public view returns (uint256[] memory) {
        return proprietarios[carteira];
    }
}