function hash=string2hash(str,type)
% This function generates a hash value from a text string
%
% hash=string2hash(str,type);
%
% inputs,
%   str : The text string, or array with text strings.
% outputs,
%   hash : The hash value, integer value between 0 and 2^32-1
%   type : Type of has 'djb2' (default) or 'sdbm'
%
% example,
%
%  hash=string2hash('hello world');
%  disp(hash);


% passa de string para double array
str=double(str);

if(nargin<2), type='djb2'; end


switch(type)
    case 'djb2'
        hash = 5381*ones(size(str,1),1); 
        for i=1:size(str,2)
            hash = mod(hash * 33 + str(:,i), 2^32-1); 
        end

    case 'sdbm'
        hash = zeros(size(str,1),1);
        for i=1:size(str,2) 
            hash = mod(hash * 65599 + str(:,i), 2^32-1);
        end

    otherwise
        error('string_hash:inputs','unknown type');
end