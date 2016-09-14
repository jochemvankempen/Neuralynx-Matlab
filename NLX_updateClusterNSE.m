function NSE1 = NLX_updateClusterNSE(NSE1,NSE2,SaveMemoryFlag)

% updates spikes in NSE1 with spike information in NSE2


%% load NSE data
if nargin<1 | isempty(NSE1)
	NSE1 = NLX_LoadNSE([],'FULL',1,[]);
elseif ischar(NSE1)
	NSE1 = NLX_LoadNSE(NSE1,'FULL',1,[]);
end
if nargin<2 | isempty(NSE2)
	NSE2 = NLX_LoadNSE([],'FULL',1,[]);
elseif ischar(NSE2)
	NSE2 = NLX_LoadNSE(NSE2,'FULL',1,[]);
end

% % sort spikes
% NSE1 = NLX_sortNSE(NSE1);
% NSE2 = NLX_sortNSE(NSE2);

%% find spikes
if ~SaveMemoryFlag
    i = NSE2.TimeStamps>=NSE1.TimeStamps(1) & NSE2.TimeStamps<=NSE1.TimeStamps(end);
    
    if length(NSE1.TimeStamps)~=sum(i)
        error('Spike number mismatch');
    end
    if any(NSE2.TimeStamps(i)~=NSE1.TimeStamps)
        warning('Mismatch of spike timestamps');
        i(NSE2.TimeStamps(i)~=NSE1.TimeStamps) = false;
    end
    
    NSE1.TimeStamps = NSE2.TimeStamps(i);
    NSE1.ScNr = NSE2.ScNr(i);
    NSE1.ClusterNr = NSE2.ClusterNr(i);
    NSE1.SpikeFeatures = NSE2.SpikeFeatures(:,i);
    NSE1.SpikeWaveForm = NSE2.SpikeWaveForm(:,:,i);
else
    n = length(NSE1.TimeStamps);
    [dummy,i2] = ismember(NSE1.TimeStamps,NSE2.TimeStamps);
    for i=1:n
        NSE1.ScNr(i) = NSE2.ScNr(i2(i));
        NSE1.ClusterNr(i) = NSE2.ClusterNr(i2(i));
        NSE1.SpikeFeatures(:,i) = NSE2.SpikeFeatures(:,i2(i));
        NSE1.SpikeWaveForm(:,:,i) = NSE2.SpikeWaveForm(:,:,i2(i));
    end
end
        
        

% 
% % go through all the spikes
% hwait = waitbar(0,['check ' sprintf('%6.0f',nSpikes) ' spikes ...']);
% for i = 1:nSpikes
% 	cSpki = NSE2.TimeStamps==NSE1.TimeStamps(i);
% 	
% % 	if sum(cSpki)==0;error('Can''t find spike.');
% % 	elseif sum(cSpki)>1;error('Found more than one spike.');
% % 	elseif 	~all(NSE1.SpikeWaveForm(:,1,i)==NSE1.SpikeWaveForm(:,1,cSpki))
% % 		error('Spikes have different waveforms');
% % 	end
% 
% 	errorsum = zeros(1,3);
% 	if sum(cSpki)==0;errorsum(1) = errorsum(1)+1;
% 	elseif sum(cSpki)>1;errorsum(2) = errorsum(2)+1;
% 	elseif 	~all(NSE1.SpikeWaveForm(:,1,i)==NSE2.SpikeWaveForm(:,1,cSpki))
% 		errorsum(3) = errorsum(3)+1;
% 	else
% 		% no error, use all the spike times
% 		NSE1.ClusterNr(i) = NSE2.ClusterNr(cSpki);
% 	end
% 	
% 	waitbar(i/nSpikes,hwait);
% end
% close(hwait);
% 
% fprintf(1,'%7.0f total\n',nSpikes);
% fprintf(1,'%7.0f notfound\n',errorsum(1));
% fprintf(1,'%7.0f ambigous\n',errorsum(2));
% fprintf(1,'%7.0f wrong waveform\n',errorsum(3));
