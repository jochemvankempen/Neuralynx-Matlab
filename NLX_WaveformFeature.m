function [F,Flim,Frange] = NLX_WaveformFeature(NSE,Feature,TimeStampIndex,WaveFormIndex,MapScaleMode,MapValMode)

% Extracts features of Waveform data.  
% F = NLX_WaveformFeature(NSE,Feature,TimeStampIndex,WaveFormIndex,MapScaleMode,MapValMode)
%
% NSE .............. NSE structure
% Feature .......... index or 'Time','Peak','Valley','Energy','Height'
% TimeStampIndex ... index
% WaveFormIndex .... index
% MapScaleMode ..... Scale to map to. Options:
%                    [] -> no mapping
%                    'SYSRANGE' -> scales to AD-range of system
%                    'POSSYSRANGE' -> scales to positive AD-range of system
%                    [low high] -> scales to a given range of values
% MapValMode ....... Values to map. Options: 
%                    [] or false -> maps range of current values
%                    true -> maps expected range of values
%                    [low high] -> maps a given range of values
%
% F ........ extracted feature values for each timestamp
% Flim ..... limit of feature values
% Frange ... theoretically expected limit of feature values


if nargin<6
    MapValMode = [];
    if nargin<5
        MapScaleMode = [];
    end;end;

%% get indices
[nWF,xxx,nTS] = size(NSE.SpikeWaveForm);
if nargin<3 || isempty(TimeStampIndex)
    TimeStampIndex = true(nTS,1);
end
if nargin<4 || isempty(WaveFormIndex)
    WaveFormIndex = true(nWF,1);
end

%% get the AD-range of the system
[SysRange,ADRange] = NLX_getADRangeNSE(NSE,TimeStampIndex);

%% extract features
if isnumeric(Feature)
    F = NSE.SpikeWaveForm(Feature,:,TimeStampIndex);
    Flim = [min(F(:)) max(F(:))];
    Frange = SysRange;%theoretical data limit
elseif ischar(Feature)
    switch Feature
        case 'Time'
            F = NSE.TimeStamps(TimeStampIndex);
            Flim = [min(F(:)) max(F(:))];
            Frange = Flim;%theoretical data limit
        case 'Peak'
            F = max(NSE.SpikeWaveForm(WaveFormIndex,:,TimeStampIndex),[],1);
            Flim = [min(F(:)) max(F(:))];
            Frange = SysRange;%theoretical data limit
        case 'Valley'
            F = min(NSE.SpikeWaveForm(WaveFormIndex,:,TimeStampIndex),[],1);
            Flim = [min(F(:)) max(F(:))];
            Frange = SysRange;%theoretical data limit
        case 'Energy'
            F = sum(NSE.SpikeWaveForm(WaveFormIndex,:,TimeStampIndex).^2,1);
            Flim = [min(F(:)) max(F(:))];
            Frange = [0 sum(WaveFormIndex).*(max(abs(SysRange)).^2)];%theoretical data limit
        case 'Height'
            F = max(NSE.SpikeWaveForm(WaveFormIndex,:,TimeStampIndex),[],1) - abs(min(NSE.SpikeWaveForm(WaveFormIndex,:,TimeStampIndex),[],1));
            Flim = [min(F(:)) max(F(:))];
            Frange = [0 diff(SysRange)];%theoretical data limit
        case {'PC' 'PC1' 'PC2' 'PC3'}
            [coefs,scores] = princomp(permute(NSE.SpikeWaveForm(WaveFormIndex,:,TimeStampIndex),[3 1 2]));
            F = scores(:,1:3);
            Flim = [min(F(:)) max(F(:))];Frange = Flim;
        otherwise
            error('Don''t know this waveform feature %s !!!',Feature);
    end
end
F = F(:);

%% map values
% Re-map feature values to a given scale.
% This applies to features like energy, where the outcoming feature
% values are on a different scale to the actual waveform values
if isempty(MapScaleMode)
    % no mapping
else
    if ischar(MapScaleMode)
        switch upper(MapScaleMode)
            case 'SYSRANGE'
                MapScale = SysRange;
            case 'POSSYSRANGE'
                MapScale = [0 1].*max(abs(SysRange));
            otherwise
                error('Don''t know what to scale to!!');
        end
    elseif isnumeric(MapScaleMode)
        MapScale = MapScaleMode;
    end
    
    if isempty(MapValMode) || (islogical(MapValMode) && ~MapValMode)
        MapValLim = Flim;
    elseif islogical(MapValMode) && MapValMode
        MapValLim = Frange;
    elseif isnumeric(MapValMode)
        MapValLim = MapValMode;
    end
    
    F = (F-(MapValLim(1)))./diff(MapValLim);% normalise F
    F(F<MapValLim(1)) = 0;% clip values
    F(F>MapValLim(2)) = 1;% clip values
    F = MapScale(1)+F.*diff(MapScale);% map to new range
end


