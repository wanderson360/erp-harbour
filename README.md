# ERP em Harbour

Sistema ERP simples para microempresas, desenvolvido em **Harbour** (sucessor moderno do Clipper).  
Interface em terminal, multiplataforma (Linux/Windows), com suporte a DBF/NTX/CDX.
## 📖 Motivação

Harbour é uma linguagem antiga de paradigma procedural, descendente direta do Clipper, que foi muito utilizada em sistemas ERP e aplicações comerciais nas décadas de 80 e 90.
Resolvi me aventurar nesse projeto para revisitar o passado dos sistemas de gestão, compreender como funcionavam os ERPs antigos e explorar a evolução das práticas de programação.
Esse mergulho histórico ajuda a valorizar o legado da computação e entender como soluções simples em terminal sustentaram negócios por muitos anos.

## ✨ Funcionalidades
- **Cadastros**: Usuários, Clientes, Produtos e Fornecedores  
- **Estoque**: Controle de produtos e movimentações  
- **Vendas**: Registro de vendas e integração automática com financeiro  
- **Financeiro**: Contas a receber e baixas de títulos  
- **Relatórios**: Listagens e consultas financeiras  
- **Backup/Restore**: Sistema de backup multiplataforma (Linux/Windows)

## 🔑 Login Padrão
- **Usuário:** `admin`  
- **Senha:** `123`  
- Nível de acesso inicial: **Gerencial**
```
## 📂 Estrutura do Projeto

ERP/
├── erp.prg          # Menu principal e fluxo do sistema
├── cadastro.prg     # Gestão de cadastros
├── estoque.prg      # Controle de estoque
├── vendas.prg       # Módulo de vendas
├── financeiro.prg   # Contas a receber
├── relatorios.prg   # Relatórios financeiros
├── erpex.hbp        # Arquivo de projeto Harbour
├── build.sh         # Script de compilação automatizada
└── README.md        # Documentação do projeto
```

## 🚀 Compilação
No Linux:
```bash
./build.sh
```
▶️ Execução
```
./erp_sistema
```
<img width="1070" height="1040" alt="image" src="https://github.com/user-attachments/assets/dc5d9074-4957-4795-bc2c-0aa3cf171ef0" />
