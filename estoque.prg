#include "inkey.ch"
/* ==========================================================================
 ESTOQUE.PRG - Módulo de Movimentação e Saldos
 ========================================================================== */

PROCEDURE MenuEstoque()
    LOCAL nOpc := 0
    DO WHILE .T.
        CLS
        @ 1,2 SAY "USUARIO: " + AllTrim(cUsuarioLogado) + " (" + cNivelAcesso + ")"
        @ 2,10 SAY "--- CONTROLE DE ESTOQUE ---"
        @ 4,10 SAY "1 - Entrada de Mercadoria"
        @ 5,10 SAY "2 - Saida de Mercadoria"
        @ 6,10 SAY "3 - Listar Saldos Atuais"
        @ 8,10 SAY "0 - Voltar"
        @ 10,10 SAY "Opcao: "
        INPUT TO nOpc
        DO CASE
            CASE nOpc == 1 ; MovimentarEstoque("E")
            CASE nOpc == 2 ; MovimentarEstoque("S")
            CASE nOpc == 3 ; ListarSaldos()
            CASE nOpc == 0 ; EXIT
        ENDCASE
    ENDDO
RETURN

PROCEDURE CriarMoviment()
    IF ! File("moviment.dbf")
        DbCreate("moviment.dbf", { ;
            { "DATA", "D", 8, 0 }, ;
            { "PROD_ID", "N", 5, 0 }, ;
            { "TIPO", "C", 1, 0 }, ; // E = Entrada, S = Saída
            { "QUANT", "N", 10, 2 }, ;
            { "USER", "C", 15, 0 } ;
            } )
    ENDIF
RETURN

PROCEDURE MovimentarEstoque( cTipo )
    LOCAL nID := 0, nQtd := 0

    CriarMoviment()

    CLS
    @ 2,10 SAY IF(cTipo == "E", ">>> ENTRADA DE ESTOQUE <<<", ">>> SAIDA DE ESTOQUE <<<")

    @ 4,10 SAY "ID do Produto: " GET nID PICTURE "99999"
    READ

    IF nID == 0 .OR. LastKey() == 27
        RETURN
    ENDIF

    IF Select("PRODUTOS") == 0
        USE produtos SHARED NEW ALIAS PRODUTOS
        SET INDEX TO produtos
    ENDIF
    SELECT PRODUTOS

    IF ! PRODUTOS->(DbSeek(nID))
        @ 6,10 SAY "ERRO: Produto ID " + AllTrim(Str(nID)) + " nao encontrado!"
        INKEY(2)
        RETURN
    ENDIF

    @ 6,10 SAY "Produto: " + PRODUTOS->DESCRICAO
    @ 7,10 SAY "Estoque Atual: " + Transform(PRODUTOS->ESTOQUE, "@E 999,999.99")
    @ 8,0 SAY Replicate("-", 80)

    @ 10,10 SAY "Quantidade para " + IF(cTipo=="E","ACRESCENTAR","DIMINUIR") + ": " GET nQtd PICTURE "999,999.99"
    READ

    IF nQtd <= 0
        RETURN
    ENDIF

    IF cTipo == "S" .AND. (PRODUTOS->ESTOQUE - nQtd) < 0
        @ 12,10 SAY "ATENCAO: Estoque ficara NEGATIVO!"
        @ 13,10 SAY "Confirma assim mesmo (S/N)? "
        IF Upper(Chr(Inkey(0))) != "S"
            RETURN
        ENDIF
    ENDIF

    IF PRODUTOS->(RLOCK())
        IF cTipo == "E"
            REPLACE PRODUTOS->ESTOQUE WITH PRODUTOS->ESTOQUE + nQtd
        ELSE
            REPLACE PRODUTOS->ESTOQUE WITH PRODUTOS->ESTOQUE - nQtd
        ENDIF
        PRODUTOS->(DBUNLOCK())

        IF Select("MOV") == 0
            USE moviment SHARED NEW ALIAS MOV
        ENDIF
        MOV->(DbAppend())
        REPLACE MOV->DATA WITH Date(), ;
            MOV->PROD_ID WITH nID, ;
            MOV->TIPO WITH cTipo, ;
            MOV->QUANT WITH nQtd, ;
            MOV->USER WITH cUsuarioLogado

        @ 15,10 SAY "Estoque atualizado com sucesso!"
        DBCOMMITALL()
    ELSE
        @ 15,10 SAY "Erro: Registro travado por outro usuario."
    ENDIF

    INKEY(2)
RETURN

PROCEDURE ListarSaldos()
    LOCAL nLin := 5

    CLS
    @ 1,2 SAY "RELATORIO DE SALDOS EM ESTOQUE"
    @ 2,0 SAY Replicate("-", 80)
    @ 3,2 SAY "ID DESCRICAO ESTOQUE ATUAL"
    @ 4,0 SAY Replicate("-", 80)

    IF Select("PRODUTOS") == 0
        USE produtos SHARED NEW ALIAS PRODUTOS
        SET INDEX TO produtos
    ENDIF

    SELECT PRODUTOS
    GO TOP

    DO WHILE ! EOF()
        @ nLin, 2 SAY Str(ID, 4)
        @ nLin, 7 SAY PadR(DESCRICAO, 30)
        @ nLin, 40 SAY Transform(ESTOQUE, "@E 999,999.99")

        nLin++

        IF nLin > 20
            @ 22,2 SAY "Pressione qualquer tecla para continuar..."
            INKEY(0)
            CLS
            nLin := 5
            @ 1,2 SAY "RELATORIO DE SALDOS (CONT.)"
        ENDIF
        SKIP
    ENDDO

    @ nLin+1, 2 SAY "Fim da listagem. Pressione ENTER."
    INKEY(0)
RETURN
