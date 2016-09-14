function [NCS, DelayCompensation] = NLX_LoadNCS(NCSpath,FieldOption,ExtractMode,ExtractArray)

% Loads a *.ncs file into a matlab structure
%
% NCS = NLX_LoadNCS(NCSpath,FieldOption,ExtractMode,ExtractArray)
%
% INPUT:
% NCSpath ... full filepath, windows gui popup if empty
% FieldOption .... 'HEADER'    - Only header
%                  'FULL'      - Loads the full file dataset
%                  'NOSAMPLES' - everything apart from samples
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
% NCS.ChNr ............. [1 x NumSamples] 
% NCS.SF ............... [1 x NumSamples] Sample frequency for every
%                                         NCS.Samples column
% NCS.ValidSampleNum ... [1 x NumSamples] valid samples in every NCS.Samples column
% NCS.Samples .......... [(512) x NumSamples] 

NCS.Path = '';
NCS.Header = [];
NCS.TimeStamps = [];
NCS.ChNr = [];
NCS.SF = [];
NCS.ValidSampleNum = [];
NCS.Samples = [];

ExtractHeader = 1;

% check input
if nargin < 1 | isempty(NCSpath)
	[filename,pathname] = uigetfile('*.ncs','load Neuralynx *.NCS data file');
	NCSpath = fullfile(pathname,filename);
	if ~filename;return;end
end
NCS.Path = NCSpath;
if nargin<2 | isempty(FieldOption);FieldOption = 'HEADER';end
if nargin<3 | isempty(ExtractMode);ExtractMode = 1;ExtractArray=[];end
if nargin<5 | isempty(EchoOff);EchoOff = 0;end

% check options
switch upper(FieldOption)
	case 'HEADER' ;
        FieldArray = [0 0 0 0 0];[NCS.Header] = Nlx2MatCSC(NCSpath,FieldArray,ExtractHeader,ExtractMode,ExtractArray);
	case 'FULL' ;
        FieldArray = [1 1 1 1 1];[NCS.TimeStamps,NCS.ChNr,NCS.SF,NCS.ValidSampleNum,NCS.Samples,NCS.Header] = Nlx2MatCSC(NCSpath,FieldArray,ExtractHeader,ExtractMode,ExtractArray);
	case 'NOSAMPLES' ;
        FieldArray = [1 1 1 1 0];[NCS.TimeStamps,NCS.ChNr,NCS.SF,NCS.ValidSampleNum,NCS.Header] = Nlx2MatCSC(NCSpath,FieldArray,ExtractHeader,ExtractMode,ExtractArray);
	otherwise
		FieldArray = [0 0 0 0 0];[NCS.Header] = Nlx2MatCSC(NCSpath,FieldArray,ExtractHeader,1,ExtractArray);
end


        
    
