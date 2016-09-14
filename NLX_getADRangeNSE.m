function [SysRange,ADRange,WaveRange] = NLX_getADRangeNSE(NLX,SpikeIndex,SysMode)

% get the AD-range of the current setup
% [SysRange,ADRange,WaveRange] = NLX_getADRangeNSE(NLX,SpikeIndex)
%
% 

if nargin<3
    SysMode = '';
end

[nWaveSamples,ShouldBeOne,nTS] = size(NLX.SpikeWaveForm);

if nargin<2 || isempty(SpikeIndex)
    maxR = max(NLX.SpikeWaveForm(:,:,:),[],3);
    minR = min(NLX.SpikeWaveForm(:,:,:),[],3);
else
    maxR = max(NLX.SpikeWaveForm(:,:,SpikeIndex),[],3);
    minR = min(NLX.SpikeWaveForm(:,:,SpikeIndex),[],3);
end

WaveRange(:,1) = minR;
WaveRange(:,2) = maxR;

ADRange(1,1) = min(minR);
ADRange(1,2) = max(maxR);

if isempty(SysMode) && any(abs(NLX.SpikeWaveForm(:))>2048)
    SysMode = 'Digital';
else
    SysMode = 'Analog';
end

switch SysMode
    case 'Analog'
        SysRange = [-2048 2048];% analog Cheetah
    case 'Digital'
        SysRange = [-32768 32768];% digital LYNX
end

