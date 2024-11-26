% Ler o ficheiro CSV
frases = readtable('dataset112.csv');

% excluir duplicadas
frases = unique(frases, 'rows');

%meter texto em minusculas
frases = lower(frases);
disp(frases)

%------------------------------

% Acessar apenas a coluna de texto para normalização
textData = frases.Text;

% Converter texto para minúsculas
textData = lower(textData);

% Remover pontuações
%textData = erasePunctuation(textData);

% Remover números e caracteres especiais
textData = regexprep(textData, '[^a-zA-Z\s]', ''); % Remove tudo exceto letras e espaços

% Substituir a coluna normalizada na tabela original (se necessário)
frases.Text = textData;

% Exibir as frases normalizadas
disp(frases);
