function NSE = NLX_ExtractCluster(NSE,ClusterNr,savefile)

% Extracts a cluster (e.g. previously selected by SpikeSort) from a *.NSE file
% NSE ......... structure, see NLX_loadNSE.m
% ClusterNr ... array of cluster nr

[Index,NSE] = NLX_findSpikes(NSE,'CLUSTER',ClusterNr);
if isempty(NSE.Path);return;end
NSE = NLX_ExtractNSE(NSE,Index);
if savefile
    NSE = NLX_SaveNSE(NSE,0);
end