load BF_data.mat

%tabela das métricas do bloom filter
practical_fp_rate = (falsos_positivos / length(testFrases));

BF_metrics = table(n, k, p, pfp, falsos_positivos, practical_fp_rate, 'VariableNames', {'TamanhoFiltro_N','FuncoesHash_k','Prob_p','FP_Teorico_','FP_Contagem','FP_Pratica'});

disp('Métricas do Bloom Filter:');
disp(BF_metrics);

%grafico para comparar falsos positivos teorico vs pratico
figure;
bar([pfp, practical_fp_rate]);
set(gca, 'XTickLabel', {'Prob. Teórica', 'Prob. Prática'});
ylabel('Taxa de Falsos Positivos (%)');
title('Comparação da Probabilidade de Falsos Positivos - Bloom Filter');