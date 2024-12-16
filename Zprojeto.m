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

%%

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
            %fprintf('Frase com falso positivo: %s\n', testFrases{i});
            %fprintf('Número de telefone associado: %s\n', spamPhone{end});
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