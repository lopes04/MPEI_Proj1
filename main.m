% Ler o ficheiro CSV
data = readtable('dataset.csv');
% Exibir os nomes das colunas
disp(data.Properties.VariableNames);

% Dividir a coluna única em duas: Frases e Categoria
splitData = split(data.Text, ' : ');

frases = splitData(:, 1); % Coluna com as frases
%categorias = splitData(:, 2); % Coluna com as categoria

categorias = cell(height(data), 1);
for i = 1 : height(data)
    categorias{i} = data.Category{i};
end

disp(categorias)

% Perguntar amanhâ ao stor
% Converter as frases para string e minúsculas para facilitar o processamento
frases = string(frases);
frases = lower(frases);

%excluir duplicadas
frases = unique(frases);

%remover pontos finais e virgulas das frases
frases = regexprep(frases, '\.$', '');
frases = regexprep(frases, ',', '');

% Remover as stopwords usando removeStopWords
frases = tokenizedDocument(frases);
frases = removeStopWords(frases);
frases = joinWords(frases);
frases = string(frases);

disp(frases)

%------------------------------

%criar o vocabulário único das frases (lista de palavras únicas)
vocabulary = createVocabulary(frases);
disp('Vocabulário único:');
disp(vocabulary);

%------------------------------

%criar a matriz Bag-of-Words (número de ocorrências)
numFrases = length(frases);
numWords = length(vocabulary);

%inicializar a matriz com zeros
matriz_ocorrencias = zeros(numFrases, numWords);

%preencher a matriz Bag-of-Words
for i = 1:numFrases
    %dividir a frase atual em palavras
    words = split(frases{i});
    for j = 1:numWords
        %contar as ocorrências da palavra atual na frase atual
        matriz_ocorrencias(i, j) = sum(strcmp(words, vocabulary{j}));
    end
end

%exibir a matriz de ocorrências - linhas = frases || colunas = palavras
%ou seja, esta é a primeira linha da matriz
%1     0     0     0     0     0
%significa que na primeria frase aparece uma vez a primeria palavra da Bag-of-Words
disp('Matriz Ocorrências:');
disp(matriz_ocorrencias);


% ------------------------------

% Criar um vetor com a frase correspondente a cada linha da matriz
% O vetor será simplesmente as frases, já que cada linha da matriz ocorrências
% corresponde a uma frase única.
fraseCorrespondente = frases;

% Exibir o vetor de frases correspondentes
disp('Frase correspondente a cada linha da matriz Bag-of-Words:');
disp(fraseCorrespondente);

% ------------------------------

% numero de casos favoraveis/ numero de casos possiveis 
% P(I) - prob de calhar I a dividir por todos
% P(B) - ...
% P(P) - ...
% Depois tenho que fazer a % P("palavra_à_escolha"|I) = (categoria palavra_à_escolha na classe I) / (numero de palavras na classe I)

