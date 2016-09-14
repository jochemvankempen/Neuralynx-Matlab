function hull = NLX_getBoundaries(NSE,index)
% get the boundaries of waveforms
%   hull = NLX_getBoundaries(NSE,index)
% index ... logical index or cluster nrs
%
% NSE.TimeStamps ...... [1 x NumSpikes] microseconds (10^-6s)
% NSE.ScNr ............ [1 x NumSpikes] Nr of Sc-Channel (Electrode)
% NSE.ClusterNr ....... [1 x NumSpikes] Nr of Cluster
% NSE.SpikeFeatures ... [8 x NumSpikes] Featurvalues for each spike
% NSE.SpikeWaveForm ... [32 x 1 x NumSpikes] 32 point sample of each spike

[nBins,nDummy,N] = size(NSE.SpikeWaveForm);

if islogical(index)
    n = sum(index);
    nClust = 1;
elseif isempty(index)
    n = sum(index);
    nClust = 1;
    index = true(N,1);
else
    ClusterNr = index;
    nClust = length(ClusterNr);
    clear index;
    index = false(N,nClust);
    for i=1:nClust
        index(:,i) = NSE.ClusterNr==ClusterNr(i);
    end
end


hull = zeros(nBins,2,nClust).*NaN;
for i=1:nClust
    if any(index(:,i))
        hull(:,1,i) = max(NSE.SpikeWaveForm(:,1,index(:,i)),[],3);
        hull(:,2,i) = min(NSE.SpikeWaveForm(:,1,index(:,i)),[],3);
    end
end

end

