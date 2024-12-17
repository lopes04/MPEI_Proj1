% Ler ficheiro de SPAM
spamData = readtable('dataset1_com_telefones.csv');
spamData = unique(spamData);

% Dividir frases de número de telefone
splitSpamData = split(spamData.Text, ' : ');
spamFrases = splitSpamData(:, 1); % Coluna com as frases

% Acesse a coluna 'Phone' corretamente
spamNumeros = cell(height(spamData), 1);
for ctg = 1 : height(spamData)
    spamNumeros{ctg} = num2str(spamData.Phone(ctg));  % Converte o número de telefone para string
end

% Carregar números conhecidos como spam
if isfile('lista_negra.csv')
    existentSpamData = readtable('lista_negra.csv');
    existentSpam = string(existentSpamData.PhoneNumber);  % Converte para string
else
    % Ignora passo se ainda não existem números
    disp('File "lista_negra.csv" not found. Initializing empty data.');
    existentSpamData = table([], 'VariableNames', {'PhoneNumber'});
    existentSpam = string([]);  % Cria lista vazia (0 números)
end

% Verificar números de telefone e frases
validSpamIndices = true(height(spamData), 1);  % Inicializa todos os índices como válidos

for ctg = 1 : height(spamData)
    numAtual = spamNumeros{ctg};  %numero atual dentro do for
    
    % Verificar se o número de telefone está na lista negra
    if any(strcmp(numAtual, existentSpam))  % Compara com todos os números da lista

        validSpamIndices(ctg) = false;
        disp(['Número ', numAtual, ' detetado como SPAM']);  % Mensagem de deteção de número
    end
end

% Retira as frases de Spam
validSpamFrases = spamFrases(validSpamIndices);
validSpamNumeros = spamNumeros(validSpamIndices);

% ------------------------------
% Pré-processamento das frases
validSpamFrases = string(validSpamFrases);
validSpamFrases = lower(validSpamFrases);  % Converter para minúsculas
frasestoken = tokenizedDocument(validSpamFrases);

% Remover as stopwords
validSpamFrases = removeStopWords(frasestoken);
validSpamFrases = joinWords(validSpamFrases);

% Limpeza adicional das frases
validSpamFrases = string(validSpamFrases);
validSpamFrases = regexprep(validSpamFrases, '\.$', '');  % Remover pontos finais
validSpamFrases = regexprep(validSpamFrases, ',', '');    % Remover vírgulas

% Dividir o dataset em treino e teste (80% treino, 20% teste)

% Obter o número de linhas filtradas
numValidRows = numel(validSpamFrases);
%randIndices = randperm(numValidRows); %apenas para teste com indices random
trainLimit = round(0.8 * numValidRows);

% Conjuntos de treino e teste
trainFrases = validSpamFrases(1:trainLimit);
testFrases = validSpamFrases(trainLimit + 1:end);

% Criar o vocabulário único das frases
vocabulary = createVocabulary(trainFrases);
vocabulary = vocabulary(vocabulary ~= "");  % Remover strings vazias

%% Configuração do Bloom Filter
p = 0.001;  % Probabilidade de falsos positivos
m = length(trainFrases);
n = round(-(m * log(p) / (log(2))^2));
k = round(((n / m) * log(2)));

% Inicializar Bloom Filter
BF = inicializarBF(n);

%% Adicionar elementos ao filtro
for i = 1:m
    BF = adicionarBF(BF, trainFrases{i}, k);
end

% Verificar falsos negativos no conjunto de treino
falsos = 0;
for i = 1:m
    bool = membroBF(BF, trainFrases{i}, k);
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
        phoneIndex = find(strcmp(testFrases{i}, validSpamFrases));

        if ~isempty(phoneIndex)
            spamPhone{end + 1} = validSpamNumeros{phoneIndex};  % Encontrar o número associado à frase
            fprintf('Frase com falso positivo: %s\n', testFrases{i});
            fprintf('Número de telefone associado: %s\n', spamPhone{end});
        end
    end
end

% Exibir os resultados de falsos positivos
fprintf('Falsos positivos: %d\n', falsos_positivos);
fprintf('Probabilidade Prática de Falsos Positivos = %.3f%s\n', (falsos_positivos / length(testFrases)) * 100, "%");

% Calcular e exibir a probabilidade teórica de falsos positivos
pfp = (1 - exp(-(k * m) / n))^k;
fprintf('Probabilidade Teórica Estimada de Falsos Positivos = %.3f%s\n', pfp * 100, "%");

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