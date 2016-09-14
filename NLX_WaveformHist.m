function NSE = NLX_WaveformHist(NSE,ClusterNr,SampleNr,Bins)

% Plots histogram of waveform values at given sample nr.

NumClust = length(ClusterNr);
NumSamp = length(SampleNr);
if isempty(NSE)
    NSE = NLX_LoadNSE([],'WAVEFORMS',1,[]);
end

if nargin<4
    Bins = [-2047:2047/15:0 2047/15:2047/15:2047];
end

figure('color','k');
for i=1:NumClust
    for j=1:NumSamp
        subplot(NumSamp,NumClust,(j-1)*NumClust+i)
        Index = NLX_findSpikes(NSE,'CLUSTER',ClusterNr(i));
        
        N = hist(permute(NSE.SpikeWaveForm(SampleNr(j),1,Index),[3 1 2]),Bins);
        h = bar(Bins,N);
        set(h,'edgecolor','none','facecolor',NLX_ClusterColor(i));
        set(gca,'color','k', ...
            'xlim',[Bins(1) Bins(end)],'xcolor',[.5 .5 .5], 'xtick',[-2000:100:2000], ...
            'ycolor',[.5 .5 .5])
    end
end
