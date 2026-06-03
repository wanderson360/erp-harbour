/* ==========================================================================
   CADASTRO.PRG - Módulo de Gestão de Tabelas e Cadastros
   ========================================================================== */

// Avisa o compilador que estas variáveis existem globalmente (Public) no sistema
MEMVAR cNivelAcesso, cUsuarioLogado

PROCEDURE Cadastros()
    LOCAL nOpc := 0
    DO WHILE .T.
        CLS
        @ 2,10 SAY "--- MENU DE CADASTROS ---"
        @ 4,10 SAY "1 - Usuarios"
        @ 5,10 SAY "2 - Clientes"
        @ 6,10 SAY "3 - Produtos"
        @ 7,10 SAY "4 - Fornecedores"
        @ 8,10 SAY "0 - Voltar"
        @ 10,10 SAY "Opcao: " GET nOpc PICT "9" VALID nOpc >= 0 .AND. nOpc <= 4
        READ

        IF LastKey() == 27 .OR. nOpc == 0
            EXIT
        ENDIF

        DO CASE
            CASE nOpc == 1
                IF cNivelAcesso == "G"
                    CadastroUsuarios()
                ELSE
                    @ 12,10 SAY "ACESSO NEGADO! Apenas Gerentes."
                    INKEY(2)
                ENDIF
            CASE nOpc == 2 ; CadastroClientes()
            CASE nOpc == 3 ; CadastroProdutos()
            CASE nOpc == 4 ; CadastroFornecedores()
        ENDCASE
    ENDDO
RETURN

// --- SEÇÃO DE PRODUTOS ---

PROCEDURE CriarProdutos()
    LOCAL aEstrutura := {}
    IF ! File( "produtos.dbf" )
        aEstrutura := { { "ID", "N", 5, 0 }, ;
            { "DESCRICAO", "C", 50, 0 }, ;
            { "PRECO", "N", 10, 2 }, ;
            { "ESTOQUE", "N", 10, 2 }, ;
            { "FORN_id", "N", 5, 0 }, ;
            { "ATIVO", "L", 1, 0 } }
        DBCREATE( "produtos.dbf", aEstrutura )
        USE produtos EXCLUSIVE
        INDEX ON ID TO produtos
        USE
    ENDIF
RETURN

PROCEDURE CadastroProdutos()
    LOCAL nOpc := 0
    CriarProdutos()
    
    IF Select("PRODUTOS") == 0 
        USE produtos SHARED NEW ALIAS PRODUTOS 
        SET INDEX TO produtos 
    ENDIF
    
    SELECT PRODUTOS
    DO WHILE .T.
    CLS
    @ 2,10 SAY "CADASTRO DE PRODUTOS"
    @ 4,10 SAY "1 - Incluir 2 - Alterar"
    @ 5,10 SAY "3 - Excluir 4 - Listar"
    @ 6,10 SAY "0 - Voltar"
    @ 8,10 SAY "Opcao: " GET nOpc PICT "9" VALID nOpc >= 0 .AND. nOpc <= 4
    READ
        
    IF LastKey() == 27 .OR. nOpc == 0 ; EXIT ; ENDIF
    IF nOpc == 1 ; IncluirProduto() ; ENDIF
    IF nOpc == 2 ; AlterarProduto() ; ENDIF
    IF nOpc == 3 ; ExcluirProduto() ; ENDIF
    IF nOpc == 4 ; ListarProdutos() ; ENDIF
    ENDDO
RETURN

PROCEDURE IncluirProduto()
    LOCAL nIdFornecedor := 0, cDescricao := Space(50), nPreco := 0, nEstoque := 0, nNovoID := 0
    CLS
    @ 2,10 SAY "--- INCLUIR NOVO PRODUTO ---"
    @ 4,10 SAY "Descricao....: " GET cDescricao PICT "@!"
    @ 5,10 SAY "Preco........: " GET nPreco PICT "999999.99"
    @ 6,10 SAY "Estoque......: " GET nEstoque PICT "999999.99"
    @ 7,10 SAY "ID Fornecedor: " GET nIdFornecedor PICT "99999" VALID (nIdFornecedor > 0)
    READ

    IF LastKey() == 27 ; RETURN ; ENDIF
    
    CriarFornecedores()
    IF Select("FORN") == 0 
        USE fornecedores SHARED NEW ALIAS FORN 
        SET INDEX TO fornecedores 
    ENDIF

    SELECT FORN
    SEEK nIdFornecedor

    IF ! FOUND()
        @ 9,10 SAY "ERRO: Fornecedor nao cadastrado!"
        INKEY(2)
        RETURN
    ENDIF
    
    SELECT PRODUTOS 
    GO BOTTOM 
    nNovoID := ID + 1
    
    APPEND BLANK
    IF RLOCK()
        REPLACE ID WITH nNovoID, DESCRICAO WITH cDescricao, PRECO WITH nPreco, ;
            ESTOQUE WITH nEstoque, FORN_id WITH nIdFornecedor, ATIVO WITH .T.
        DBUNLOCK() 
        DBCOMMIT()
        @ 11,10 SAY "Produto cadastrado com sucesso!" ; INKEY(2)
    ENDIF
