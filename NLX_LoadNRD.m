function NRD = NLX_LoadNRD(NRDpath,ChannelNumber,FieldOption,ExtractMode,ExtractArray)

% Loads a *.ncs file into a matlab structure
%
% NCS = NLX_LoadNCS(NCSpath,FieldOption,ExtractMode,ExtractArray)
%
% INPUT:
% NCSpath ... full filepath, windows gui popup if empty
% FieldOption .... 'HEADER' - Only header
%                  'FULL' - Loads the full file dataset
% ExtractMode .... 1 Extract All [] 
%                  2 Extract Record Index Range [1stRec-1 lastRec-1]
%                  3 Extract Record Index List [RecNr-1 ...] 
%                  4 Extract Timestamp Range [StartStamp EndStamp] 
%                  5 Extract Timestamp List [StampVal1 StampVal2 ...]
% ExtractArray ... Mode 1  [] 
%                  Mode 2  [1stRec-1 lastRec-1]
%                  Mode 3  [RecNr-1 ...] 
%                  Mode 4  [StartStamp EndStamp] 
%                  Mode 5  [StampVal1 StampVal2 ...]
%
% OUTPUT:
% NCS.Path ............ Full path of the original data file
% NCS.Header .......... Cellarray of strings [NumRows x 1], amplification
%                       parameter
% NCS.TimeStamps ....... [1 x NumSamples] microseconds (10^-6s)
% NCS.Samples .......... [(512) x NumSamples] 

NRD.Path = '';
NRD.Header = [];
NRD.TimeStamps = [];
NRD.Samples = [];
NRD.ChNr = ChannelNumber;

ExtractHeader = 1;

% check input
if nargin < 1 | isempty(NRDpath)
	[filename,pathname] = uigetfile('*.nrd','load Neuralynx *.NRD raw-data file');
	NRDpath = fullfile(pathname,filename);
	if ~filename;return;end
end
NRD.Path = NRDpath;
if nargin<3 | isempty(FieldOption);FieldOption = 'HEADER';end
if nargin<4 | isempty(ExtractMode);ExtractMode = 1;ExtractArray=[];end

% get estimate for reading time
% 1 Byte = 8 Bit
% 1 Kilobyte = 1024 Bytes
% 1 Megabyte = 1048576 Bytes
% 1 Gigabyte = 1073741824 Bytes
[Hd,FileBytes] = NLX_readHeader(NRDpath);
cHead = NLX_Head2Struct(Hd);
SecPerByte = 5.0e-9;
numExtras = 10;
numChan = cHead.NumChannels;
numPacket = 7 + numExtras + numChan + 1;
PackageSizeInBytes = numPacket*32/8;
NumPackageTotal = floor(FileBytes/PackageSizeInBytes);
dt = 1e6/cHead.SamplingFrequency;
EstLastTime = NumPackageTotal*dt;
fprintf(1,'Raw data filesize: %u bytes (%1.2fGb) -> %4.0f min %2.3f sec\n',FileBytes,FileBytes/1073741824,floor(EstLastTime*1e-6/60),rem(EstLastTime*1e-6,60));
fprintf(1,'reading ETA -> %4.0f min %2.3f sec\n',floor(FileBytes*SecPerByte/60),rem(FileBytes*SecPerByte,60));
if ExtractMode==4
    dt = max(ExtractArray)-min(ExtractArray);
    fprintf(1,'data window -> %4.0f min %2.3f sec\n',floor(dt*1e-6/60),rem(dt*1e-6,60));
end
    

tic;
% check options
switch upper(FieldOption)
	case 'HEADER' ;
        ChannelNumber = 0;
        FieldArray = [0 0];
        ExtractHeader = 1;
        ExtractMode = 3;
        ExtractArray = 1;
        [NRD.Header] = Nlx2MatNRD(NRDpath,ChannelNumber,FieldArray,ExtractHeader,ExtractMode,ExtractArray);
	case 'FULL' ;
        FieldArray = [1 1];[NRD.TimeStamps,NRD.Samples,NRD.Header] = Nlx2MatNRD(NRDpath,ChannelNumber,FieldArray,ExtractHeader,ExtractMode,ExtractArray);
    otherwise
        error('Don''t know option!!');
		%FieldArray = [0 0];[NRD.Header] = Nlx2MatNRD(NRDpath,ChannelNumber,FieldArray,ExtractHeader,1,ExtractArray);
end
t = toc;
fprintf(1,'            => %4.0f min %2.3f sec\n',floor(t/60),rem(t,60))

NRD.TimeStamps = NRD.TimeStamps(:);
NRD.Samples = NRD.Samples(:);

