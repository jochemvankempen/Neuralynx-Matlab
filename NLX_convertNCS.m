function NCS = NLX_convertNCS(NCS,ADGain,AmpGain)

% Convert the raw *.ncs data to analog microV
% If ADGain and/or AmpGain are left empty, the values in the header will be
% used for conversion. The maximum ADbit Value is read from the header.
% INPUT
% NCS ........ structure, see NLX_loadNCS
% ADGain .....
% AmpGain ....
% OUTPUT
% NCS ........ NCS structure containing data in time window

ADVoltRange = 10; % in mV
% check conversion parameter
H = NLX_Head2Struct(NCS.Header);
if nargin<4 | isempty(AmpGain);AmpGain = H.AmpGain;end
if nargin<3 | isempty(ADGain);ADGain = H.ADGain;end
ADMaxValue = H.ADMaxValue;
ADBitVolts = (ADVoltRange/ADMaxValue) .* (1/ADGain) .* (1/AmpGain);
disp(['ADGain: ' num2str(ADGain) ' AmpGain: ' num2str(AmpGain) ' ADBitVolts: ' num2str(ADBitVolts) ' ADMaxValue: ' num2str(ADMaxValue)]);

if length(unique(NCS.ValidSampleNum))>1;warning('ValidSampleNum are inconsistent!');end
if length(unique(NCS.SF))>1;warning('Sample Frequencies are inconsistent!');end

% conversion to micro volts
NCS.Samples = NCS.Samples .* ADBitVolts .* (10^6);