RETURN

PROCEDURE ListarProdutos()
    CLS 
    ? "LISTAGEM DE PRODUTOS" 
    ? "ID  DESCRICAO                      PRECO      ESTOQUE" 
    ? Replicate("-", 60)
    SELECT PRODUTOS ; GO TOP
    DO WHILE ! EOF()
        IF ATIVO
            ? Str(ID, 3), PadR(DESCRICAO, 30), Transf(PRECO, "@E 999,999.99"), Str(ESTOQUE, 10)
        ENDIF
        SKIP
    ENDDO
    ? ; ? "Fim da lista. Pressione tecla..." ; INKEY(0)
RETURN

PROCEDURE AlterarProduto()
    LOCAL nID := 0, cDesc := Space(50), nPrc := 0, nEst := 0
    CLS 
    @ 2,10 SAY "ALTERAR PRODUTO" 
    @ 4,10 SAY "ID do Produto: " GET nID PICT "99999" 
    READ
    
    SELECT PRODUTOS ; SEEK nID
    IF ! FOUND() ; @ 6,10 SAY "Nao encontrado!" ; INKEY(2) ; RETURN ; ENDIF

    cDesc := DESCRICAO ; nPrc := PRECO ; nEst := ESTOQUE
    @ 8,10 SAY "Nova Desc: " GET cDesc PICT "@!"
    @ 9,10 SAY "Novo Preco: " GET nPrc PICT "999999.99"
    @ 10,10 SAY "Novo Estoq: " GET nEst PICT "999999.99"
    READ

    IF LastKey() == 27 ; RETURN ; ENDIF
    IF RLOCK() 
        REPLACE DESCRICAO WITH cDesc, PRECO WITH nPrc, ESTOQUE WITH nEst
        DBUNLOCK() 
        DBCOMMIT() 
    ENDIF
RETURN

PROCEDURE ExcluirProduto()
    LOCAL nID := 0
    CLS 
    @ 2,10 SAY "EXCLUIR PRODUTO"
    @ 4,10 SAY "ID para excluir: " GET nID PICT "99999"
    READ
    
    SELECT PRODUTOS ; SEEK nID // <--- Corrigido de nIDincluirfor para nID
    IF FOUND() .AND. RLOCK() 
        DELETE 
        DBUNLOCK() 
        DBCOMMIT()
        @ 6,10 SAY "Excluido com sucesso!" 
    ELSE 
        @ 6,10 SAY "Erro ou nao encontrado!" 
    ENDIF
    INKEY(2)
RETURN

// --- SEÇÃO DE CLIENTES ---

PROCEDURE CriarClientes()
    LOCAL aEstrut := { { "ID", "N", 5, 0 }, { "NOME", "C", 40, 0 }, { "CPF", "C", 18, 0 }, { "FONE", "C", 15, 0 } }
    IF ! File("clientes.dbf") ; DBCREATE("clientes", aEstrut) ; ENDIF
    IF ! File("clientes.ntx") 
        USE clientes NEW 
        INDEX ON ID TO clientes 
        CLOSE clientes 
    ENDIF
RETURN

PROCEDURE CadastroClientes()
    LOCAL nOpc := 0
    CriarClientes()
    IF Select("CLI") == 0 
        USE clientes SHARED NEW ALIAS CLI 
        SET INDEX TO clientes 
    ENDIF
    DO WHILE .T.
    CLS 
    @ 2,10 SAY "--- GESTAO DE CLIENTES ---"
    @ 4,10 SAY "1-Incluir  2-Listar  3-Alterar  4-Excluir  0-Voltar"
    @ 6,10 SAY "Opcao: " GET nOpc PICT "9" VALID nOpc >= 0 .AND. nOpc <= 4
    READ
        
    IF LastKey() == 27 .OR. nOpc == 0 ; EXIT ; ENDIF
    SELECT CLI
    IF nOpc == 1 ; IncluirCliente() ; ENDIF
    IF nOpc == 2 ; ListarClientes() ; ENDIF
    IF nOpc == 3 ; AlterarCliente() ; ENDIF
    IF nOpc == 4 ; ExcluirCliente() ; ENDIF
    ENDDO
