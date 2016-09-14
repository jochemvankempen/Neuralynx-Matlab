function Header = NLX_Head2Cell(NLXHeader)

% converts the header cell array to a cell array with label and parameter
% separated




NumRows = length(NLXHeader);
for i = 1:NumRows
    if isempty(NLXHeader{i})
        Header{i,1} = '';
        Header{i,2} = '';
    elseif strcmp(NLXHeader{i}(1),'#')
        Header{i,1} = NLXHeader{i};
        Header{i,2} = '';
    elseif ~isempty(strfind(NLXHeader{i},'-'))
        k = strfind(NLXHeader{i},'-');
        [ValName,remainder] = strtok(NLXHeader{i}(k+1:end));
        Header{i,1} = ValName;
        if isempty(str2num(remainder))
            Header{i,2} = remainder;
        else
            Header{i,2} = str2num(remainder);
        end
    else
        continue;
    end
end