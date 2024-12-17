%% Opção para inserir dados customizados
    % Ler dataset principal como padrão
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

    trainIndices = randIndices(1:trainLimit);

    trainFrases = frases(trainIndices);
    trainCategorias = categorias(trainIndices);
    trainNumeros = numeros(trainIndices);

% Perguntar ao usuário se deseja usar dados customizados
useCustomData = input('Deseja usar frases customizadas e números de telefone? (s/n): ', 's');

if lower(useCustomData) == 's'
    % Inicializar arrays vazios para frases e números
    customFrases = [];
    customNumeros = [];

    customData = 1;

    % Loop para inserir frases e números customizados
    while true
        frase = input('Digite uma frase (ou pressione Enter para terminar): ', 's');
        if isempty(frase)
            break; % Termina o loop quando o usuário pressiona Enter
        end
        numero = input('Digite o número de telefone associado: ', 's');

        % Adicionar dados ao array
        customFrases = [customFrases; frase];
        customNumeros = [customNumeros; numero];
    end

    % Usar dados customizados como conjunto de teste
    testFrases = string(customFrases);
    testNumeros = string(customNumeros);
    
    % Copiar categorias vazias (placeholder)
    testCategorias = repmat("custom", size(testFrases));
    
else
    testIndices = randIndices(trainLimit + 1:end);

    customData = 0;

    % Separar frases, categorias e números para teste
    testFrases = frases(testIndices);
    testCategorias = categorias(testIndices);
    testNumeros = numeros(testIndices);
end

% Processamento das trainFrases (novo)
trainFrases = string(trainFrases);
trainFrases = lower(trainFrases); % Converter para minúsculas
trainFrasestoken = tokenizedDocument(trainFrases); % Tokenizar frases
cleanTrainFrasestoken = removeStopWords(trainFrasestoken); % Remover stopwords
cleanTrainFrases = joinWords(cleanTrainFrasestoken); % Reunir palavras
trainFrases = string(cleanTrainFrases);
trainFrases = regexprep(trainFrases, '[.,]', ''); % Remover pontos e vírgulas

% Processamento das testFrases
testFrases = string(testFrases);
testFrases = lower(testFrases); % Converter para minúsculas
testFrasestoken = tokenizedDocument(testFrases); % Tokenizar frases
cleanTestFrasestoken = removeStopWords(testFrasestoken); % Remover stopwords
cleanTestFrases = joinWords(cleanTestFrasestoken); % Reunir palavras
testFrases = string(cleanTestFrases);
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

for ctg = 1:length(testFrases)
    numAtual = string(testNumeros(ctg)); % Número atual no conjunto de teste
    
    % Verificar se o número está na lista negra
    if any(strcmp(numAtual, existentSpam))
        validSpamIndices(ctg) = false;
        fprintf('Número %s detetado como SPAM\n', numAtual); % Mensagem de deteção
    end
end

% Retirar as frases e números marcados como SPAM
testFrases = testFrases(validSpamIndices);
testCategorias = testCategorias(validSpamIndices);
testNumeros = testNumeros(validSpamIndices);

%

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

% Verificar falsos positivos no conjunto de teste
falsos_positivos = 0;
falsosPositivosIndices = false(length(testFrases), 1);
spamPhone = {}; %cria array vazio para número de telefones que dêem falso positivo

for i = 1:length(testFrases)
    if membroBF(BF, testFrases{i}, k)
        falsos_positivos = falsos_positivos + 1;
        falsosPositivosIndices(i) = true;

        % Recuperar o número de telefone associado à frase
        phoneIndex = find(strcmp(testFrases{i}, testFrases));

        if ~isempty(phoneIndex)
            spamPhone{end + 1} = string(testNumeros(phoneIndex));  % Encontrar o número associado à frase
            fprintf('Frase com falso positivo: %s\n', testFrases{i});
            fprintf('Número de telefone associado: %s\n', spamPhone{end});
        end
    end
end

testFrases = testFrases(~falsosPositivosIndices);
testCategorias = testCategorias(~falsosPositivosIndices);
testNumeros = testNumeros(~falsosPositivosIndices);

% Exibir os resultados de falsos positivos
%fprintf('Falsos positivos: %d\n', falsos_positivos);
%fprintf('Probabilidade Prática de Falsos Positivos = %.3f%s\n', (falsos_positivos / length(testFrases)) * 100, "%");

% Calcular e exibir a probabilidade teórica de falsos positivos
pfp = (1 - exp(-(k * m) / n))^k;
%fprintf('Probabilidade Teórica Estimada de Falsos Positivos = %.3f%s\n', pfp * 100, "%");

% Exibir os números de telefone correspondentes aos falsos positivos
if ~isempty(spamPhone)
    disp('Números de telefone associados aos falsos positivos:');
    disp(spamPhone);
end

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

if length(testFrases) < 1
    fprintf("\n");
    return;
end
%% Naive Bayes

vocabulary = createVocabulary(trainFrases);
%remover strings vazias
vocabulary = vocabulary(vocabulary ~= "");

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
imagesc(matriz_ocorrencias);

