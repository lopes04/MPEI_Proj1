%% Aplica as k funções como adicionarElemento(), mas apenas verifica se as posições contêm o valor 1
%%  – Se alguma das posições contém 0 não é um membro do conjunto

%% A pior situação em termos de tempo de processamento ocorre para membros e para falsos positivos 
%% – Ambos obrigam a calcular todas as k funções de dispersão
function boleano = membroBF(BF, elemento, k)
    boleano = true;
    for i = 1:k
        elemento = [elemento num2str(i^2*10001)];
        indice = mod(string2hash(elemento),length(BF))+1;

        if BF(indice) == 0
            boleano = false;
            break;
        end
    end 
    
end