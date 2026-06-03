// Módulo de Vendas - VENDAS.PRG
PROCEDURE ModuloVendas()
    LOCAL nOpc := 0
    CriarVendas()
    DO WHILE .T.
        CLS
        @ 2,10 SAY "SISTEMA ERP - MODULO DE VENDAS"
        @ 3,10 SAY Replicate("-", 40)
        @ 5,10 SAY "1 - Registrar Nova Venda"
        @ 6,10 SAY "2 - Listar Vendas Realizadas"
        @ 8,10 SAY "0 - Voltar"
        @ 10,10 SAY "Opcao: "
        INPUT TO nOpc
        DO CASE
            CASE nOpc == 1 ; RegistrarVenda()
            CASE nOpc == 2 ; ListarVendas()
            CASE nOpc == 0 ; EXIT
        ENDCASE
    ENDDO
RETURN

// --- Criação das tabelas de Vendas e Financeiro ---
PROCEDURE CriarVendas()
    IF ! File("vendas.dbf")
        DBCREATE("vendas.dbf", { ;
            { "ID_VENDA", "N", 6, 0 }, ;
            { "DATA", "D", 8, 0 }, ;
            { "ID_CLI", "N", 5, 0 }, ;
            { "VALOR_TOT", "N", 12, 2 } ;
            })
        USE vendas EXCLUSIVE NEW
        INDEX ON ID_VENDA TO vendas
        USE
    ENDIF

    IF ! File("receber.dbf")
        DBCREATE("receber.dbf", { ;
            { "ID_VENDA", "N", 6, 0 }, ;
            { "CLIENTE", "N", 5, 0 }, ;
            { "VENCIMEN", "D", 8, 0 }, ;
            { "VALOR", "N", 12, 2 }, ;
            { "STATUS", "C", 1, 0 } ;
            })
        USE receber EXCLUSIVE NEW
        INDEX ON ID_VENDA TO receber
        USE
    ENDIF
RETURN

PROCEDURE RegistrarVenda()
    LOCAL nCli := 0, nProd := 0, nQuant := 0, nTotal := 0, nVendaID := 0
    LOCAL dVenc := Date() + 30

    CLS
    @ 2,10 SAY "--- LANCAMENTO DE VENDA ---"

    IF Select("VENDAS") == 0
        USE vendas SHARED NEW ALIAS VENDAS
        SET INDEX TO vendas
    ENDIF

    IF Select("PRODUTOS") == 0
        USE produtos SHARED NEW ALIAS PRODUTOS
        SET INDEX TO produtos
    ENDIF

    IF Select("RECEBER") == 0
        USE receber SHARED NEW ALIAS RECEBER
        SET INDEX TO receber
    ENDIF

    @ 4,10 SAY "ID do Cliente: " GET nCli PICTURE "99999"
    READ
    IF LastKey() == 27
        RETURN
    ENDIF

    @ 6,10 SAY "ID do Produto: " GET nProd PICTURE "99999"
    READ

    SELECT PRODUTOS
    SEEK nProd

    IF ! FOUND()
        @ 8,10 SAY "ERRO: Produto nao encontrado!"
        INKEY(2)
        RETURN
    ENDIF

    @ 7,10 SAY "Produto: " + PadR(PRODUTOS->DESCRICAO, 30)
    @ 8,10 SAY "Preco Unitario: " + Transform(PRODUTOS->PRECO, "@E 999,999.99")

    @ 10,10 SAY "Quantidade: " GET nQuant PICTURE "999.99"
    READ

    IF nQuant <= 0
        RETURN
    ENDIF

    nTotal := nQuant * PRODUTOS->PRECO
    @ 12,10 SAY "TOTAL DA VENDA: R$ " + Transform(nTotal, "@E 999,999.99")
    @ 13,10 SAY "Confirma a venda (S/N)? "

    IF Upper(Chr(Inkey(0))) != "S"
        RETURN
    ENDIF

    SELECT VENDAS
    GO BOTTOM
    nVendaID := VENDAS->ID_VENDA + 1
    IF nVendaID <= 0
        nVendaID := 1
    ENDIF

    APPEND BLANK
    IF RLOCK()
        REPLACE ID_VENDA WITH nVendaID
        REPLACE DATA WITH Date()
        REPLACE ID_CLI WITH nCli
        REPLACE VALOR_TOT WITH nTotal
        DBUNLOCK()
    ENDIF

    SELECT RECEBER
    APPEND BLANK
    IF RLOCK()
        REPLACE ID_VENDA WITH nVendaID
        REPLACE CLIENTE WITH nCli
        REPLACE VENCIMEN WITH dVenc
        REPLACE VALOR WITH nTotal
        REPLACE STATUS WITH "A"
        DBUNLOCK()
    ENDIF

    @ 15,10 SAY "SUCESSO! Venda " + AllTrim(Str(nVendaID)) + " registrada."
    DBCOMMITALL()
    INKEY(2)
RETURN

PROCEDURE ListarVendas()
    LOCAL nLin := 5
    CLS
    @ 1,10 SAY "--- VENDAS REALIZADAS ---"
    @ 3,2 SAY "VENDA DATA CLI VALOR TOTAL"
    @ 4,2 SAY Replicate("-", 50)

    IF Select("VENDAS") == 0
        USE vendas SHARED NEW ALIAS VENDAS
        SET INDEX TO vendas
    ENDIF

    SELECT VENDAS
    GO TOP

    DO WHILE ! EOF()
        @ nLin, 2 SAY Str(ID_VENDA, 5)
        @ nLin, 10 SAY DATA
        @ nLin, 21 SAY Str(ID_CLI, 4)
        @ nLin, 30 SAY Transform(VALOR_TOT, "@E 999,999.99")
        nLin++

        IF nLin > 20
            @ 22,10 SAY "Pressione tecla..."
            INKEY(0)
            CLS
            nLin := 5
            @ 1,10 SAY "--- VENDAS REALIZADAS (CONT.) ---"
        ENDIF
        SKIP
    ENDDO

    @ 23,10 SAY "Fim da lista. Pressione tecla."
    INKEY(0)
RETURN
