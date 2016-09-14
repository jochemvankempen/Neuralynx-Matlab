function [Index,NSE] = NLX_findSpikes(NSE,varargin)

% Finds spikes with given properties.
%
% NLX_findSpikes(NSE,Property1,Value1,Property2,Value2 ...)
% NSE ............. structure containing NSE data, loads file if empty
% Property/Value pairs
% 'WAVEFORM' ......  [n X 3] matrix, [sample nr , lower boundary , upper boundery]
%                    Boundaries are values between -2047 2047(-32768 32768)
%                    Max. in SpiikeSort Template Window (ncf cluster file)
% 'CLUSTER' ........ [n]
% 'TIME' ........... [lower upper] window, multiple windows in rows

if isempty(NSE)
	NSE = NLX_LoadNSE([],'FULL',1,[],1);
	if isempty(NSE.Path);return;end
end
[NumSpikes,FieldArray] = NLX_CheckNSE(NSE);

Index = true(NumSpikes,1);

for i = 1:2:length(varargin)
	switch upper(varargin{i})
		case 'WAVEFORM'
			for j = 1:size(varargin{i+1},1)
                Index = Index & permute(NSE.SpikeWaveForm(varargin{i+1}(j,1),:,:)>=varargin{i+1}(j,2) & NSE.SpikeWaveForm(varargin{i+1}(j,1),:,:)<=varargin{i+1}(j,3),[3,2,1]);
			end
		case 'CLUSTER'
			for j = 1:length(varargin{i+1})
				Index = Index & NSE.ClusterNr(:,1)==varargin{i+1}(j);
			end
		case 'TIME'
			for j = 1:size(varargin{i+1},1)
				Index = Index & NSE.TimeStamps(:,1)>=varargin{i+1}(j,1) & NSE.TimeStamps(:,1)<=varargin{i+1}(j,2);
			end
        otherwise
            error('Don''t know what to look for!');
	end
end
