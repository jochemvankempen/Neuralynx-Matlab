function [index,spikes] = NLX_NSE2WaveClus(NSE,sampleindex,savedir)

% converts a nse file to the ascii(*.mat) format that is used by Wave_clus
%

if nargin<2 | isempty(sampleindex)
    sampleindex = [1:32];
end

% check input format
if ischar(NSE)
    NSE = NLX_LoadNSE(NSE,'WAVEFORMS',1,[]);
elseif isstruct(NSE)
end

[fdir,fname,fext] = fileparts(NSE.Path);
if nargin<3 | isempty(savedir)
    savedir = fdir;
end

index = NSE.TimeStamps.*0.001;
spikes = permute(NSE.SpikeWaveForm(sampleindex,:,:),[3,1,2]);
data = NaN;

save(fullfile(savedir,[fname '.mat']),'-mat','-V6','data','index','spikes');