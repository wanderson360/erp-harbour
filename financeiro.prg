/* ==========================================================================
 FINANCEIRO.PRG - Módulo de Contas a Receber e Baixas
 ========================================================================== */

PROCEDURE GerarFinanceiro(nIdV, nIdC, nValor, dData)
    IF Select("RECEBER") == 0
        USE receber SHARED NEW ALIAS RECEBER
        SET INDEX TO receber
    ENDIF

    SELECT RECEBER
    APPEND BLANK

    IF RLOCK()
        REPLACE ID_VENDA WITH nIdV, ;
            CLIENTE WITH nIdC, ;
            VENCIMEN WITH dData + 30, ;
            VALOR WITH nValor, ;
            STATUS WITH "A"
        DBUNLOCK()
        DBCOMMIT()
    ENDIF
RETURN

PROCEDURE BaixarTitulo()
    LOCAL nVendaBusca := 0
    LOCAL cConfirma := "N"

    CLS
    @ 2,10 SAY "--- BAIXA DE TITULOS (CONTAS A RECEBER) ---"
    @ 4,10 SAY "Digite o Numero da Venda para baixar: " GET nVendaBusca PICTURE "999999"
    READ

    IF nVendaBusca == 0
        RETURN
    ENDIF

    IF Select("RECEBER") == 0
        USE receber SHARED NEW ALIAS RECEBER
        SET INDEX TO receber
    ENDIF

    SELECT RECEBER
    SET ORDER TO 1
    SEEK nVendaBusca

    IF FOUND()
        IF STATUS == "P"
            @ 10,10 SAY "Este titulo JA ESTA PAGO!"
            Inkey(2)
        ELSE
            @ 7,10 SAY Replicate("-", 50)
            @ 8,10 SAY "Venda: " + AllTrim(Str(ID_VENDA))
            @ 8,30 SAY "Cliente: " + AllTrim(Str(CLIENTE))
            @ 9,10 SAY "Valor: R$ " + Transform(VALOR, "@E 999,999.99")
            @ 9,40 SAY "Venc: " + DToC(VENCIMEN)
            @ 10,10 SAY Replicate("-", 50)

            @ 12,10 SAY "Confirma o PAGAMENTO deste titulo? (S/N): " GET cConfirma PICTURE "X" VALID cConfirma $ "SN"
            READ

            IF cConfirma == "S"
                IF RLOCK()
                    REPLACE STATUS WITH "P"
                    DBUNLOCK()
                    DBCOMMIT()
                    @ 14,10 SAY ">>> BAIXA REALIZADA COM SUCESSO! <<<"
                ELSE
                    @ 14,10 SAY "ERRO: Registro em uso por outro usuario!"
                ENDIF
                Inkey(2)
            ENDIF
        ENDIF
    ELSE
        @ 10,10 SAY "Venda nao encontrada no Financeiro!"
        Inkey(2)
    ENDIF
RETURN

PROCEDURE RelatorioFinanceiro()
    LOCAL nTotal := 0
    LOCAL nLin := 5

    CLS
    @ 1,10 SAY "--- TITULOS EM ABERTO ---"
    @ 3,2 SAY "VENDA CLIENTE VENCIMENTO VALOR"
    @ 4,2 SAY Replicate("-", 50)

    IF Select("RECEBER") == 0
        USE receber SHARED NEW ALIAS RECEBER
        SET INDEX TO receber
    ENDIF

    SELECT RECEBER
    GO TOP

    DO WHILE ! EOF()
        IF STATUS == "A"
            @ nLin, 2 SAY Str(ID_VENDA, 5)
            @ nLin, 10 SAY Str(CLIENTE, 5)
            @ nLin, 21 SAY DToC(VENCIMEN)
            @ nLin, 35 SAY Transform(VALOR, "@E 999,999.99")
            nTotal += VALOR
            nLin++
        ENDIF
        SKIP
    ENDDO

    @ nLin+1, 2 SAY Replicate("-", 50)
    @ nLin+2, 2 SAY "TOTAL A RECEBER: R$ " + Transform(nTotal, "@E 9,999,999.99")
    INKEY(0)
RETURN
