% a assinatura de uma frase será composta pelos menores valores gerados pelas kk funções hash
function minhashSignatures = generateMinhashSignatures(Set, k, R, p)
    % Função para calcular assinaturas Minhash para um conjunto de frases
    %
    % Inputs:
    % - Set: Cell array, cada elemento contém os shingles de uma frase
    % - k: Número de funções hash (número de linhas da assinatura)
    % - R: Matriz de coeficientes aleatórios (k x 2), colunas para 'a' e 'b'
    % - p: Número primo grande para modular hashing
    %
    % Output:
    % - MA: Matriz de assinaturas Minhash (k x Nu), onde Nu é o número de frases

    Nu = length(Set);  % Número de frases
    minhashSignatures = inf(k, Nu);   % Inicializar com infinito para encontrar o mínimo

    for hf = 1:k
        % Coeficientes da função hash atual
        a = R(hf, 1);
        b = R(hf, 2);
        for user = 1:Nu
            conjunto = Set{user};  % Conjunto de shingles da frase atual
            hash_codes = zeros(1, length(conjunto));  % Vetor para armazenar os hashes
            for elem = 1:length(conjunto)
                % Aplicar função de hash personalizada
                hash_codes(elem) = mod(a * hashShingle(conjunto(elem)) + b, p);
            end
            % Encontrar o menor hash (Minhash)
            minhash = min(hash_codes);
            minhashSignatures(hf, user) = minhash;
        end
    end
end