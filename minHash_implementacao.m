%% Naive Bayes

% Ler o ficheiro CSV
data = readtable('dataset1_com_telefones.csv');
% Exibir os nomes das colunas
%disp(data.Properties.VariableNames);

% Dividir a coluna única em duas: Frases e Categoria
splitData = split(data.Text, ' : ');

frases = splitData(:, 1); % Coluna com as frases
%categorias = splitData(:, 2); % Coluna com as categoria


categorias = cell(height(data), 1);
for ctg = 1 : height(data)
    categorias{ctg} = data.Category{ctg};
end
%disp(categorias);

%rrmover linhas duplicadas
%(fazer isto)


% ------------------------------
%dividir o dataset em treino e teste (60% treino, 40% teste)

% Total de linhas
numRows = size(data, 1);

% Gerar índices aleatórios
randIndices = randperm(numRows);

% Determinar limites para treino e teste
trainLimit = round(0.6 * numRows);

% Conjuntos de treino e teste
trainIndices = randIndices(1:trainLimit);
testIndices = randIndices(trainLimit + 1:end);

% Separar frases e categorias para treino
trainFrases = frases(trainIndices);
trainCategorias = categorias(trainIndices);

% Separar frases e categorias para teste
testFrases = frases(testIndices);
testCategorias = categorias(testIndices);

% Exibir resultados para validação
%disp('Conjunto de treino (frases):');
%disp(trainFrases);

%disp('Conjunto de treino (categorias):');
%disp(trainCategorias);

%disp('Conjunto de teste (frases):');
%disp(testFrases);

%disp('Conjunto de teste (categorias):');
%disp(testCategorias);
    
%--------------------------------

% Processamento das trainFrases

% Converter as frases para string para facilitar o processamento
trainFrases = string(trainFrases);
trainFrases = lower(trainFrases);
frasestoken = tokenizedDocument(trainFrases);
%customStopWords = [stopWords "there's" "someone"];
%customStopWords = string(customStopWords);

% Remover as stopwords usando removeStopWords
cleanfrasestoken = removeStopWords(frasestoken);
cleanfrases = joinWords(cleanfrasestoken);

trainFrases = string(cleanfrases);
%remover pontos finais das frases
trainFrases = regexprep(trainFrases, '\.$', '');
%remover virgulas das frases
trainFrases = regexprep(trainFrases, ',', '');


%converter texto em minusculas
trainFrases = lower(trainFrases);
disp(trainFrases);


% Processamento das testFrases

% Converter as frases para string para facilitar o processamento
testFrases = string(testFrases);
testFrases = lower(testFrases);
frasestoken = tokenizedDocument(testFrases);
%customStopWords = [stopWords "there's" "someone"];
%customStopWords = string(customStopWords);

% Remover as stopwords usando removeStopWords
cleanfrasestoken = removeStopWords(frasestoken);
cleanfrases = joinWords(cleanfrasestoken);

testFrases = string(cleanfrases);
%remover pontos finais das frases
testFrases = regexprep(testFrases, '\.$', '');
%remover virgulas das frases
testFrases = regexprep(testFrases, ',', '');


%converter texto em minusculas
testFrases = lower(testFrases);
disp(testFrases);

%------------------------------

%criar o vocabulário único das frases (lista de palavras únicas)
vocabulary = createVocabulary(trainFrases);
%remover strings vazias
vocabulary = vocabulary(vocabulary ~= "");
%disp('Vocabulário único:');
%disp(vocabulary);

%------------------------------

%criar a matriz Bag-of-Words (número de ocorrências)
numFrases = length(trainFrases);
numWords = length(vocabulary);

%inicializar a matriz com zeros
matriz_ocorrencias = zeros(numFrases, numWords);

%preencher a matriz Bag-of-Words
for ctg = 1:numFrases
    %dividir a frase atual em palavras
    words = split(trainFrases{ctg});
    for j = 1:numWords
        %contar as ocorrências da palavra atual na frase atual
        matriz_ocorrencias(ctg, j) = sum(strcmp(words, vocabulary{j}));
    end
