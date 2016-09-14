function NLX = NLX_Cell2Head(NLX,c)

nRows = size(c,1);
for iRow = 1:nRows
    if ~isempty(c{iRow,1}) && isempty(c{iRow,2})
        NLX.Header{iRow,1} = c{iRow,1};
    elseif isempty(c{iRow,1}) && isempty(c{iRow,2})
        NLX.Header{iRow,1} = '';
    elseif ~isempty(c{iRow,1}) && ~isempty(c{iRow,2})
        if isnumeric(c{iRow,2})
            NLX.Header{iRow,1} = ['-' c{iRow,1} ' ' num2str(c{iRow,2})]; 
        elseif ischar(c{iRow,2})
            NLX.Header{iRow,1} = ['-' c{iRow,1} ' ' c{iRow,2}]; 
        end
    end
end