RETURN

PROCEDURE IncluirCliente()
    LOCAL cNom := Space(40), cDoc := Space(18), cFon := Space(15), nID := 0
    CLS ; @ 2,10 SAY "--- INCLUIR NOVO CLIENTE ---"
    @ 4,10 SAY "Nome/Razao...: " GET cNom PICT "@!"
    @ 5,10 SAY "CPF/CNPJ.....: " GET cDoc PICT "@!"
    @ 6,10 SAY "Telefone.....: " GET cFon PICT "@!"
    READ
    IF LastKey() == 27 ; RETURN ; ENDIF
    SELECT CLI ; GO BOTTOM ; nID := ID + 1
    APPEND BLANK
    IF RLOCK()
        REPLACE ID WITH nID, NOME WITH cNom, CPF WITH cDoc, FONE WITH cFon
        DBUNLOCK() ; DBCOMMIT() ; @ 8,10 SAY "Cliente cadastrado!" ; INKEY(2)
    ENDIF
RETURN

PROCEDURE ListarClientes()
    LOCAL nLin := 5
    IF Select("CLI") == 0 ; USE clientes SHARED NEW ALIAS CLI ; ENDIF
    SELECT CLI ; GO TOP
    IF EOF() ; CLS ; @ 10,10 SAY "Arquivo vazio!" ; INKEY(2) ; RETURN ; ENDIF
    CLS 
    @ 1,2 SAY "ID   NOME                                     DOC/CPF            FONE"
    @ 2,0 SAY Replicate("-", 80)
    DO WHILE ! EOF()
        @ nLin, 0 SAY Str(ID, 4) 
        @ nLin, 5 SAY PadR(NOME, 40) 
        @ nLin, 46 SAY PadR(CPF, 18) 
        @ nLin, 65 SAY FONE
        nLin++
        IF nLin > 20 
            @ 22,10 SAY "Pressione tecla..." ; INKEY(0) ; CLS ; nLin := 5 
        ENDIF
        SKIP
    ENDDO
    INKEY(0)
RETURN

PROCEDURE AlterarCliente()
    LOCAL nBusca := 0, cNom, cDoc, cFon
    CLS ; @ 2,10 SAY "--- ALTERAR DADOS DO CLIENTE ---"
    @ 4,10 SAY "ID do Cliente: " GET nBusca PICT "9999" ; READ
    SELECT CLI ; SEEK nBusca
    IF FOUND()
    cNom := NOME ; cDoc := CPF ; cFon := FONE
    @ 8,10 SAY "Nome: " GET cNom PICT "@!" 
    @ 9,10 SAY "Doc : " GET cDoc PICT "@!" 
    @ 10,10 SAY "Fone: " GET cFon PICT "@!" 
    READ
    IF LastKey() == 27 ; RETURN ; ENDIF
        IF RLOCK() 
            REPLACE NOME WITH cNom, CPF WITH cDoc, FONE WITH cFon
            DBUNLOCK() ; DBCOMMIT() 
        ENDIF
    ELSE 
        @ 6,10 SAY "Nao encontrado!" ; INKEY(2) 
    ENDIF
RETURN

PROCEDURE ExcluirCliente()
    LOCAL nBusca := 0, cConfirma := "N"
    CLS ; @ 2,10 SAY "--- EXCLUIR CLIENTE ---"
    @ 4,10 SAY "ID do Cliente: " GET nBusca PICT "9999" ; READ
    SELECT CLI ; SEEK nBusca
    IF FOUND()
        @ 8,10 SAY "CONFIRMA EXCLUSAO? (S/N): " GET cConfirma PICT "!" VALID cConfirma $ "SN" 
        READ
        IF cConfirma == "S" .AND. RLOCK() 
            DELETE ; DBUNLOCK() ; DBCOMMIT() 
        ENDIF
    ENDIF
RETURN

// --- SEÇÃO DE FORNECEDORES ---

PROCEDURE CriarFornecedores()
    IF ! File("fornecedores.dbf")
        DbCreate("fornecedores.dbf", { {"ID","N",5,0}, {"NOME","C",40,0}, {"CPF","C",18,0}, {"FONE","C",15,0} })
        USE fornecedores EXCLUSIVE 
        INDEX ON ID TO fornecedores 
        USE
    ENDIF
