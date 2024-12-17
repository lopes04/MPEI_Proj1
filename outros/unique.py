def remover_linhas_duplicadas(arquivo_entrada, arquivo_saida):
    """Lê um arquivo, remove linhas duplicadas e salva o resultado em um novo arquivo."""
    with open(arquivo_entrada, 'r', encoding='utf-8') as file:
        linhas = file.readlines()
    
    # Usar um conjunto para eliminar duplicatas, mantendo a ordem original
    linhas_unicas = list(dict.fromkeys(linhas))
    
    # Salvar no novo arquivo
    with open(arquivo_saida, 'w', encoding='utf-8') as file:
        file.writelines(linhas_unicas)

    print(f"Linhas duplicadas removidas. Arquivo salvo como: {arquivo_saida}")

# Caminho do arquivo original e do arquivo de saída
arquivo_entrada = "dataset1.csv"
arquivo_saida = "dataset1.csv"

# Executar a função
remover_linhas_duplicadas(arquivo_entrada, arquivo_saida)
