function NSE = NLX_ExtractNSE(NSE,Index)

% Extracts entries from a NSE structure

if islogical(Index)

    if ~isempty(NSE.TimeStamps);
        NSE.TimeStamps(~Index)=[];
    end
    
    if ~isempty(NSE.ScNr);
        NSE.ScNr(~Index)=[];
    end
    
    if ~isempty(NSE.ClusterNr);
        NSE.ClusterNr(~Index)=[];
    end

    if ~isempty(NSE.SpikeFeatures);
        NSE.SpikeFeatures(:,~Index)=[];
    end
    
    if ~isempty(NSE.SpikeWaveForm);
        NSE.SpikeWaveForm(:,:,~Index)=[];
    end
    
else
    
    
end
    
