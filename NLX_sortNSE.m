function NSE = NLX_sortNSE(NSE)

% Remove duplicate TimeStamps and sorts Timestamps

% sort data
[NSE.TimeStamps,SortIndex] = sort(NSE.TimeStamps);
if ~isempty(NSE.ScNr);NSE.ScNr = NSE.ScNr(SortIndex);end;
if ~isempty(NSE.ClusterNr);NSE.ClusterNr = NSE.ClusterNr(SortIndex);end;
if ~isempty(NSE.SpikeFeatures);NSE.SpikeFeatures = NSE.SpikeFeatures(:,SortIndex);end;
if ~isempty(NSE.SpikeWaveForm);NSE.SpikeWaveForm = NSE.SpikeWaveForm(:,:,SortIndex);end;

% search for duplicate timestamps
DupliSpikes = find(diff(NSE.TimeStamps)==0);

% delete the second of duplicate spikes
if ~isempty(DupliSpikes)
    NSE = NLX_DeleteNSE(NSE,DupliSpikes+1);
    disp(['Deleted ' num2str(length(DupliSpikes)) ' duplicate spikes']); 
end