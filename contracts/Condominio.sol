// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Condominio {
    // @dev Endereço do síndico
    address public sindico;

    struct Unidade {
        address morador;
        address autorizado;
    }

    mapping(uint256 => Unidade) public unidades;

    // @dev Modificador para somente sindico
    modifier somenteSindico() {
        require(msg.sender == sindico, "Somente sindico");
        _;
    }

    // @dev Evento de mudança de síndico
    event NovoSindico(
        address indexed sindicoAntigo,
        address indexed sindicoNovo
    );

    // @dev Evento de adição de unidade
    event UnidadeAdicionada(
        uint256 indexed unidade,
        address indexed morador,
        address indexed sindico
    );

    event MoradorAtualizado(
        uint256 indexed unidade,
        address indexed moradorAntigo,
        address indexed moradorNovo,
        address sindico
    );

    // @dev Evento de remoção de unidade
    event UnidadeRemovida(uint256 indexed unidade, address indexed sindico);

    // @dev Evento de autorização de endereço
    event EnderecoAutorizado(
        uint256 indexed unidade,
        address indexed morador,
        address indexed autorizado
    );

    // @dev Evento de desautorização de endereço
    event EnderecoDesautorizado(
        uint256 indexed unidade,
        address indexed morador,
        address indexed autorizado
    );

    // @dev O deployer do contrato é o síndico
    constructor() {
        _mudarSindico(msg.sender);
    }

    // @dev Função para mudar o síndico
    // @param _novoSindico Endereço do novo síndico
    function mudarSindico(address _novoSindico) external somenteSindico {
        _mudarSindico(_novoSindico);
    }

    // @dev Função interna para mudar o síndico
    // @dev Essa função emite o evento
    // @param _novoSindico Endereço do novo síndico
    function _mudarSindico(address _novoSindico) internal {
        // @dev Atribui o novo síndico
        sindico = _novoSindico;

        // @dev Emite o evento de mudança de síndico
        emit NovoSindico(msg.sender, _novoSindico);
    }

    // @info Função para adicionar uma unidade
    // @dev Somente o síndico pode adicionar uma unidade
    // @param _unidade Número da unidade
    // @param _morador Endereço do morador
    function adicionarUnidade(
        uint256 _unidade,
        address _morador
    ) public somenteSindico {
        require(_unidade > 0, "Unidade invalida");
        require(_morador != address(0), "Morador invalido");
        require(unidades[_unidade].morador == address(0), "Unidade existente");

        // @dev Adiciona a unidade
        unidades[_unidade] = Unidade(_morador, address(0));

        // @dev Emite o evento de adição de unidade
        emit UnidadeAdicionada(_unidade, _morador, msg.sender);
    }

    // @info Função para atualizar o morador de uma unidade
    // @dev Somente o síndico pode atualizar o morador de uma unidade
    // @param _unidade Número da unidade
    // @param _moradorNovo Endereço do novo morador
    function atualizarMorador(
        uint256 _unidade,
        address _moradorNovo
    ) public somenteSindico {
        // @dev Recupera o morador antigo
        address moradorAntigo = unidades[_unidade].morador;

        // @dev Atualiza o morador
        unidades[_unidade].morador = _moradorNovo;

        // @dev Emite o evento de atualização de morador
        emit MoradorAtualizado(
            _unidade,
            moradorAntigo,
            _moradorNovo,
            msg.sender
        );
    }

    // @info Função para remover uma unidade
    // @dev Somente o síndico pode remover uma unidade
    // @param _unidade Número da unidade
    function removerUnidade(uint256 _unidade) public somenteSindico {
        require(unidades[_unidade].morador != address(0), "Unidade inexistente");

        // @dev Remove a unidade
        delete unidades[_unidade];

        // @dev Emite o evento de remoção de unidade
        emit UnidadeRemovida(_unidade, msg.sender);
    }

    // @info Função para autorizar um endereço
    // @dev Somente o morador pode autorizar um endereço
    // @param _unidade Número da unidade
    // @param _autorizado Endereço a ser autorizado
    function autorizarEndereco(uint256 _unidade, address _autorizado) public {
        // @dev Recupera a unidade
        Unidade storage unidade = unidades[_unidade];

        // @dev Verifica se o morador é o msg.sender
        require(unidade.morador == msg.sender, "Somente morador");

        require(_autorizado != address(0), "Endereco invalido");

        require(_autorizado == unidades[_unidade].morador, "Morador nao pode autorizar morador");

        require(_autorizado != unidades[_unidade].autorizado, "Endereco ja autorizado");

        // @dev Só autoriza se não estiver autorizado
        require(unidade.autorizado != _autorizado, "Endereco ja autorizado");

        // @dev Autoriza o endereço
        unidade.autorizado = _autorizado;

        // @dev Emite o evento de autorização de endereço
        emit EnderecoAutorizado(_unidade, msg.sender, _autorizado);
    }

    // @info Função para desautorizar um endereço
    // @dev Somente o morador pode desautorizar um endereço
    // @param _unidade Número da unidade
    // @param _autorizado Endereço a ser desautorizado
    function desautorizarEndereco(
        uint256 _unidade,
        address _autorizado
    ) public {
        // @dev Recupera a unidade
        Unidade storage unidade = unidades[_unidade];

        // @dev Verifica se o morador é o msg.sender
        require(unidade.morador == msg.sender, "Somente morador");

        // @dev Só desautoriza se estiver autorizado
        require(unidade.autorizado == _autorizado, "Endereco nao autorizado");

        // @dev Desautoriza o endereço
        unidade.autorizado = address(0);

        // @dev Emite o evento de desautorização de endereço
        emit EnderecoDesautorizado(_unidade, msg.sender, _autorizado);
    }

    // @info Função para desautorizar-se
    // @dev Somente o autorizado pode desautorizar-se
    // @param _unidade Número da unidade
    function desautorizarSe(uint256 _unidade) public {
        // @dev Recupera a unidade
        Unidade storage unidade = unidades[_unidade];

        // @dev Verifica se o autorizado é o msg.sender
        require(unidade.autorizado == msg.sender, "Somente autorizado");

        // @dev Desautoriza o endereço
        unidade.autorizado = address(0);

        // @dev Emite o evento de desautorização de endereço
        emit EnderecoDesautorizado(_unidade, unidade.morador, msg.sender);
    }

    // @info Função para retornar o votante (morador ou autorizado) de uma unidade
    // @param _unidade Número da unidade
    // @return Morador ou autorizado da unidade
    function retornaVotante(uint256 _unidade) public view returns (address) {
        // @dev Recupera a unidade
        Unidade storage unidade = unidades[_unidade];

        // @dev Retorna o morador ou autorizado
        return
            unidade.autorizado == address(0)
                ? unidade.morador
                : unidade.autorizado;
    }
}
