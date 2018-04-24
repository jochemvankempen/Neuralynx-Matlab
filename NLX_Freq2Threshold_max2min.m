function [NSE,i, NewThresholdValue] = NLX_Freq2Threshold_max2min(NSE,ClusterNr,FreqBounds,TimeWin,ReposClustNr,LogFileID)

% Adjust a spike threshold to a set frequency in a defined window.
% Rejected spikes are indicated by ReposClustNr, accepted spikes by ClusterNr
%
% NSE = NLX_Freq2Threshold(NSE,ClusterNr,FreqBounds,TimeWin)
%
% ClusterNr .... select NSE.ClusterNr
% FreqBounds ... [1 x 2] desired firing frequency bounds [Hz]
% TimeWin ...... [n x 2] Time windows to count spikes in, in Neuralynx time [microsec]

% ReposClustNr = max(NSE.ClusterNr)+1;
% ReposClustNr = 9;
%
% Adjustment of NLX_Freq2Threshold.m
% Here, rather than using staircase procedure, we use a maximum threshold
% and then progressively lower it until the desired spike rate is reached.
%
% Jochem van Kempen, 11-04-2018

ReposDeleteFlag = false;

WaveAlign = NLX_getWaveAlign(NSE);

if nargin<6
    LogFileID = 1;
end

if nargin<4 || isempty(TimeWin)
    TimeWin = [min(NSE.TimeStamps)-1 max(NSE.TimeStamps)+1];
end

%% get current parameter
iCluster    = NLX_findSpikes(NSE,'CLUSTER',ClusterNr);
WaveMax     = NLX_WaveformMax(NSE,iCluster,WaveAlign);
WaveMin     = NLX_WaveformMin(NSE,iCluster,WaveAlign);
WaveRange   = [WaveMin WaveMax];
cSpikeCount = NLX_CountSpikes(NSE,TimeWin,ClusterNr);
cSpikeCount = sum(cSpikeCount);
dt          = sum(diff(TimeWin,[],2),1);
cSpikeRate  = cSpikeCount/(dt*1e-6);
Step        = 0.025*abs(diff([WaveMax WaveMin])); % take a much smaller step than in original script
lastStepDir = NaN;
currStepDir = NaN;

convergenceError = 0;
iDecr = 1; iDecr2 = 1;    

stepSizeMin = 1;

%% check threshold mode
if abs(WaveMax)<abs(WaveMin)
    NegThresFlag = true;
else
    NegThresFlag = false;
end

%% set high threshold, and progressively lower it to reach the desired firing rate
i = 0;
fprintf(LogFileID,'%1.0f %1.2f Hz %1.0f to %1.0f\n',i,cSpikeRate,WaveMin,WaveMax);
orig_waveMin = WaveMin;
orig_waveMax = WaveMax;

if cSpikeRate >= FreqBounds(1) && cSpikeRate <= FreqBounds(2)
    NewThresholdValue = WaveMin;
    i = 1;
elseif cSpikeRate < FreqBounds(1)
    warning(['spikerate (' num2str(cSpikeRate) ') is too low!!'])
    NewThresholdValue = WaveMin;
end

directionchange = false;
while cSpikeRate > FreqBounds(2) || cSpikeRate < FreqBounds(1)
    
    if i == 0 && cSpikeRate > FreqBounds(2)
        % first iteration. Set threshold close to wavemin or wavemax
        if ~NegThresFlag
            NewThresholdValue = WaveMin+Step;
        else
            NewThresholdValue = WaveMax-Step;
        end
        OldThresholdValue = NewThresholdValue;
    elseif i > 0 && cSpikeRate > FreqBounds(2) && Step > stepSizeMin && ~directionchange
        % If the direction did not change (the spikerate
        % was higher than FreqBounds(2) on the previous iteration) subtract
        % the same stepsize from the threshold and run again
        OldThresholdValue = NewThresholdValue;
        if ~NegThresFlag
            NewThresholdValue = NewThresholdValue + Step;
        else
            NewThresholdValue = NewThresholdValue - Step;
        end
    elseif i > 0 && cSpikeRate > FreqBounds(2) && Step > stepSizeMin && directionchange
        % If the direction did change (the spikerate
        % was lower than FreqBounds(1) on the previous iteration) subtract
        % the decreased stepsize from the threshold and run again
        OldThresholdValue = NewThresholdValue;
        Step = Step /2;
        if ~NegThresFlag
            NewThresholdValue = NewThresholdValue + Step;
        else
            NewThresholdValue = NewThresholdValue - Step;
        end
        directionchange = false;
    elseif i>0 && cSpikeRate < FreqBounds(1) && Step > stepSizeMin
        % If the spikerate is lower than FreqBounds(1), subtract
        % the decreased stepsize from the old threshold threshold and run again
        directionchange = true;
        NewThresholdValue = OldThresholdValue;        
        Step = Step /2;
        if ~NegThresFlag
            NewThresholdValue = NewThresholdValue + Step;
        else
            NewThresholdValue = NewThresholdValue - Step;
        end
    elseif Step < stepSizeMin
        % implemented an extra cycle with different step sizes, to prevent
        % non-convergence to a spike threshold and getting stuck in the
        % while loop with stepsize 0. 
        convergenceError = convergenceError+1;
        
        Step = 0.005 / convergenceError * abs(diff([orig_waveMax orig_waveMin])); % take a much smaller step than in original cycle
        if ~NegThresFlag
            NewThresholdValue = orig_waveMin+Step;
        else
            NewThresholdValue = orig_waveMax-Step;
        end
        
        if convergenceError>1
            stepSizeMin = stepSizeMin/convergenceError;
        end
    else
        break;
    end
    i = i+1;
        
    NSE = NLX_setSpikeThreshold(NSE,ClusterNr,NewThresholdValue,ReposClustNr);
    
    % update values
    iCluster    = NLX_findSpikes(NSE,'CLUSTER',ClusterNr);
    WaveMax     = NLX_WaveformMax(NSE,iCluster,WaveAlign);
    WaveMin     = NLX_WaveformMin(NSE,iCluster,WaveAlign);
    cSpikeCount = NLX_CountSpikes(NSE,TimeWin,ClusterNr);
    cSpikeCount = sum(cSpikeCount);
    dt = sum(diff(TimeWin,[],2),1);
    cSpikeRate = cSpikeCount/(dt*1e-6);
        
    fprintf(LogFileID,'%1.0f %1.2f Hz %1.0f to %1.0f Threshold %1.0f Step:%1.1f\n',i,cSpikeRate,WaveMin,WaveMax,NewThresholdValue, Step);
    
end


%% delete repository
if ReposDeleteFlag
    ClusterNr = NLX_findSpikes(NSE,'CLUSTER',ReposClustNr);
    NSE = NLX_DeleteNSE(NSE,ClusterNr);
end
