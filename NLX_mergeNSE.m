function NSE = NLX_mergeNSE(NSE,varargin)

% merge NSE structures
% NSE = NLX_mergeNSE(NSE1,NSE2, ...)
%
% keeps the path and header of the first structure
%
% NSE.Path ............ Full path of the original data file
% NSE.Header .......... Cellarray of strings [NumRows x 1], amplification
%                       parameter
% NSE.TimeStamps ...... [1 x NumSpikes] microseconds (10^-6s)
% NSE.ScNr ............ [1 x NumSpikes] Nr of Sc-Channel (Electrode)
% NSE.ClusterNr ....... [1 x NumSpikes] Nr of Cluster
% NSE.SpikeFeatures ... [8 x NumSpikes] Featurvalues for each spike
% NSE.SpikeWaveForm ... [32 x 1 x NumSpikes] 32 point sample of each spike

for i=1:length(varargin)
    NSE.TimeStamps = cat(1,NSE.TimeStamps,varargin{i}.TimeStamps);
    NSE.ScNr = cat(1,NSE.ScNr,varargin{i}.ScNr);
    NSE.ClusterNr = cat(1,NSE.ClusterNr,varargin{i}.ClusterNr);
    NSE.SpikeFeatures = cat(2,NSE.SpikeFeatures,varargin{i}.SpikeFeatures);
    NSE.SpikeWaveForm = cat(3,NSE.SpikeWaveForm,varargin{i}.SpikeWaveForm);
end

[NSE.TimeStamps, SortIndex] = sort(NSE.TimeStamps);
NSE.ScNr = NSE.ScNr(SortIndex);
NSE.ClusterNr = NSE.ClusterNr(SortIndex);
NSE.SpikeFeatures = NSE.SpikeFeatures(:,SortIndex);
NSE.SpikeWaveForm = NSE.SpikeWaveForm(:,:,SortIndex);

if any(diff(NSE.TimeStamps)==0)
    error('Found duplicate timestamps!');
end

