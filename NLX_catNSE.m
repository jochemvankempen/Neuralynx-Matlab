function NSE = NLX_catNSE(NSE1,NSE2)

% concatenate two NSE structures

if isempty(NSE1)
    NSE = NSE2;
    return;
else
    NSE = NSE1;
end

% NSE.Path = '';

% NSE.Header = [];

if ~isempty(NSE.TimeStamps)
    NSE.TimeStamps = cat(1,NSE.TimeStamps,NSE2.TimeStamps);
end

if ~isempty(NSE.ScNr)
    NSE.ScNr = cat(1,NSE.ScNr,NSE2.ScNr);
end

if ~isempty(NSE.ClusterNr)
    NSE.ClusterNr = cat(1,NSE.ClusterNr,NSE2.ClusterNr);
end

if ~isempty(NSE.SpikeFeatures)
    NSE.SpikeFeatures = cat(2,NSE.SpikeFeatures,NSE2.SpikeFeatures);
end

if ~isempty(NSE.SpikeWaveForm)
    NSE.SpikeWaveForm = cat(3,NSE.SpikeWaveForm,NSE2.SpikeWaveForm);
end

