function [c,ClusterNr] = NLX_CountSpikes(NSE,TimeWin,ClusterNr)

% Counts spikes in a given time window.
% [c,ClusterNr] = NLX_CountSpikes(NSE,TimeWin,ClusterNr)
% TimeWin ..... [n x 2]
% ClusterNr ... select NSE.ClusterNr
% c ........... [nTimeWin x nCluster]

%% get time window
if nargin<2 || isempty(TimeWin)
    TimeWin = [min(NSE.TimeStamps) max(NSE.TimeStamps)];
end
nTW = size(TimeWin,1);

%% get clusters
if nargin<3 || isempty(ClusterNr)
    ClusterNr = unique(NSE.ClusterNr);
end
nClusters = length(ClusterNr);

%% loop TimeWin and Clusters

% allocate arrays
isTW = false(size(NSE.TimeStamps));
isCl = false(size(NSE.TimeStamps));
c = zeros(nTW,nClusters);

hwait = waitbar(0,'count spikes');
for iC = 1:nClusters
    isCl = NSE.ClusterNr==ClusterNr(iC);
    for iTW=1:nTW
        isTW = NSE.TimeStamps>=TimeWin(iTW,1) & NSE.TimeStamps<=TimeWin(iTW,2);
        c(iTW,iC) = sum(isTW&isCl);
        waitbar(((iTW-1)*nClusters+iC)/(nTW*nClusters),hwait);
    end
end
close(hwait);
    