RETURN

PROCEDURE CadastroFornecedores()
    LOCAL nOpc := 0
    CriarFornecedores()
    IF Select("FORN") == 0 
        USE fornecedores SHARED NEW ALIAS FORN 
        SET INDEX TO fornecedores 
    ENDIF
    DO WHILE .T.
    CLS ; @ 2,10 SAY "--- GESTAO DE FORNECEDORES ---"
    @ 4,10 SAY "1-Incluir  2-Listar  4-Excluir  0-Voltar"
    @ 6,10 SAY "Opcao: " GET nOpc PICT "9" VALID nOpc >= 0 .AND. nOpc <= 4
    READ
        
    IF LastKey() == 27 .OR. nOpc == 0 ; EXIT ; ENDIF
    SELECT FORN
    IF nOpc == 1 ; IncluirFornecedor() ; ENDIF
    IF nOpc == 2 ; ListarFornecedores() ; ENDIF
    IF nOpc == 4 ; ExcluirFornecedor() ; ENDIF
    ENDDO
RETURN

PROCEDURE IncluirFornecedor()
    LOCAL cNom := Space(40), cDoc := Space(19), cFon := Space(15), nID := 0
    CLS ; @ 2,10 SAY "--- INCLUIR FORNECEDOR ---"
    @ 4,10 SAY "Nome: " GET cNom PICT "@!" 
    @ 5,10 SAY "Doc : " GET cDoc PICT "@!" 
    @ 6,10 SAY "Fone: " GET cFon PICT "@!" 
    READ
    IF LastKey() == 27 ; RETURN ; ENDIF
    SELECT FORN ; GO BOTTOM ; nID := ID + 1
    APPEND BLANK
    IF RLOCK() 
        REPLACE ID WITH nID, NOME WITH cNom, CPF WITH cDoc, FONE WITH cFon 
        DBUNLOCK() ; DBCOMMIT() 
    ENDIF
RETURN

PROCEDURE ListarFornecedores()
    LOCAL nLin := 5

    IF Select("FORN") == 0
        USE fornecedores SHARED NEW ALIAS FORN
        SET INDEX TO fornecedores
    ENDIF

    SELECT FORN
    GO TOP
    CLS
    @ 1,2 SAY "ID   FORNECEDOR                               DOC/CNPJ           FONE"
    @ 2,0 SAY Replicate("-", 80)

    IF EOF()
        @ 10,10 SAY "Arquivo de fornecedores esta vazio!"
        INKEY(2)
        RETURN
    ENDIF

    DO WHILE ! EOF()
        @ nLin, 0 SAY Str(ID, 4)
        @ nLin, 5 SAY PadR(NOME, 38)
        @ nLin, 45 SAY PadR(CPF, 18)
        @ nLin, 65 SAY PadR(FONE, 15)
        nLin++

        IF nLin > 20
            @ 22,10 SAY "Pressione tecla para ver mais..."
            INKEY(0)
            CLS
            @ 1,2 SAY "ID   FORNECEDOR (CONTINUACAO)                DOC/CNPJ           FONE"
            @ 2,0 SAY Replicate("-", 80)
            nLin := 5
        ENDIF
        SKIP
    ENDDO

    @ nLin+2, 10 SAY "Fim da lista. Pressione Enter."
    INKEY(0)
RETURN

PROCEDURE ExcluirFornecedor()
    LOCAL nBusca := 0, cConfirma := "N"
    CLS 
    @ 2,10 SAY "--- EXCLUIR FORNECEDOR ---"
    @ 4,10 SAY "ID Fornecedor: " GET nBusca PICT "99999"
    READ
    
    SELECT FORN ; SEEK nBusca
    IF FOUND()
        @ 8,10 SAY "EXCLUIR? (S/N): " GET cConfirma PICT "!" VALID cConfirma $ "SN"
        READ
        IF cConfirma == "S" .AND. RLOCK() 
            DELETE ; DBUNLOCK() ; DBCOMMIT()
        ENDIF
    ENDIF
RETURN

// --- SEÇÃO DE USUÁRIOS ---