% ------------------------------

% Criar um vetor com a frase correspondente a cada linha da matriz
% O vetor será simplesmente as frases, já que cada linha da matriz ocorrências
% corresponde a uma frase única.
fraseCorrespondente = trainFrases;

% numero de casos favoraveis/ numero de casos possiveis 
% P(I) - prob de calhar I a dividir por todos
% P(B) - ...
% P(P) - ...

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
    fprintf('Frase: "%s" -> Categoria prevista: %s\n', testFrases{i}, categorias_previstas(i));
end
% calcular a precisão
precisao = (correto / length(testCategorias)) * 100;

% exibir a precisão
if customData == 0
    fprintf('Precisão do modelo Naive Bayes: %.2f%%\n', precisao);
end


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

%limite similaridade
similarity_threshold = input('Digite o valor do threshold de similaridade (ex: 0.60): ');
% Verificar se o valor inserido é válido
if isempty(similarity_threshold) || ~isnumeric(similarity_threshold) || similarity_threshold < 0 || similarity_threshold > 1
    disp('Valor inválido! A usar o valor padrão de 0.60.');
    similarity_threshold = 0.60;
end

fprintf('Threshold de similaridade definido como: %.2f\n', similarity_threshold);

% inicializar matriz de similaridades
similarities = zeros(length(testMinhashSignatures), length(trainMinhashSignatures));

% calcular similaridade entre cada assinatura de teste e cada assinatura de treino
for i = 1:length(testMinhashSignatures)
    for j = 1:length(trainMinhashSignatures)
        % comparar assinaturas e calcular similaridade de Jaccard estimada
        similarities(i, j) = checkSimilarities(testMinhashSignatures{i}, trainMinhashSignatures{j});
    end
end


% identificar as frases de treino mais semelhantes para cada frase de teste
[maxSimilarities, bestMatches] = max(similarities, [], 2);

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

showLastResults = input('Deseja ver todas as frases de teste ou apenas as similares? (0/1): ', 's');

% Inicializar contador de frases similares
counter = 0;

for c = 1:length(categorias_unicas)
    % Categoria atual
    categoria_atual = categorias_unicas(c);
    
    % Filtrar subconjuntos de treino e teste para a categoria atual
    trainSubset = trainFrases(strcmp(trainCategorias, categoria_atual));
    testSubset = testFrases(strcmp(categorias_previstas, categoria_atual));
    
    if ~isempty(trainSubset) && ~isempty(testSubset)
        % Gerar shingles e hashes
        trainShingles = cellfun(@(x) generateShingles({x}, shingle_size), trainSubset, 'UniformOutput', false);
        testShingles = cellfun(@(x) generateShingles({x}, shingle_size), testSubset, 'UniformOutput', false);

        trainHashedShingles = cellfun(@(x) hashShingle(x), trainShingles, 'UniformOutput', false);
        testHashedShingles = cellfun(@(x) hashShingle(x), testShingles, 'UniformOutput', false);

        % Gerar assinaturas MinHash
        trainSignatures = cellfun(@(x) generateMinhashSignatures(x, numHashFunctions, prime, a, b), trainHashedShingles, 'UniformOutput', false);
        testSignatures = cellfun(@(x) generateMinhashSignatures(x, numHashFunctions, prime, a, b), testHashedShingles, 'UniformOutput', false);

        % Calcular similaridades
        similarities = zeros(length(testSignatures), length(trainSignatures));
        for i = 1:length(testSignatures)
            for j = 1:length(trainSignatures)
                similarities(i, j) = checkSimilarities(testSignatures{i}, trainSignatures{j});
            end
        end
        
        % Processar recomendações e similaridades relevantes
        for i = 1:length(testSubset)
            currentSimilarities = similarities(i, :); % Linha atual de similaridades
            
            % Encontrar índices com similaridade acima do threshold
            similar_indices = find(currentSimilarities >= similarity_threshold);
            
            if ~isempty(similar_indices)
                % Encontrar a similaridade máxima e o melhor match
                [~, bestMatchIdx] = max(currentSimilarities(similar_indices));
                bestMatch = similar_indices(bestMatchIdx);
                counter = counter + 1;

                % Exibir resultados
                fprintf('Frase de teste: "%s"\n', testSubset{i});
                fprintf('Frase semelhante no treino: "%s"\n', trainSubset{bestMatch});
                fprintf('Similaridade estimada de Jaccard: %.2f\n', currentSimilarities(bestMatch));
                fprintf('\n');
            else
                % Caso não haja similaridade acima do threshold
                if showLastResults == 0
                    fprintf('Frase de teste: "%s" não encontrou frases semelhantes no treino.\n\n', testSubset{i});
                end
            end
        end
    else
        fprintf('Nenhum dado para a categoria: %s\n', categoria_atual);
    end
end

% Exibir contagem e percentagem de frases similares
fprintf('Número de frases similares: %d\n', counter);
fprintf('Percentagem de frases similares: %.2f%%\n', (counter / length(testFrases)) * 100);

linhaMaximo = max(similarities, [], 2); % Máximo ao longo das colunas (dimensão 2)