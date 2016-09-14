function m = NLX_WaveformMin(NSE,Index,SampleNr)
% Get the minimum of waveforms
% m = NLX_WaveformMin(NSE,i,SampleNr)
m = squeeze(min(NSE.SpikeWaveForm(:,:,Index),[],3));
if nargin>2 && ~isempty(m)
    m = m(SampleNr);
end