function NSE = NLX_setSpikeVariableThreshold(NSE,ClusterNr,NewThresh,ReposClustNr)

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
%
% adapted from NLX_setSpikeThreshold.m
% NewThresh is a vector with the same size as NSE.TimeStamps. Thus, every
% spike has its own threshold. This allows a different threshold over the
% course of the experiment.

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
    
    if WaveMin<=min(NewThresh) && isempty(ReposClustNr)
        % delete spikes
        i = NLX_findSpikesMat(NSE,'CLUSTER',ClusterNr,'WAVEFORM',[repmat(WaveAlign,length(NewThresh),1)  repmat(ADRange(1),length(NewThresh),1) NewThresh-1]);
        NSE = NLX_DeleteNSE(NSE,i);
    
    elseif WaveMin<=min(NewThresh) && ~isempty(ReposClustNr)
        % put spikes to repository cluster
        i = NLX_findSpikesMat(NSE,'CLUSTER',ClusterNr,'WAVEFORM',[repmat(WaveAlign,length(NewThresh),1)  repmat(ADRange(1),length(NewThresh),1) NewThresh-1]);
        NSE.ClusterNr(i) = ReposClustNr;
    
    elseif WaveMin>min(NewThresh) && isempty(ReposClustNr)
        % no way to add spikes
        fprintf('New threshold too low!\n');
    
    elseif WaveMin>min(NewThresh) && ~isempty(ReposClustNr)
        % get spikes back from repository cluster
        i = NLX_findSpikesMat(NSE,'CLUSTER',ReposClustNr,'WAVEFORM',[repmat(WaveAlign,length(NewThresh),1) NewThresh repmat(ADRange(2),length(NewThresh),1)]);
        NSE.ClusterNr(i) = ClusterNr;
        
    else
        error('There should be no other alternative here!');
    end
    
else

    % negative threshold
    
    if WaveMax>=min(NewThresh) && isempty(ReposClustNr)
        % delete spikes
        i = NLX_findSpikesMat(NSE,'CLUSTER',ClusterNr,'WAVEFORM',[repmat(WaveAlign,length(NewThresh),1)  NewThresh+1 repmat(ADRange(2),length(NewThresh),1)]);
        NSE = NLX_DeleteNSE(NSE,i);
        
    elseif WaveMax>=min(NewThresh) && ~isempty(ReposClustNr)
        % put spikes to repository cluster
        i = NLX_findSpikesMat(NSE,'CLUSTER',ClusterNr,'WAVEFORM',[repmat(WaveAlign,length(NewThresh),1)  NewThresh+1 repmat(ADRange(2),length(NewThresh),1)]);
        NSE.ClusterNr(i) = ReposClustNr;
        
    elseif WaveMax<min(NewThresh) && isempty(ReposClustNr)
        % no way to add spikes
        fprintf('New threshold too low!\n');
        
    elseif WaveMax<min(NewThresh) && ~isempty(ReposClustNr)
        % get spikes back from repository cluster
        i = NLX_findSpikesMat(NSE,'CLUSTER',ReposClustNr,'WAVEFORM',[repmat(WaveAlign, length(NewThresh),1)  repmat(ADRange(1),length(NewThresh),1)]); 
        NSE.ClusterNr(i) = ClusterNr;
        
    else
        error('There should be no other alternative here!');
    end

    
end