end

%exibir a matriz de ocorrências - linhas = frases || colunas = palavras
%ou seja, esta é a primeira linha da matriz
%1     0     0     0     0     0
%significa que na primeria frase aparece uma vez a primeria palavra da Bag-of-Words
disp('Matriz Ocorrências:');
disp(matriz_ocorrencias);
imagesc(matriz_ocorrencias)
% ------------------------------

% Criar um vetor com a frase correspondente a cada linha da matriz
% O vetor será simplesmente as frases, já que cada linha da matriz ocorrências
% corresponde a uma frase única.
fraseCorrespondente = trainFrases;
disp(trainFrases);

% ------------------------------

% numero de casos favoraveis/ numero de casos possiveis 
% P(I) - prob de calhar I a dividir por todos
% P(B) - ...
% P(P) - ...

% Depois tenho que fazer a % P("palavra_à_escolha"|I) = (categoria palavra_à_escolha na classe I) / (numero de palavras na classe I)
% fazer isto para os três casos, I, P, B


%calcular P(I), P(B) e P(P)

%categorias
categorias_unicas = ['I', 'B', 'P'];

%probs das categorias
probabilidades_categoria = zeros(length(categorias_unicas), 1);

%contar ocorrências de cada categoria e calcular a probabilidade
for ctg = 1:length(categorias_unicas)
    categoria_count = sum(strcmp(trainCategorias, categorias_unicas(ctg))); %retorna 1 se forem iguais e soma todos os 1
    probabilidades_categoria(ctg) = categoria_count / length(trainCategorias); %casos favoraveis a dividir por casos totais
end


%exibir as probabilidades das categorias
disp('Probabilidades das categorias:');
for ctg = 1:length(categorias_unicas)
    fprintf('P(%s) = %.3f\n', categorias_unicas(ctg), probabilidades_categoria(ctg));
end
%calcular probs condicionadas

%criar matriz prob cond para cada palavra dada uma categoria
num_categorias = length(categorias_unicas);
prob_cond = zeros(num_categorias, numWords); %aqui linhas = categorias e colunas = palavras

%suavização de laplace (para evitar prob zero)
suavizacao_laplace = 1;

%calcular P(palavra | categoria)
for c = 1:num_categorias
    %vou filtrar frases que pertencem à categoria atual
    categoria_atual = categorias_unicas(c);
    indices_categorias = strcmp(trainCategorias, categoria_atual); %retorna 1 se for a mesma categoria
    frases_categoria = trainFrases(indices_categorias);

    %contar ocorrências de cada palavra nas frases da categoria
    total_palavras_categoria = 0;
    palavras_por_categoria = zeros(1, numWords); %counter para cada palavra

    for f = 1:length(frases_categoria)
        %dividir frase em palavras
        palavras = split(frases_categoria{f});

        %atualizar contadores
        total_palavras_categoria = total_palavras_categoria + length(palavras);

        for p = 1:numWords
            palavras_por_categoria(p) = palavras_por_categoria(p) + sum(strcmp(palavras, vocabulary{p}));
        end
    end

    %calcular probs cond
    prob_cond(c, :) = (palavras_por_categoria + suavizacao_laplace) ./ (total_palavras_categoria + numWords * suavizacao_laplace);
end


for ctg = 1:num_categorias
    fprintf('Probabilidades condicionais para a categoria %s:\n', categorias_unicas(ctg));
    for j = 1:numWords
        fprintf('P(%s | %s) = %.4f\n', vocabulary{j}, categorias_unicas(ctg), prob_cond(ctg, j));
    end
    fprintf('\n');
end


%--------------------

% depois para finalizar naive bayes:
% P(categoria∣frase) = P(categoria) * ∏ P(palavra∣categoria) , ∏ é o multiplicatório
% é melhor usamos logaritmo para evitar underflow, valores muito pequenos


