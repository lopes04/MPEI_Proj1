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

% -------------------------------------
% Ler o dataset de SPAM
spamData = readtable('fakedataset_com_telefones.csv');
spamData = unique(spamData); % Remover duplicados

% Dividir frases e números de telefone do fakedataset
splitSpamData = split(spamData.Text, ' : ');
spamFrases = splitSpamData(:, 1); % Coluna com as frases de SPAM
spamNumeros = spamData.Phone; % Coluna com os números de telefone de SPAM

spamFrases = string(spamFrases);
spamFrases = lower(spamFrases); % Converter para minúsculas
spamfrasestoken = tokenizedDocument(spamFrases); % Tokenizar frases
cleanspamfrasestoken = removeStopWords(spamfrasestoken); % Remover stopwords
cleanspamfrases = joinWords(cleanspamfrasestoken); % Reunir palavras
spamFrases = string(cleanspamfrases);
spamFrases = regexprep(spamFrases, '[.,]', ''); % Remover pontos e vírgulas

% Carregar números conhecidos como SPAM
if isfile('lista_negra.csv')
    existentSpamData = readtable('lista_negra.csv');
    existentSpam = string(existentSpamData.PhoneNumber); % Converter para string
else
    disp('File "lista_negra.csv" not found. Initializing empty data.');
    existentSpamData = table([], 'VariableNames', {'PhoneNumber'});
    existentSpam = string([]); % Lista vazia
end

% Verificar números de telefone e frases do conjunto de teste
validSpamIndices = true(length(testFrases), 1); % Inicializar todos os índices como válidos

disp(existentSpam);

for ctg = 1:length(testFrases)
    numAtual = string(testNumeros(ctg)); % Número atual no conjunto de teste
    
    % Verificar se o número está na lista negra
    if any(strcmp(numAtual, existentSpam))
        validSpamIndices(ctg) = false;
        disp(['Número ', numAtual, ' detetado como SPAM']); % Mensagem de deteção
    end
end

% Retirar as frases e números marcados como SPAM
testFrases = testFrases(validSpamIndices);
testCategorias = testCategorias(validSpamIndices);
testNumeros = testNumeros(validSpamIndices);

% Configuração do Bloom Filter
p = 0.001;  % Probabilidade de falsos positivos
m = length(spamFrases);
n = round(-(m * log(p) / (log(2))^2));
k = round(((n / m) * log(2)));

% Inicializar Bloom Filter
BF = inicializarBF(n);

% Adicionar elementos ao filtro
for i = 1:m
    BF = adicionarBF(BF, spamFrases{i}, k);
end

% Verificar falsos negativos no conjunto de treino
falsos = 0;
for i = 1:m
    bool = membroBF(BF, spamFrases{i}, k);
    if bool == false
        falsos = falsos + 1;
    end
end
%disp(falsos);  % Exibir o número de falsos negativos

% Verificar falsos positivos no conjunto de teste
falsos_positivos = 0;
spamPhone = {}; %cria array vazio para número de telefones que dêem falso positivo

for i = 1:length(testFrases)
    if membroBF(BF, testFrases{i}, k)
        falsos_positivos = falsos_positivos + 1;

        % Recuperar o número de telefone associado à frase
        phoneIndex = find(strcmp(testFrases{i}, testFrases));

        if ~isempty(phoneIndex)
            spamPhone{end + 1} = testNumeros(phoneIndex);  % Encontrar o número associado à frase
            fprintf('Frase com falso positivo: %s\n', testFrases{i});
            fprintf('Número de telefone associado: %s\n', spamPhone{end});
        end
    end
end

% Exibir os resultados de falsos positivos
%fprintf('Falsos positivos: %d\n', falsos_positivos);
%fprintf('Probabilidade Prática de Falsos Positivos = %.3f%s\n', (falsos_positivos / length(testFrases)) * 100, "%");

% Calcular e exibir a probabilidade teórica de falsos positivos
pfp = (1 - exp(-(k * m) / n))^k;
%fprintf('Probabilidade Teórica Estimada de Falsos Positivos = %.3f%s\n', pfp * 100, "%");

% Exibir os números de telefone correspondentes aos falsos positivos
disp('Números de telefone associados aos falsos positivos:');
disp(spamPhone);

%transpor array para coluna
spamPhone = spamPhone';

% Converter em tabela
newSpamData = table(spamPhone, 'VariableNames', {'PhoneNumber'});


newSpamData.PhoneNumber = string(newSpamData.PhoneNumber); % Convert to string


%Adiciona novos números spam aos já existentes
combinedSpamData = [existentSpamData; newSpamData];

% Verificação de duplicados
%combinedData = unique(combinedData);

% Atualiza o CSV
writetable(combinedSpamData, 'lista_negra.csv');

%tabela das métricas do bloom filter
practical_fp_rate = (falsos_positivos / length(testFrases)) * 100;

BF_metrics = table(n, k, p, pfp*100, falsos_positivos, practical_fp_rate, falsos, ...
    'VariableNames', {'TamanhoFiltro_N','FuncoesHash_k','Prob_p','FP_Teorico_%','FP_Contagem','FP_Pratica_%','FN_Contagem'});

disp('Métricas do Bloom Filter:');
disp(BF_metrics);

