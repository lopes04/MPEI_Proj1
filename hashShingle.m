%Receber um conjunto de shingles (array ou cell array de strings).
%Converter cada shingle em um valor hash usando uma função de hashing.
%Retornar os valores hash em um vetor.

function shingleHashed = hashShingle(shingleSet)
  % Verificar se a entrada é válida
  if ~iscell(shingleSet)
      error('Entrada shingleSet deve ser uma cell array.');
  end

  % Inicializar vetor de hashes
  shingleHashed = zeros(1, length(shingleSet));

  % Aplicar hash para cada shingle
  for i = 1:length(shingleSet)
      shingleHashed(i) = string2hash(shingleSet{i}); % Chamada da função de hash
  end
end

function hashValue = string2hash(str)
  % Função básica de hash para strings
  % Converte uma string em um valor hash numérico
  hashValue = 0;
  for i = 1:length(str)
      hashValue = mod(hashValue * 31 + double(str(i)), 2^32 - 1);
  end
end
