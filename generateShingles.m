function shingle = generateShingles(string_set, shingle_size)
  % Verificar se a entrada é válida
  if ~iscell(string_set) && ~isstring(string_set)
      error('Entrada string_set deve ser uma cell array ou vetor de strings.');
  end
  
  % Converter para cell array de caracteres, se necessário
  if isstring(string_set)
      string_set = cellstr(string_set);
  end

  % Inicializar a saída
  shingle = {};

  % Gerar shingles para cada string no conjunto
  for idx = 1:length(string_set)
      currentString = string_set{idx};      % Frase atual
      chars = char(currentString);         % Tratar como sequência de caracteres
      numChars = length(chars);            % Número total de caracteres

      % Verificar se há caracteres suficientes para criar shingles
      if numChars < shingle_size
          continue; % Ignorar strings menores que o tamanho do shingle
      end

      % Criar shingles de tamanho shingle_size
      for i = 1:(numChars - shingle_size + 1)
          shingle{end + 1} = chars(i:i + shingle_size - 1);
      end
  end

  % Remover duplicatas
  shingle = unique(shingle);
end
