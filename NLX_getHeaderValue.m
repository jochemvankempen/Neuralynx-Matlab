function value = NLX_getHeaderValue(NLXHeader,label)

for i=1:length(NLXHeader)
    j = strfind(NLXHeader{i},['-' label]);
    nChars = length(['-' label]);
    if ~isempty(j) && j==1 && strcmp(NLXHeader{i}(nChars+1),' ')
        value = str2double(NLXHeader{i}(nChars+2:end));
    end
end