PROCEDURE CriarUsuarios()
    IF ! File("usuarios.dbf")
        DbCreate("usuarios.dbf", { {"ID","N",4,0}, {"NOME","C",30,0}, {"LOGIN","C",15,0}, {"SENHA","C",15,0}, {"NIVEL","C",1,0} })
        USE usuarios EXCLUSIVE 
        APPEND BLANK
        REPLACE ID WITH 1, NOME WITH "ADMIN", LOGIN WITH "admin", SENHA WITH "123", NIVEL WITH "G"
        INDEX ON LOGIN TO usuarios 
        USE
    ENDIF
RETURN

PROCEDURE CadastroUsuarios()
    LOCAL nOpc := 0 
    CriarUsuarios()
    IF Select("USER") == 0 
        USE usuarios SHARED NEW ALIAS USER 
        SET INDEX TO usuarios 
    ENDIF
    DO WHILE .T.
    CLS 
    @ 2,10 SAY "USUARIOS" 
    @ 4,10 SAY "1-Incluir  2-Listar  0-Voltar" 
    @ 6,10 SAY "Opcao: " GET nOpc PICT "9" VALID nOpc >= 0 .AND. nOpc <= 2
    READ
        
    IF LastKey() == 27 .OR. nOpc == 0 ; EXIT ; ENDIF
    IF nOpc == 1 ; IncluirUsuario() ; ENDIF
    IF nOpc == 2 ; ListarUsuarios() ; ENDIF
    ENDDO
RETURN

PROCEDURE IncluirUsuario()
    LOCAL cNom := Space(30), cLog := Space(15), cSen := Space(15), cNiv := "O", nID := 0
    CLS ; @ 2,10 SAY "INCLUIR USUARIO"
    @ 4,10 SAY "Nome : " GET cNom PICT "@!" 
    @ 5,10 SAY "Login: " GET cLog PICT "@!" 
    @ 6,10 SAY "Senha: " GET cSen
    @ 7,10 SAY "Nivel: " GET cNiv PICT "!" VALID cNiv $ "GO" 
    READ
    IF LastKey() == 27 ; RETURN ; ENDIF
    SELECT USER ; GO BOTTOM ; nID := ID + 1
    APPEND BLANK
    IF RLOCK() 
        REPLACE ID WITH nID, NOME WITH cNom, LOGIN WITH cLog, SENHA WITH cSen, NIVEL WITH cNiv 
        DBUNLOCK() ; DBCOMMIT() 
    ENDIF
RETURN

PROCEDURE ListarUsuarios()
    LOCAL nLin := 5

    IF Select("USER") == 0
        USE usuarios SHARED NEW ALIAS USER
        SET INDEX TO usuarios
    ENDIF

    SELECT USER
    GO TOP
    CLS
    @ 1,10 SAY "--- LISTA DE USUARIOS CADASTRADOS ---"
    @ 3,2 SAY "ID   NOME                           LOGIN           NIVEL"
    @ 4,2 SAY Replicate("-", 70)

    IF EOF()
        @ 6,10 SAY "Nenhum usuario cadastrado."
    ELSE
        DO WHILE ! EOF()
            @ nLin, 2 SAY Str(ID, 4)
            @ nLin, 7 SAY PadR(NOME, 30)
            @ nLin, 38 SAY PadR(LOGIN, 15)
            @ nLin, 54 SAY IF(NIVEL == "G", "GERENTE", "OPERADOR")
            nLin++

            IF nLin > 20
                @ 22,10 SAY "Pressione qualquer tecla para continuar..."
                INKEY(0)
                CLS
                @ 1,10 SAY "--- LISTA DE USUARIOS (CONTINUACAO) ---"
                nLin := 5
            ENDIF
            SKIP
        ENDDO
    ENDIF

    @ nLin+2, 10 SAY "Fim da lista. Pressione qualquer tecla."
    INKEY(0)
RETURN

FUNCTION TelaLogin()
    LOCAL cL := Space(15), cS := Space(15), lOk := .F.
    PUBLIC cUsuarioLogado := "", cNivelAcesso := ""
    
    CriarUsuarios()
    IF Select("USER") == 0 
        USE usuarios SHARED NEW ALIAS USER 
        SET INDEX TO usuarios 
    ENDIF
    
    CLS 
    @ 5,30 SAY "LOGIN" 
    @ 7,30 SAY "User: " GET cL 
    @ 8,30 SAY "Pass: " GET cS 
    READ
    
    USER->(DbSeek(AllTrim(cL)))
    IF FOUND() .AND. AllTrim(USER->SENHA) == AllTrim(cS)
        cUsuarioLogado := USER->NOME 
        cNivelAcesso := USER->NIVEL 
        lOk := .T.
    ENDIF
    USER->(DbCloseArea())
RETURN lOk