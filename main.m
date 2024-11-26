% Ler o ficheiro CSV
data = readtable('dataset112_contextual_categories.csv');
% Exibir os nomes das colunas
disp(data.Properties.VariableNames);

% Dividir a coluna única em duas: Frases e Categoria
%splitData = split(data.Var1, ' : '); % Supondo que a única coluna foi nomeada como 'Var1'

%frases = splitData(:, 1); % Coluna com as frases
%categorias = splitData(:, 2); % Coluna com as categoria











% excluir duplicadas
%frases = unique(frases, 'rows');

%converter texto em minusculas
%frases = lower(frases);
%disp(frases)

%------------------------------

