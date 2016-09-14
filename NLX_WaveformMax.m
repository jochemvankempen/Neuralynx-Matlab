function m = NLX_WaveformMax(NSE,Index,SampleNr)
% Get the maximum of waveforms
% m = NLX_WaveformMax(NSE,i,SampleNr)
m = squeeze(max(NSE.SpikeWaveForm(:,:,Index),[],3));
if nargin>2 && ~isempty(m)
    m = m(SampleNr);
end