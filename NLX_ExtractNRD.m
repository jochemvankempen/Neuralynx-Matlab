function NRD = NLX_ExtractNRD(NRD,Index)

% Extracts entries from a NRD structure

if islogical(Index)

    if ~isempty(NRD.TimeStamps);
        NRD.TimeStamps(~Index)=[];
    end
    
    if ~isempty(NRD.Samples);
        NRD.Samples(~Index)=[];
    end
    
else
    
    
end
    
