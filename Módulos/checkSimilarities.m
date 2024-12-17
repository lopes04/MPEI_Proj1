function [sorted_similarities, sorted_indices] = checkSimilarities(minhash_signature_query, minhash_signatures)
    % Função para calcular similaridades de Jaccard usando assinaturas Minhash
    %
    % Inputs:
    % - minhash_signature_query: Assinatura Minhash do utilizador (vetor coluna)
    % - minhash_signatures: Matriz de assinaturas Minhash (linhas = funções hash, colunas = itens)
    %
    % Outputs:
    % - sorted_similarities: Similaridades ordenadas em ordem decrescente
    % - sorted_indices: Índices dos itens em ordem decrescente de similaridade

    % Verificar consistência das dimensões
    if size(minhash_signature_query, 1) ~= size(minhash_signatures, 1)
        error('A assinatura do utilizador e as assinaturas do conjunto devem ter o mesmo número de funções hash.');
    end

    % Calcular similaridade
    num_hashes = size(minhash_signature_query, 1);
    similarities = sum(minhash_signature_query == minhash_signatures, 1) / num_hashes;

    % Ordenar similaridades em ordem decrescente
    [sorted_similarities, sorted_indices] = sort(similarities, 'descend');
end