% inicializar vetor para armazenar categorias previstas
categorias_previstas = strings(length(testFrases), 1);

% variavel para avaliar precisão (ver quantas estão corretas)
correto = 0;

% Classificar cada frase de teste
for i = 1:length(testFrases)
    % Dividir a frase de teste em palavras
    words = split(testFrases{i});
    
    % Inicializar vetor para probabilidades posteriores
    prob_posterior = zeros(num_categorias, 1);
    
    % Calcular a probabilidade posterior para cada categoria
    for c = 1:num_categorias
        % P(Categoria) inicial (log)
        prob_posterior(c) = log(probabilidades_categoria(c));
        
        % Somar log(P(palavra | categoria)) para cada palavra na frase
        for j = 1:length(words)
            if ismember(words{j}, vocabulary) % Garantir que a palavra está no vocabulário
                wordIndex = find(strcmp(vocabulary, words{j}));
                prob_posterior(c) = prob_posterior(c) + log(prob_cond(c, wordIndex));
            end
        end
    end
    
    % Escolher a categoria com maior probabilidade posterior
    [~, idxMax] = max(prob_posterior);
    categorias_previstas(i) = categorias_unicas(idxMax);
    % ver as que estão certas para a precisão
    if categorias_previstas(i) == testCategorias(i)
        correto = correto + 1;
    end
end

% categorias previstas com as frases correspondentes
disp('Frases e suas categorias previstas:');
for i = 1:length(testFrases)
    fprintf('Frase: "%s" -> Categoria prevista: %s\n', testFrases{i}, categorias_previstas(i));
end
% calcular a precisão
precisao = (correto / length(testCategorias)) * 100;

% exibir a precisão
fprintf('Precisão do modelo Naive Bayes: %.2f%%\n', precisao);

%% acabou aqui Naive Bayes
%--------------------------------------------------------------------------------------------------------------------------------------

%% MinHash

% 1 -> primeiro vou gerar shingles a partir das frases

shingle_size = 4;

testFrases = cellstr(testFrases);   % converter para cell array de strings para passar de arg para a funcao
trainFrases = cellstr(trainFrases);

% gerar shingles para cada frase de teste e treino
testShingles = cellfun(@(x) generateShingles({x}, shingle_size), testFrases, 'UniformOutput', false);
trainShingles = cellfun(@(x) generateShingles({x}, shingle_size), trainFrases, 'UniformOutput', false);

%exibir os shingles que deram (só para teste)
disp('Shingles das frases de teste:');
disp(testShingles);


% 2 -> gerar hashes para o shingles 

testHashedShingles = cellfun(@(x) hashShingle(x), testShingles, 'UniformOutput', false);
trainHashedShingles = cellfun(@(x) hashShingle(x), trainShingles, 'UniformOutput', false);

disp('Hashes das frases de teste:');
disp(testHashedShingles);

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

disp('Assinaturas Minhash das frases de teste:');
disp(testMinhashSignatures);


% 4 -> similaridade de Jaccard: calcular similaridade entre assinaturas de teste e treino

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
disp('Matriz de similaridades (teste x treino):');
disp(similarities);

% agora vou fazer a recomendação baseada na similaridade
% primeiro identifico a frase mais semelhante no treino para cada frase do teste
% segundo uso a categoria associada à frase mais semelhante como recomendação

% identificar as frases de treino mais semelhantes para cada frase de teste
[maxSimilarities, bestMatches] = max(similarities, [], 2);

% exibir frases de teste e as suas correspondentes de treino mais semelhantes
disp('Frases de teste e suas correspondentes de treino mais semelhantes:');
for i = 1:length(testFrases)
    if maxSimilarities(i) > 0.45
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

%limite de similaridade
similarity_threshold = 0.45;

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
disp('Categorias previstas para frases de teste:');
disp(categorias_previstas);

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