%grafico para comparar falsos positivos teorico vs pratico
figure;
bar([pfp*100, practical_fp_rate]);
set(gca, 'XTickLabel', {'Prob. Teórica', 'Prob. Prática'});
ylabel('Taxa de Falsos Positivos (%)');
title('Comparação da Probabilidade de Falsos Positivos - Bloom Filter');



%%
% Naive Bayes

% Exibir resultados para validação
%disp('Conjunto de treino (frases):');
%disp(trainFrases);

%disp('Conjunto de treino (categorias):');
%disp(trainCategorias);

%disp('Conjunto de teste (frases):');
%disp(testFrases);

%disp('Conjunto de teste (categorias):');
%disp(testCategorias);
    
%------------------------------

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
%disp('Matriz Ocorrências:');
%disp(matriz_ocorrencias);
imagesc(matriz_ocorrencias)
% ------------------------------

% Criar um vetor com a frase correspondente a cada linha da matriz
% O vetor será simplesmente as frases, já que cada linha da matriz ocorrências
% corresponde a uma frase única.
fraseCorrespondente = trainFrases;
%disp(trainFrases);

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
%disp('Probabilidades das categorias:');
for ctg = 1:length(categorias_unicas)
    %fprintf('P(%s) = %.3f\n', categorias_unicas(ctg), probabilidades_categoria(ctg));
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
    %fprintf('Probabilidades condicionais para a categoria %s:\n', categorias_unicas(ctg));
    for j = 1:numWords
        %fprintf('P(%s | %s) = %.4f\n', vocabulary{j}, categorias_unicas(ctg), prob_cond(ctg, j));
    end
    %fprintf('\n');
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
%disp('Frases e suas categorias previstas:');
for i = 1:length(testFrases)
    %fprintf('Frase: "%s" -> Categoria prevista: %s\n', testFrases{i}, categorias_previstas(i));
end
% calcular a precisão
precisao = (correto / length(testCategorias)) * 100;

% exibir a precisão
fprintf('Precisão do modelo Naive Bayes: %.2f%%\n', precisao);

%vou fazer uma matriz de confusão entre as categorias I, B, P
[cm, order] = confusionmat(testCategorias, categorias_previstas);

disp('Matriz de Confusão (Linhas: Verdadeiro, Colunas: Previsto):');
disp(array2table(cm,'VariableNames',cellstr(order'),'RowNames',cellstr(order')));

% Exibição da matriz de confusão em forma gráfica
figure;
confusionchart(cm, order);
title('Matriz de Confusão - Naive Bayes');

% Cálculo de métricas por classe
numClasses = length(order);
precision = zeros(numClasses,1);
%recall mede casos que foram identificados como positivos
recall = zeros(numClasses,1); %quanto mais alto o recall, menos falsos positivos há
%f1score é média entre precisão e recall
f1score = zeros(numClasses,1); %quanto mais próximo de 1 melhor o modelo

for i = 1:numClasses
    TP = cm(i,i);
    FP = sum(cm(:,i)) - TP;
    FN = sum(cm(i,:)) - TP;
    precision(i) = TP / (TP + FP);
    recall(i) = TP / (TP + FN);
    f1score(i) = 2 * (precision(i)*recall(i)) / (precision(i) + recall(i));
end

accuracy = (sum(diag(cm)) / sum(cm(:))) * 100;

% Converter order em string se necessário
if iscell(order)
    Categoria = string(order);
else
    Categoria = order;
end

% Criar a tabela (agora todos devem ter o mesmo comprimento)
NaiveBayesMetrics = table(Categoria, precision, recall, f1score, ...
    'VariableNames', {'Categoria','Precisao','Recall','F1Score'});

disp('Métricas por Classe - Naive Bayes:');
disp(NaiveBayesMetrics);

fprintf('Precisão Global: %.2f%%\n', accuracy);

% Gráfico de barras das métricas
figure;
bar([precision recall f1score]);
set(gca,'XTickLabel',order);
ylabel('Valor');
legend('Precisão','Recall','F1-score');
title('Métricas de Desempenho por Categoria - Naive Bayes');



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

%Gráfico de Distribuição de Similaridades
allSimilarities = similarities(:);

figure;
histogram(allSimilarities, 'Normalization','pdf');
title('Distribuição das Similaridades MinHash (Jaccard estimado)');
xlabel('Similaridade');
ylabel('Densidade');

% Estatísticas descritivas
meanSimilarity = mean(allSimilarities);
medianSimilarity = median(allSimilarities);
fprintf('Similaridade Média: %.2f\n', meanSimilarity);
fprintf('Mediana da Similaridade: %.2f\n', medianSimilarity);


%bloxpot de similaridade
%O boxplot das similaridades de MinHash é uma representação gráfica 
%que mostra a distribuição das similaridades estimadas (via MinHash) entre pares de frases do conjunto de teste e treino
figure;
boxplot(allSimilarities);
title('Boxplot das Similaridades MinHash');
ylabel('Similaridade');


%tabela dos top 5 mais similares
% Encontrar os top 5 pares de maior similaridade
[sortedVals, sortedIdx] = sort(allSimilarities, 'descend');
topN = 5;
topIndices = sortedIdx(1:topN);
[ti, tj] = ind2sub(size(similarities), topIndices);

TopPairsTable = table(testFrases(ti), trainFrases(tj), sortedVals(1:topN), ...
    'VariableNames', {'FraseTeste','FraseTreino','Similaridade'});
disp('Top 5 pares mais similares (teste-treino):');
disp(TopPairsTable);

