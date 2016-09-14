function NLX_PlotClusterDrift(NSE,ClusterNr,SampleNr,Ylim,PlotMedFlag)

% Checks for a drift in cluster parameter over time.
% plots medians of waveform values and frequency against time
%
% NSE ... structure (see NLX_loadNSE.m)
% NLX_PlotClusterDrift(ClusterNr,SampleNr)
%
% ClusterNr ..... cluster number
% SampleNr ... number of waveform (n=32) sample

if isempty(NSE)
    NSE = NLX_LoadNSE([],'WAVEFORMS',1,[]);
end
NumClust = length(ClusterNr);
NumSamp = length(SampleNr);
NSE = NLX_sortNSE(NSE);

MedianBinWin = 30;
TimeTicks = 60*10^6;

if isempty(Ylim)
    SampleRange = [-2047 2047];
else
    SampleRange = Ylim;
end
% SampleRange = [0 3500];
% SampleRange = [0 3000];

figure('color','k','name','temporal drift','numbertitle','off')
for i = 1:NumClust
    for j = 1:NumSamp
        
        if ~any(NSE.ClusterNr==ClusterNr(i));continue;end
        
        subplot(NumClust,NumSamp,(i-1)*NumSamp+j);
        
        currTS = NSE.TimeStamps(NSE.ClusterNr==ClusterNr(i));
        currSA = permute(NSE.SpikeWaveForm(SampleNr(j),1,(NSE.ClusterNr==ClusterNr(i))),[1 3 2]);
        currMax = max(currSA);
        currMin = min(currSA);

        
         set(gca,'color','k','box','on','layer','bottom', ...
            'xcolor',[.5 .5 .5],'xlim',[min(NSE.TimeStamps) max(NSE.TimeStamps)],'xtick',[min(NSE.TimeStamps):TimeTicks:max(NSE.TimeStamps)],'xgrid','on', ...
            'ycolor',[.5 .5 .5],'ylim',SampleRange);
       
        % median sample value ------------------------------
        currMed = []; 
        currMed = cat(1,currMed,[min(currTS):MedianBinWin*1000000:max(currTS)]');
        currNumMed = size(currMed,1);
        for m = 1:currNumMed-1
            currMedSpikes = (currTS>=currMed(m,1) & currTS<currMed(m+1,1));
            if any(currMedSpikes)
                currMed(m,2) = median(currSA(currMedSpikes));
            else
                currMed(m,2) = NaN;
            end
        end
        currMed(:,1) = currMed(:,1) + MedianBinWin*1000000*0.5;
        currMed(end,:) = [];
        
        % plot -----------------------------------------------
        line(currTS,currSA, ...
            'linestyle','none', ...
            'marker','o', ...
            'markeredgecolor','none', ...
            'markerfacecolor',NLX_ClusterColor(ClusterNr(i)), ...
            'markersize',1, ...
            'clipping','off');
        if PlotMedFlag
            line(currMed(:,1),currMed(:,2), ...
                'linestyle','-', ...
                'linewidth',2, ...
                'marker','none', ...
                'color',NLX_ClusterColor(ClusterNr(i)));
        end
        
        
    end
end

figure('color','k','name','mean pulse/sec','numbertitle','off')
for i = 1:NumClust
    subplot(NumClust,1,i);
    
    if ~any(NSE.ClusterNr==ClusterNr(i));continue;end
    currTS = NSE.TimeStamps(NSE.ClusterNr==ClusterNr(i));
    currFreq = []; 
    currFreq = cat(1,currFreq,[min(currTS):MedianBinWin*1000000:max(currTS)]');
    currNumFreq = size(currFreq,1);
    for m = 1:currNumFreq-1
        currMedSpikes = (currTS>=currFreq(m,1) & currTS<currFreq(m+1,1));
        if any(currMedSpikes)
            currFreq(m,2) = sum(currMedSpikes)/MedianBinWin;
        else
            currFreq(m,2) = NaN;
        end
    end
    currFreq(:,1) = currFreq(:,1) + MedianBinWin*1000000*0.5;
    currFreq(end,:) = [];

    
    line(currFreq(:,1),currFreq(:,2), ...
        'linestyle','-', ...
        'linewidth',3, ...
        'marker','none', ...
        'color',NLX_ClusterColor(ClusterNr(i)), ...
        'clipping','off');
    set(gca,'color','k','box','on', ...
        'xcolor',[.5 .5 .5],'xlim',[min(NSE.TimeStamps) max(NSE.TimeStamps)],'xtick',[min(NSE.TimeStamps):TimeTicks:max(NSE.TimeStamps)], ...
        'ycolor',[.5 .5 .5],'ylim',[0 max(currFreq(:,2))]);
    
end        

return;
