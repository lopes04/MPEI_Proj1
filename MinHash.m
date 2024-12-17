% Ler dataset principal

data = readtable('dataset1_com_telefones.csv');

% Dividir a coluna única em duas: Frases e Categoria
splitData = split(data.Text, ' : ');
frases = splitData(:, 1); % Coluna com as frases

% Copiar categorias diretamente da tabela
categorias = data.Category;

% Copiar números diretamente da tabela
numeros = data.Phone;

% Dividir o dataset em treino e teste (60% treino, 40% teste)
numRows = size(data, 1); % Total de linhas
randIndices = randperm(numRows); % Gerar índices aleatórios
trainLimit = round(0.6 * numRows); % Limite de treino

% Índices para treino e teste
trainIndices = randIndices(1:trainLimit);
testIndices = randIndices(trainLimit + 1:end);

% Separar frases, categorias e números para treino
trainFrases = frases(trainIndices);
trainCategorias = categorias(trainIndices);
trainNumeros = numeros(trainIndices);

% Separar frases, categorias e números para teste
testFrases = frases(testIndices);
testCategorias = categorias(testIndices);
testNumeros = numeros(testIndices);

% Processamento das trainFrases
trainFrases = string(trainFrases);
trainFrases = lower(trainFrases); % Converter para minúsculas
frasestoken = tokenizedDocument(trainFrases); % Tokenizar frases
cleanfrasestoken = removeStopWords(frasestoken); % Remover stopwords
cleanfrases = joinWords(cleanfrasestoken); % Reunir palavras
trainFrases = string(cleanfrases);
trainFrases = regexprep(trainFrases, '[.,]', ''); % Remover pontos e vírgulas

% Processamento das testFrases
testFrases = string(testFrases);
testFrases = lower(testFrases); % Converter para minúsculas
frasestoken = tokenizedDocument(testFrases); % Tokenizar frases
cleanfrasestoken = removeStopWords(frasestoken); % Remover stopwords
cleanfrases = joinWords(cleanfrasestoken); % Reunir palavras
testFrases = string(cleanfrases);
testFrases = regexprep(testFrases, '[.,]', ''); % Remover pontos e vírgulas

%%
%Minhash

% 1 -> primeiro vou gerar shingles a partir das frases

shingle_size = 4;

testFrases = cellstr(testFrases);   % converter para cell array de strings para passar de arg para a funcao
trainFrases = cellstr(trainFrases);

% gerar shingles para cada frase de teste e treino
testShingles = cellfun(@(x) generateShingles({x}, shingle_size), testFrases, 'UniformOutput', false);
trainShingles = cellfun(@(x) generateShingles({x}, shingle_size), trainFrases, 'UniformOutput', false);

%exibir os shingles que deram (só para teste)
%disp('Shingles das frases de teste:');
%disp(testShingles);


% 2 -> gerar hashes para o shingles 

testHashedShingles = cellfun(@(x) hashShingle(x), testShingles, 'UniformOutput', false);
trainHashedShingles = cellfun(@(x) hashShingle(x), trainShingles, 'UniformOutput', false);

%disp('Hashes das frases de teste:');
%disp(testHashedShingles);

% 3 -> gerar assinaturas MinHash usando os hashes

% Parâmetros do Minhash
numHashFunctions = 100; % Número de funções hash
prime = 2^32 - 1; % Número primo grande

% Inicializar coeficientes de hashing aleatórios
a = randi([1, prime-1], numHashFunctions, 1); % Coeficientes 'a'
b = randi([0, prime-1], numHashFunctions, 1); % Coeficientes 'b'

% Gerar assinaturas Minhash para treino e teste
testMinhashSignatures = cellfun(@(x) generateMinhashSignatures(x, numHashFunctions, prime, a , b), testHashedShingles, 'UniformOutput', false);
trainMinhashSignatures = cellfun(@(x) generateMinhashSignatures(x, numHashFunctions, prime, a, b), trainHashedShingles, 'UniformOutput', false);

%disp('Assinaturas Minhash das frases de teste:');
%disp(testMinhashSignatures);


% 4 -> similaridade de Jaccard: calcular similaridade entre assinaturas de teste e treino

%limite de similaridade
similarity_threshold = 0.60;

% inicializar matriz de similaridades
similarities = zeros(length(testMinhashSignatures), length(trainMinhashSignatures));

% calcular similaridade entre cada assinatura de teste e cada assinatura de treino
for i = 1:length(testMinhashSignatures)
    for j = 1:length(trainMinhashSignatures)
        % comparar assinaturas e calcular similaridade de Jaccard estimada
        similarities(i, j) = checkSimilarities(testMinhashSignatures{i}, trainMinhashSignatures{j});
    end
end

% exibir matriz de similaridades
%disp('Matriz de similaridades (teste x treino):');
%disp(similarities);

% agora vou fazer a recomendação baseada na similaridade
% primeiro identifico a frase mais semelhante no treino para cada frase do teste
% segundo uso a categoria associada à frase mais semelhante como recomendação

% identificar as frases de treino mais semelhantes para cada frase de teste
[maxSimilarities, bestMatches] = max(similarities, [], 2);

