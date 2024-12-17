import csv
import random
import chardet

def detectar_codificacao(arquivo):
    """Detecta a codificação de um arquivo."""
    with open(arquivo, 'rb') as f:
        resultado = chardet.detect(f.read())
    return resultado['encoding']

def gerar_numero_telefone():
    """Gera um número de telefone aleatório no formato (XX) XXXXX-XXXX."""
    prefixo = random.choice([91, 92, 93, 96])
    sufixo = ''.join(map(str, random.sample(range(0, 10), 7)))
    return f" {prefixo}{sufixo}"

def adicionar_telefones_antes_do_texto(arquivo_csv):
    """Adiciona números de telefone antes da coluna `Text` no CSV, mantendo o separador ':'."""
    # Detecta a codificação do arquivo
    encoding = detectar_codificacao(arquivo_csv)

    # Lê o conteúdo do CSV original
    with open(arquivo_csv, 'r', newline='', encoding=encoding) as arquivo:
        leitor = csv.reader(arquivo, delimiter=':')  # Usa ':' como delimitador
        cabecalho = next(leitor)  # Lê o cabeçalho
        linhas = list(leitor)  # Lê as linhas restantes

    # Atualiza o cabeçalho para incluir a nova coluna
    cabecalho.insert(2, " Phone")
    
    # Adiciona um número de telefone no início de cada linha
    for linha in linhas:
        if len(linha) > 0:
            linha.insert(2, gerar_numero_telefone())

    # Salva o novo conteúdo no mesmo arquivo ou em um novo arquivo
    novo_arquivo_csv = arquivo_csv.replace(".csv", "_com_telefones.csv")
    with open(novo_arquivo_csv, 'w', newline='', encoding='utf-8') as arquivo:
        escritor = csv.writer(arquivo, delimiter=':')  # Usa ':' como delimitador
        escritor.writerow(cabecalho)  # Escreve o cabeçalho atualizado
        escritor.writerows(linhas)  # Escreve as linhas atualizadas

    print(f"Arquivo atualizado salvo como: {novo_arquivo_csv}")

# Exemplo de uso
adicionar_telefones_antes_do_texto("fakedataset.csv")
