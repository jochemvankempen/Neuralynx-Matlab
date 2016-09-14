function NSE = NLX_setSpikeThreshold(NSE,ClusterNr,NewThresh,ReposClustNr)

% Set spike detection threshold.
% Detects negative/positve thresholding, repository cluster is used to add
% spikes to meet threshold criterion.
% 
% NSE = NLX_setSpikeThreshold(NSE,ClusterNr,NewThresh,ReposClustNr)
%
% NSE ................. structure, see NLX_loadNSE.m
% ClusterNr ........... select NSE.ClusterNr
% NewThresh ........... Boundaries are values between
% ReposClustNr ........

if nargin<4
    ReposClustNr = [];
end

%% get general settings
WaveAlign = NLX_getWaveAlign(NSE);
ADRange = NLX_getADRangeNSE(NSE);

%% get max and min of waveforms
iCluster = NLX_findSpikes(NSE,'CLUSTER',ClusterNr);
WaveMax = NLX_WaveformMax(NSE,iCluster,WaveAlign);
WaveMin = NLX_WaveformMin(NSE,iCluster,WaveAlign);
if ~isempty(ReposClustNr)
    iCluster = NLX_findSpikes(NSE,'CLUSTER',ReposClustNr);
    if any(iCluster)
        ReposWaveMax = NLX_WaveformMax(NSE,iCluster,WaveAlign);
        ReposWaveMin = NLX_WaveformMin(NSE,iCluster,WaveAlign);
    else
        ReposWaveMax = [];
        ReposWaveMin = [];
    end
else
    ReposWaveMax = [];
    ReposWaveMin = [];
end

%% check the threshold mode
if abs(WaveMax)<abs(WaveMin)
    NegThresFlag = true;
else
    NegThresFlag = false;
end

%%
if ~NegThresFlag
    
    % positive threshold
    
    if WaveMin<=NewThresh && isempty(ReposClustNr)
        % delete spikes
        i = NLX_findSpikes(NSE,'CLUSTER',ClusterNr,'WAVEFORM',[WaveAlign  ADRange(1) NewThresh-1]);
        NSE = NLX_DeleteNSE(NSE,i);
    
    elseif WaveMin<=NewThresh && ~isempty(ReposClustNr)
        % put spikes to repository cluster
        i = NLX_findSpikes(NSE,'CLUSTER',ClusterNr,'WAVEFORM',[WaveAlign  ADRange(1) NewThresh-1]);
        NSE.ClusterNr(i) = ReposClustNr;
    
    elseif WaveMin>NewThresh && isempty(ReposClustNr)
        % no way to add spikes
        fprintf('New threshold too low!\n');
    
    elseif WaveMin>NewThresh && ~isempty(ReposClustNr)
        % get spikes back from repository cluster
        i = NLX_findSpikes(NSE,'CLUSTER',ReposClustNr,'WAVEFORM',[WaveAlign  NewThresh ADRange(2)]);
        NSE.ClusterNr(i) = ClusterNr;
        
    else
        error('There should be no other alternative here!');
    end
    
else

    % negative threshold
    
    if WaveMax>=NewThresh && isempty(ReposClustNr)
        % delete spikes
        i = NLX_findSpikes(NSE,'CLUSTER',ClusterNr,'WAVEFORM',[WaveAlign  NewThresh+1 ADRange(2)]);
        NSE = NLX_DeleteNSE(NSE,i);
        
    elseif WaveMax>=NewThresh && ~isempty(ReposClustNr)
        % put spikes to repository cluster
        i = NLX_findSpikes(NSE,'CLUSTER',ClusterNr,'WAVEFORM',[WaveAlign  NewThresh+1 ADRange(2)]);
        NSE.ClusterNr(i) = ReposClustNr;
        
    elseif WaveMax<NewThresh && isempty(ReposClustNr)
        % no way to add spikes
        fprintf('New threshold too low!\n');
        
    elseif WaveMax<NewThresh && ~isempty(ReposClustNr)
        % get spikes back from repository cluster
        i = NLX_findSpikes(NSE,'CLUSTER',ReposClustNr,'WAVEFORM',[WaveAlign  ADRange(1) NewThresh]);
        NSE.ClusterNr(i) = ClusterNr;
        
    else
        error('There should be no other alternative here!');
    end

    
end