% exibir frases de teste e as suas correspondentes de treino mais semelhantes
disp('Frases de teste e suas correspondentes de treino mais semelhantes:');
for i = 1:length(testFrases)
    if maxSimilarities(i) > similarity_threshold
    fprintf('Frase de teste: "%s"\n', testFrases{i});
    fprintf('Frase mais semelhante no treino: "%s"\n', trainFrases{bestMatches(i)});
    fprintf('Similaridade estimada de Jaccard: %.2f\n\n', maxSimilarities(i));
    end
end

%----------------------------------------------------------------------------------------

% 5 -> recomendações
% o que vou fazer aqui é, antes de ver a similaridade associo cada frase
% treino a uma recomendação, e depois essa frase treino vai dar similar com
% uma frase teste e associo a recomendação que estava associada à frase
% treino à frase similar teste

% Mapeamento da categoria (Naive Bayes) para o tipo de recomendação
category_to_recommendation = containers.Map({'I','B','P'}, {'medical','fires','stealing'});


%associar grupos a recomendações
recommendations = containers.Map();
recommendations('fires') = {
    'Cover the airways with a damp cloth.'
    'Stay away from buildings.'
    'Take the safest route, avoiding areas with fire or heavy smoke.'
    'Cover gaps with wet towels to prevent smoke from entering.'
    'Stay calm.'};

recommendations('stealing') = {
    'Remain calm.'
    'Try to move away from the scene. Do not confront the anyone, especially if he is armed.'
    'Avoid reacting impulsively.'
    'If the theft includes electronic devices or bank cards, block them immediately to prevent fraud.'
    'Do not attempt to recover the belongings.'};

recommendations('medical') = {
    'Seek for help in the surroundings.' 
    'Keep the person conscious and comfortable if possible.' 
    'If the victim is unconscious, check for breathing and begin CPR (cardiopulmonary resuscitation) if necessary.'
    'Do not move the person unless absolutely necessary to avoid worsening possible injuries.'
    'Provide detailed information about the victim condition to medical assistance.'};


% Após prever as categorias, armazenar categorias previstas
%disp('Categorias previstas para frases de teste:');
%disp(categorias_previstas);

%% MinHash para Refinamento por Similaridade

% Criar grupos de frases de treino/teste por categoria
categorias_unicas = unique(categorias_previstas);
for c = 1:length(categorias_unicas)
    % Categoria atual
    categoria_atual = categorias_unicas(c);
    
    % Subconjuntos de treino e teste para a categoria atual
    trainSubset = trainFrases(strcmp(trainCategorias, categoria_atual));
    testSubset = testFrases(strcmp(categorias_previstas, categoria_atual));
    
    if ~isempty(trainSubset) && ~isempty(testSubset)
        % MinHash para a categoria atual
        fprintf('Processando MinHash para a categoria: %s\n', categoria_atual);

        % Gerar shingles
        trainShingles = cellfun(@(x) generateShingles({x}, shingle_size), trainSubset, 'UniformOutput', false);
        testShingles = cellfun(@(x) generateShingles({x}, shingle_size), testSubset, 'UniformOutput', false);

        % Gerar hashes
        trainHashedShingles = cellfun(@(x) hashShingle(x), trainShingles, 'UniformOutput', false);
        testHashedShingles = cellfun(@(x) hashShingle(x), testShingles, 'UniformOutput', false);

        % Gerar assinaturas MinHash
        trainSignatures = cellfun(@(x) generateMinhashSignatures(x, numHashFunctions, prime, a, b), trainHashedShingles, 'UniformOutput', false);
        testSignatures = cellfun(@(x) generateMinhashSignatures(x, numHashFunctions, prime, a, b), testHashedShingles, 'UniformOutput', false);

        % Similaridades
        similarities = zeros(length(testSignatures), length(trainSignatures));
        for i = 1:length(testSignatures)
            for j = 1:length(trainSignatures)
                similarities(i, j) = checkSimilarities(testSignatures{i}, trainSignatures{j});
            end
        end

        % Recomendação com base no MinHash
        for i = 1:length(testSubset)
            similar_indices = find(similarities(i, :) >= similarity_threshold);
            if ~isempty(similar_indices)
                % Frase de treino mais semelhante
                [~, bestMatchIdx] = max(similarities(i, similar_indices));
                bestMatch = similar_indices(bestMatchIdx);
        
                % Obter categoria mapeada para recomendação
                if isKey(category_to_recommendation, categoria_atual)
                    recommendationKey = category_to_recommendation(categoria_atual);
                    if isKey(recommendations, recommendationKey)
                        assignedRecommendation = recommendations(recommendationKey);
                    else
                        assignedRecommendation = {'No recommendation available.'};
                    end
                else
                    assignedRecommendation = {'No recommendation available.'};
                end
        
                % Exibir resultados
                fprintf('Frase de teste: "%s"\n', testSubset{i});
                fprintf('Frase semelhante no treino: "%s"\n', trainSubset{bestMatch});
                fprintf('Similaridade estimada de Jaccard: %.2f\n', max(similarities(i, :)));
                fprintf('Recomendações:\n');
                for r = 1:length(assignedRecommendation)
                    fprintf('- %s\n', assignedRecommendation{r});
                end
                fprintf('\n');
            else
                fprintf('Frase de teste: "%s" não encontrou frases semelhantes no treino.\n\n', testSubset{i});
            end
        end
    else
        fprintf('Nenhum dado para a categoria: %s\n', categoria_atual);
    end
end

linhaMaximo = max(similarities, [], 2);

save MinHash_data.mat
