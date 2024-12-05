function vocabulary = createVocabulary(documents)
    % Função para criar um vocabulário único a partir de um conjunto de documentos
    % Entrada: 
    %   - documents: Cell array onde cada célula contém uma frase ou texto
    % Saída:
    %   - vocabulary: Cell array com as palavras únicas no conjunto de documentos

    % Concatenar todos os documentos em uma única string
    allText = join(documents);

    % Dividir o texto em palavras
    allWords = split(allText);

    % Converter para minúsculas
    allWords = lower(allWords);

    % Remover duplicadas
    vocabulary = unique(allWords);
end
