function minhash_signature = generateMinhashSignatures(shingles_hash, num_hashes, prime, a, b)
    % Função para calcular as assinaturas Minhash
    %
    % Inputs:
    % - shingles_hash: Array com os hashes dos shingles
    % - num_hashes: Número de funções hash para gerar as assinaturas
    % - prime: Número primo grande para modular hashing
    %
    % Output:
    % - minhash_signature: Vetor com as assinaturas Minhash

   

    % Inicializar a assinatura com valores infinitos
    minhash_signature = inf(num_hashes, 1);

    % Calcular assinaturas para cada função hash
    for i = 1:num_hashes
        hash_values = mod(a(i) * shingles_hash + b(i), prime); % Aplicar função hash
        minhash_signature(i) = min(hash_values); % Encontrar o menor valor para a função hash
    end
end
