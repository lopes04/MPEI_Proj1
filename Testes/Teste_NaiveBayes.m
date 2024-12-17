load naiveBayes_data.mat

% Criar a tabela (agora todos devem ter o mesmo comprimento)
NaiveBayesMetrics = table(Categoria, precision, recall, f1score, ...
    'VariableNames', {'Categoria','Precisao','Recall','F1Score'});

disp('Métricas por Classe - Naive Bayes:');
disp(NaiveBayesMetrics);

fprintf('Precisão Global: %.2f%%\n', accuracy);

% Gráfico de barras das métricas
figure;
bar([precision recall f1score]);
set(gca,'XTickLabel',order);
ylabel('Valor');
legend('Precisão','Recall','F1-score');
title('Métricas de Desempenho por Categoria - Naive Bayes');
