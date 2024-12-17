load MinHash_data.mat


%Gráfico de Distribuição de Similaridades

figure;
histogram(linhaMaximo, 'Normalization','pdf');
title('Distribuição das Similaridades MinHash (Jaccard estimado)');
xlabel('Similaridade');
ylabel('Densidade');

% Estatísticas descritivas
meanSimilarity = mean(linhaMaximo);
medianSimilarity = median(linhaMaximo);
fprintf('Similaridade Média: %.2f\n', meanSimilarity);
fprintf('Mediana da Similaridade: %.2f\n', medianSimilarity);