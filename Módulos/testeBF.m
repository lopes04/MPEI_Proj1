%% TESTE DO MÓDULO BLOOM FILTER
clc; clear; close all;

%% Funções Auxiliares e Configuração Inicial
fprintf('TESTE DO MÓDULO BLOOM FILTER\n');
fprintf('----------------------------\n');

% Parâmetros do teste
p = 0.001;  % Probabilidade de falsos positivos
m = 20;     % Número de frases de treino (pequeno para teste)

% Frases de treino e teste para simulação
trainFrases = ["spam detected", "your account is blocked", "win a prize now", ...
               "urgent action required", "this is not a drill", "call this number"];

testFrases = ["spam detected", "call this number", "unknown message", ...
              "prize notification", "fake spam alert", "your password expired"];

% Tamanho total e funções hash do Bloom Filter
n = round(-(m * log(p) / (log(2))^2));
k = round(((n / m) * log(2)));

fprintf('Configuração:\n');
fprintf('- Probabilidade de Falsos Positivos: %.3f%%\n', p * 100);
fprintf('- Tamanho do Filtro (n): %d bits\n', n);
fprintf('- Número de Funções Hash (k): %d\n\n', k);

%% Inicializar e Popular o Bloom Filter
fprintf('PASSO 1: Inicializar e Popular o Bloom Filter\n');
BF = inicializarBF(n);

% Adicionar frases ao Bloom Filter
for i = 1:length(trainFrases)
    BF = adicionarBF(BF, trainFrases(i), k);
end
fprintf('Bloom Filter preenchido com %d frases.\n\n', length(trainFrases));

%% Teste de Falsos Negativos (Devem ser Zero)
fprintf('PASSO 2: Testar Falsos Negativos\n');
falsosNegativos = 0;
for i = 1:length(trainFrases)
    if ~membroBF(BF, trainFrases(i), k)
        falsosNegativos = falsosNegativos + 1;
        fprintf('Falso Negativo Detetado: %s\n', trainFrases(i));
    end
end
fprintf('Total de Falsos Negativos: %d\n\n', falsosNegativos);

%% Teste de Falsos Positivos
fprintf('PASSO 3: Testar Falsos Positivos\n');
falsosPositivos = 0;
for i = 1:length(testFrases)
    if membroBF(BF, testFrases(i), k) && ~ismember(testFrases(i), trainFrases)
        falsosPositivos = falsosPositivos + 1;
        fprintf('Falso Positivo Detetado: %s\n', testFrases(i));
    end
end
fprintf('Total de Falsos Positivos: %d\n', falsosPositivos);

% Probabilidade prática de falsos positivos
probabilidadePratica = (falsosPositivos / length(testFrases)) * 100;
fprintf('Probabilidade Prática de Falsos Positivos: %.3f%%\n', probabilidadePratica);

%% Probabilidade Teórica de Falsos Positivos
pfp = (1 - exp(-(k * m) / n))^k;
fprintf('Probabilidade Teórica Estimada de Falsos Positivos: %.3f%%\n', pfp * 100);

%% Teste Final
fprintf('\nTESTE CONCLUÍDO:\n');
if falsosNegativos == 0
    fprintf('- SUCESSO: Nenhum falso negativo encontrado.\n');
else
    fprintf('- ERRO: Foram encontrados %d falsos negativos.\n', falsosNegativos);
end

fprintf('- Falsos Positivos Detetados: %d\n', falsosPositivos);
fprintf('- Probabilidade Prática vs. Teórica: %.3f%% vs. %.3f%%\n', probabilidadePratica, pfp * 100);
