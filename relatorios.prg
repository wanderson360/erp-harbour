/* ==========================================================================
 RELATORIOS.PRG - Módulo de Relatórios Financeiros e Gerenciais
 ========================================================================== */
PROCEDURE RelatorioReceber()
    LOCAL nTotalGeral := 0
    LOCAL nTotalAberto := 0
    LOCAL nTotalPago := 0
    LOCAL cStatusDesc := ""
    LOCAL nLinha := 5
    LOCAL nAreaAnterior := Select() // Guarda onde o sistema estava antes
    CLS
    @ 1,10 SAY "--- RELATORIO DE CONTAS A RECEBER ---"
    @ 2,0 SAY Replicate("-", 80)
    @ 3,0 SAY "VENDA CLIENTE VENCIMENTO VALOR (R$) STATUS"
    @ 4,0 SAY Replicate("-", 80)
    // 1. Verificação de Arquivo
    IF ! File("receber.dbf")
        @ 6,10 SAY "ERRO: O arquivo financeiro (receber.dbf) nao existe."
        INKEY(0)
        RETURN
    ENDIF
    // 2. Abertura Blindada
    // Se já estiver aberto, usamos a área existente. Se não, abrimos uma nova.
    IF Select("REL_REC") == 0
        USE receber SHARED NEW ALIAS REL_REC
        SET INDEX TO receber
    ENDIF

    SELECT REL_REC
    GO TOP
    IF EOF()
        @ 6,10 SAY "O arquivo financeiro esta vazio (sem vendas)."
    ELSE
        DO WHILE ! EOF()
            // 3. Identificação do Status (usando a lógica "A"berto / "P"ago)
            IF Upper(Left(REL_REC->STATUS, 1)) == "A"
                cStatusDesc := "EM ABERTO "
                nTotalAberto += REL_REC->VALOR
            ELSEIF Upper(Left(REL_REC->STATUS, 1)) == "P"
                cStatusDesc := "CONCLUIDO "
                nTotalPago += REL_REC->VALOR
            ELSE
                cStatusDesc := "DESCONHEC. "
            ENDIF
            nTotalGeral += REL_REC->VALOR
            // 4. Impressão das Linhas
            @ nLinha, 0 SAY Str(REL_REC->ID_VENDA, 5)
            @ nLinha, 7 SAY Str(REL_REC->CLIENTE, 7)
            @ nLinha, 16 SAY REL_REC->VENCIMEN
            @ nLinha, 30 SAY Transform(REL_REC->VALOR, "@E 999,999.99")
            @ nLinha, 45 SAY cStatusDesc
            nLinha++

            // Paginação: Evita que os dados saiam da tela
            IF nLinha > 18
                @ 20,10 SAY "Pressione qualquer tecla para ver mais..."
                INKEY(0)
                CLS
                @ 1,10 SAY "--- RELATORIO DE CONTAS A RECEBER (Cont.) ---"
                @ 3,0 SAY "VENDA CLIENTE VENCIMENTO VALOR (R$) STATUS"
                @ 4,0 SAY Replicate("-", 80)
                nLinha := 5
            ENDIF
            SKIP
        ENDDO
        // 5. Resumo Financeiro (Garantindo que apareça ao final)
        @ nLinha + 1, 0 SAY Replicate("-", 80)
        @ nLinha + 2, 10 SAY ">>> RESUMO FINANCEIRO <<<"
        @ nLinha + 3, 10 SAY "Total em Aberto: R$ " + Transform(nTotalAberto, "@E 999,999.99")
        @ nLinha + 4, 10 SAY "Total Pago : R$ " + Transform(nTotalPago, "@E 999,999.99")
        @ nLinha + 5, 10 SAY "TOTAL GERAL : R$ " + Transform(nTotalGeral, "@E 999,999.99")
        @ nLinha + 6, 0 SAY Replicate("-", 80)
    ENDIF
    @ 24,10 SAY "Pressione qualquer tecla para voltar ao menu..."
    INKEY(0)

    // 6. Limpeza de rastro: volta para a área onde o usuário estava antes
    SELECT (nAreaAnterior)
RETURN