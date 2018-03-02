function [NSE,i] = NLX_Freq2Threshold(NSE,ClusterNr,FreqBounds,TimeWin,ReposClustNr,LogFileID)

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
ReposDeleteFlag = false;

WaveAlign = NLX_getWaveAlign(NSE);

if nargin<6
    LogFileID = 1;
end

if nargin<4 || isempty(TimeWin)
    TimeWin = [min(NSE.TimeStamps)-1 max(NSE.TimeStamps)+1];
end

%% get current parameter
iCluster = NLX_findSpikes(NSE,'CLUSTER',ClusterNr);
WaveMax = NLX_WaveformMax(NSE,iCluster,WaveAlign);
WaveMin = NLX_WaveformMin(NSE,iCluster,WaveAlign);
WaveRange = [WaveMin WaveMax];
cSpikeCount = NLX_CountSpikes(NSE,TimeWin,ClusterNr);
cSpikeCount = sum(cSpikeCount);
dt = sum(diff(TimeWin,[],2),1);
cSpikeRate = cSpikeCount/(dt*1e-6);
Step = 0.5*abs(diff([WaveMax WaveMin]));
lastStepDir = NaN;
currStepDir = NaN;
iDecr = 1;    

%% check threshold mode
if abs(WaveMax)<abs(WaveMin)
    NegThresFlag = true;
else
    NegThresFlag = false;
end

%% do "staircase"
i = 0;
fprintf(LogFileID,'%1.0f %1.2f Hz %1.0f to %1.0f\n',i,cSpikeRate,WaveMin,WaveMax);
while cSpikeRate > FreqBounds(2) || cSpikeRate < FreqBounds(1)
    
    % change threshold
    if cSpikeRate > FreqBounds(2)
        currStepDir = -1;
        i = i+1;
        if ~NegThresFlag
            NewThresholdValue = WaveMin+Step;
            
        else
            NewThresholdValue = WaveMax-Step;
        end
    elseif i>0 && (cSpikeRate < FreqBounds(1))
        currStepDir = +1;
        i = i+1;
        if ~NegThresFlag
            NewThresholdValue = WaveMin-Step;
        else
            NewThresholdValue = WaveMax+Step;
        end
    else
        break;
    end
    
    NSE = NLX_setSpikeThreshold(NSE,ClusterNr,NewThresholdValue,ReposClustNr);
    
    % update values
    iCluster = NLX_findSpikes(NSE,'CLUSTER',ClusterNr);
    WaveMax = NLX_WaveformMax(NSE,iCluster,WaveAlign);
    WaveMin = NLX_WaveformMin(NSE,iCluster,WaveAlign);
    cSpikeCount = NLX_CountSpikes(NSE,TimeWin,ClusterNr);
    cSpikeCount = sum(cSpikeCount);
    dt = sum(diff(TimeWin,[],2),1);
    cSpikeRate = cSpikeCount/(dt*1e-6);
    
    % change stepsize
    if (cSpikeRate > FreqBounds(2) && lastStepDir == -1) || (cSpikeRate < FreqBounds(1) && lastStepDir == 1)
        iDecr = iDecr+1;
        Step = Step .* (log(2)./log(iDecr+1));
        StepHistory(iDecr) = Step;
    end
    lastStepDir = currStepDir;
    currStepDir = NaN;
    
    fprintf(LogFileID,'%1.0f %1.2f Hz %1.0f to %1.0f Step:%1.1f\n',i,cSpikeRate,WaveMin,WaveMax,Step);
    
    if Step < 1
        % implemented an extra cycle with different step sizes, to prevent
        % non-convergence to a spike threshold and getting stuck in the
        % while loop with stepsize 0. Jochem van Kempen 01/03/2018
        Step = mean(StepHistory(2:3));
        i = 1;
        iDecr = 1;
    end

end


%% delete repository
if ReposDeleteFlag
    ClusterNr = NLX_findSpikes(NSE,'CLUSTER',ReposClustNr);
    NSE = NLX_DeleteNSE(NSE,ClusterNr);
end
