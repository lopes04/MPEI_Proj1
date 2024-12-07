function BF = adicionarBF(BF, elemento, k)
%ADICIONARBF Summary of this function goes here
%   Detailed explanation goes here
    for i = 1:k

        elemento = [elemento num2str(i^2*10001)]; % Essa linha concatena o elemento (original) com uma string numérica gerada por i2×10001.
                                                  % O objetivo é criar variações diferentes do elemento para cada função hash.
                                                  %Exemplo:
    %Se o elemento for "casa" e i=1, ele será transformado em "casa10001".
    %Para i=2, será "casa40004", e assim por diante. (cada hash único para cada i)

        indice = mod(string2hash(elemento),length(BF))+1; 
        % string2hash(elemento, 'djb2'):
            %Converte a string (elemento) em um valor hash numérico.

        %mod(..., length(B)):
            %Calcula o valor da posição no vetor B usando o operador módulo (%), garantindo que o índice esteja dentro do intervalo válido (1 a length(B)).

        %+1:
            %Ajusta o índice para corresponder ao formato de indexação do MATLAB, que começa em 1.
               
        BF(indice) = 1;

    end
end

