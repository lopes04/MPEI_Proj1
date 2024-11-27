% Ler o ficheiro CSV
data = readtable('dataset.csv');
% Exibir os nomes das colunas
disp(data.Properties.VariableNames);

% Dividir a coluna única em duas: Frases e Categoria
splitData = split(data.Text, ' : ');

frases = splitData(:, 1); % Coluna com as frases
%categorias = splitData(:, 2); % Coluna com as categoria

categorias = cell(height(data), 1); % Pre-allocate a numeric array
for i = 1 : height(data)
    categorias{i} = data.Category{i};
end

disp(categorias)

% excluir duplicadas
frases = unique(frases, 'rows');

%converter texto em minusculas
frases = lower(frases);
disp(frases)

%------------------------------

