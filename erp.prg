/* ==========================================================================
 ERP.PRG - Sistema ERP para Micro Empresas
 Linguagem: Harbour
 ========================================================================== */

// Variáveis globais
PUBLIC cUsuarioLogado := ""
PUBLIC cNivelAcesso := ""

PROCEDURE Main()
    LOCAL lSair := .F.

    // Configurações regionais e ambiente
    SET DATE BRITISH
    SET CENTURY ON
    SET DELETED ON
    SET SCOREBOARD OFF
    SET CONFIRM ON
    SET WRAP ON

    // Autenticação
    CLS
    IF ! TelaLogin()
        CLS
        @ 10,20 SAY "Saindo: Login cancelado ou falhou."
        INKEY(2)
        RETURN
    ENDIF

    // Loop principal
    DO WHILE ! lSair
        lSair := MenuPrincipal()
    ENDDO

    CLS
    @ 10,10 SAY "Sistema encerrado com sucesso."
    @ 11,10 SAY "Ate logo, " + AllTrim(cUsuarioLogado)
    INKEY(1)
RETURN

FUNCTION MenuPrincipal()
    LOCAL nOpcao := 0
    CLS
    @ 0,0 SAY Replicate("=", 80)
    @ 1,2 SAY "EMPRESA: MEU ERP Harbour"
    @ 1,50 SAY "DATA: " + DToC(Date())
    @ 2,2 SAY "USUARIO: " + AllTrim(cUsuarioLogado)
    @ 2,50 SAY "NIVEL: " + If(cNivelAcesso == "G", "GERENCIAL", "OPERADOR")
    @ 3,0 SAY Replicate("=", 80)

    @ 5,10 SAY "1 - Cadastros"
    @ 6,10 SAY "2 - Estoque"
    @ 7,10 SAY "3 - Vendas"
    @ 8,10 SAY "4 - Financeiro (Baixas)"
    @ 9,10 SAY "5 - Relatorios Financeiros"
    @ 10,10 SAY "6 - Backup do Sistema"
    @ 11,10 SAY "7 - Restaurar Backup"
    @ 12,10 SAY "0 - Sair"

    @ 14,10 SAY "Opcao: "
    INPUT TO nOpcao

    DO CASE
        CASE nOpcao == 1 ; Cadastros()
        CASE nOpcao == 2 ; MenuEstoque()
        CASE nOpcao == 3 ; ModuloVendas()
        CASE nOpcao == 4 ; BaixarTitulo()
        CASE nOpcao == 5 ; RelatorioFinanceiro()
        CASE nOpcao == 6 ; FazerBackup()
        CASE nOpcao == 7 ; RestaurarBackup()
        CASE nOpcao == 0 ; RETURN .T.
            OTHERWISE
            @ 16,10 SAY "Opcao invalida! Pressione tecla..."
            INKEY(0)
    ENDCASE
RETURN .F.

// --- Backup ---
PROCEDURE FazerBackup()
    LOCAL cDataHora := DTOS(Date()) + "_" + StrTran(Time(), ":", "")
    LOCAL cNomeArq := "backup_erp_" + cDataHora + ".zip"
    LOCAL cComando := ""
    LOCAL lWindows := "Windows" $ OS()

    CLS
    @ 2,10 SAY "--- SISTEMA DE BACKUP MULTIPLATAFORMA ---"
    @ 4,10 SAY "Sistema Operacional Detectado: " + OS()
    @ 6,10 SAY "Gerando: " + cNomeArq
    @ 8,10 SAY "Aguarde, processando arquivos..."

    IF lWindows
        cComando := "tar -a -c -f " + cNomeArq + " *.dbf *.ntx > nul"
    ELSE
        cComando := "sh -c 'zip -q -j " + cNomeArq + " *.dbf *.ntx'"
    ENDIF

    hb_processRun(cComando)

    @ 8,0 CLEAR TO 12,80
    IF File(cNomeArq)
        @ 10,10 SAY "SUCESSO: Backup realizado com exito!"
        @ 11,10 SAY "Arquivo: " + cNomeArq
    ELSE
        @ 10,10 SAY "ERRO: Falha ao gerar o arquivo de backup."
    ENDIF

    @ 14,10 SAY "Pressione qualquer tecla para voltar..."
    INKEY(0)
RETURN

// --- Restaurar Backup ---
PROCEDURE RestaurarBackup()
    LOCAL cArq := Space(40)
    LOCAL cComando := ""
    LOCAL lWindows := "Windows" $ OS()
    LOCAL cConfirma := "N"

    CLS
    @ 2,10 SAY "--- RESTAURACAO MULTIPLATAFORMA ---"
    @ 4,10 SAY "Arquivos disponiveis na pasta:"
    @ 5,0 SAY Replicate("-", 60)

    IF lWindows
        RUN dir *.zip /B
    ELSE
        RUN ls -1 *.zip
    ENDIF

    @ 13,0 SAY Replicate("-", 60)
    @ 14,10 SAY "Digite o nome exato: " GET cArq PICT "@!"
    READ

    cArq := AllTrim(cArq)
    IF Empty(cArq) ; RETURN ; ENDIF
    IF !(".ZIP" $ Upper(cArq)) ; cArq += ".zip" ; ENDIF

    IF ! File(cArq) .AND. ! File(Lower(cArq))
        @ 16,10 SAY "ERRO: Arquivo nao encontrado!"
        INKEY(2)
        RETURN
    ENDIF
    IF ! File(cArq) .AND. File(Lower(cArq))
        cArq := Lower(cArq)
    ENDIF

    @ 18,10 SAY "Confirma restauracao? (S/N): " GET cConfirma PICT "X" VALID cConfirma $ "SN"
    READ

    IF cConfirma == "S"
        CLOSE ALL
        @ 20,10 SAY "Restaurando... aguarde."

        IF lWindows
            cComando := "tar -x -f " + cArq + " > nul"
        ELSE
            cComando := "sh -c 'unzip -q -o " + cArq + "'"
        ENDIF

        hb_processRun(cComando)

        CLS
        @ 10,10 SAY "RESTAURACAO CONCLUIDA COM SUCESSO!"
        @ 12,10 SAY "O sistema sera encerrado para atualizar os dados."
        INKEY(4)
        QUIT
    ENDIF
RETURN
