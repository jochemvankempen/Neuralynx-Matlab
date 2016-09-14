function NRD = NLX_readNRDbuffered(fPath,ADChan,ExtractMode,ExtractArray)

% Matlab based reader of Neuralynx Raw Data. very slow
%
% NRD = NLX_readNRD(fPath,ADChan,ExtractMode,ExtractArray)
%
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
% 1 Byte = 8 Bit
% 1 Kilobyte = 1024 Bytes
% 1 Megabyte = 1048576 Bytes
% 1 Gigabyte = 1073741824 Bytes

% Int32 STX                  Start of transmission identifier for the AD record. This value is always
%                            2048.
% Int32 Packet ID            Value to identify the type of packet. There is only one (1) type of
%                            packet for the NRD file format. This value is always 1.
% Int32 Packet Size          This value is equal to the number of AD channels plus the number of
%                            Extra values in the packet.
% UInt32 Timestamp High      The 32 high order bits that make up the 64 bit timestamp value. This
%                            value must be combined with the Timestamp Low value to create the
%                            full 64 bit Cheetah timestamp whose value is in microseconds. Please
%                            see Step 4 below for more information.
% UInt32 Timestamp Low       The 32 low order bits that make up the 64 bit timestamp value. This
%                            value must be combined with the Timestamp High value to create the
%                            full 64 bit Cheetah timestamp whose value is in microseconds. Please
%                            see Step 4 below for more information.
% Int32 Status               Reserved
% UInt32 Parallel Input Port The current value of the Parallel Input Port.
% Int32[] Extras             Reserved . This is currently an array ten (10) values containing
%                            reserved information from the hardware. While actual value of this
%                            array is not needed for data analysis, the number of values in this array
%                            needs to be taken into account when calculating the size of the Data
%                            block from the Packet Size value detailed above.
% Int32[] Data               Data values for the current record. The number of data values is based
%                            on the packet size value. The number of values in this array depends
%                            on the number of channels in your acquisition system. The size of this
%                            array is calculated by subtracting the number of Extra values from the
%                            Packet Size value detailed above.
% Int32 CRC                  The CRC value for the current record only.


%% open file
fid = fopen(fPath,'r');

% get size
status = fseek(fid,0,'eof');
FileBytes = ftell(fid);
status = fseek(fid,0,'bof');

%% read header
Hd = '';
[Hd,Hdcount] = fread(fid, 1024*16, 'uint8=>char');

% convert header
Hd = textscan(Hd,'%s','delimiter','\n');
NRD.Header  = Hd{1};
cHead = NLX_Head2Struct(NRD.Header);
%                      hash: {4x1 cell}
%                CheetahRev: '5.3.1'
%     HardwareSubSystemName: 'AcqSystem1'
%     HardwareSubSystemType: 'DigitalLynx'
%               NumChannels: 32
%                MaxADValue: 8388608
%         SamplingFrequency: 32556

%% prelimineries
numExtras = 10;
numChan = cHead.NumChannels;
numPacket = 7 + numExtras + numChan + 1;
PackageSizeInBytes = numPacket*32/8;

%% get valid start of data; SFX = 2048
ok = false;
while ~ok
    [ok,StartPos] = gotoNextSFX(fid,1024*1000,false);
    if ok
        ok = isValidPackage(fid,numPacket);
    end
end

% read first package
status = fseek(fid,StartPos,'bof');
[StartTime,StartData] = readDataPackage(fid,numExtras,numChan);

%%

switch ExtractMode
    case 4
        AcqOffsetTime = (ExtractArray(1)-StartTime);
        AcqOffsetPackNum = floor(AcqOffsetTime/(1e6/cHead.SamplingFrequency));
        AcqOffsetBytes = AcqOffsetPackNum.*PackageSizeInBytes;
        AcqStartPos = StartPos+AcqOffsetBytes;
        
        AcqTime = (ExtractArray(2)-ExtractArray(1));
        AcqPackNum = floor(AcqTime/(1e6/cHead.SamplingFrequency));
        AcqBytes = AcqPackNum.*PackageSizeInBytes;
    otherwise
        AcqStartPos = StartPos;
        AcqPackNum = 1;
        AcqBytes = AcqPackNum.*PackageSizeInBytes;
end

%%
NRD.TimeStamps = zeros(AcqPackNum,1).*NaN;
NRD.Samples = zeros(AcqPackNum,1).*NaN;
status = fseek(fid,AcqStartPos,'bof');
RawDataTimeToRead = 1e6/cHead.SamplingFrequency*AcqPackNum;
fprintf('reading %4.0fmin %2.3fsec of raw data (%1.3f Mb)\n',floor(RawDataTimeToRead*1e-6/60),rem(RawDataTimeToRead*1e-6,60),AcqBytes/1048576)
[B] = questdlg('Start reading?','No');
if ~strcmp(B,'Yes');return;end

tic;

% for iPac = 1:AcqPackNum
%     [cTimeStamp,cData] = readDataPackage(fid,numExtras,numChan,ADChan+1);
% %     cTimeStamp = 0;cData = 0;
%     if ~isempty(cTimeStamp)
%         NRD.TimeStamps(iPac) = cTimeStamp;
%         NRD.Samples(iPac) = cData(1);
%     end
% end

[NRD.TimeStamps,NRD.Samples] = readDataBuffer(fid,AcqPackNum,numExtras,numChan,ADChan+1);

ProcessingTime = toc;
fprintf(' needed %4.0fmin %2.3fsec to read\n',floor(ProcessingTime/60),rem(ProcessingTime,60))

%%
% TotalDataBytes = FileBytes-StartPos;
% NumPackageTotal = floor(TotalDataBytes/PackageSizeInBytes);
% dt = 1e6/cHead.SamplingFrequency;
% EstLastTime = StartTime + NumPackageTotal*dt;
% LastPos = StartPos + (NumPackageTotal-1) * PackageSizeInBytes;
% 
% % fprintf(1,'File Bytes   : %20.0f\n',FileBytes);
% % fprintf(1,'Start bytes  : %20.0f\n',StartPos);
% % fprintf(1,'Total Bytes  : %20.0f\n',TotalDataBytes);
% % fprintf(1,'Package Bytes: %20.0f\n',PackageSizeInBytes);
% % fprintf(1,'Package Num  : %20.2f\n',NumPackageTotal);
% % fprintf(1,'Last  bytes  : %20.0f\n',LastPos);
% 
% % read last package
% status = fseek(fid,LastPos,'bof');
% LastTime = readDataPackage(fid,numExtras,numChan);
% 

%%
fclose(fid);


function ok = isValidPackage(fid,numPacket)
ok = true;
cPos = ftell(fid);
cPacket = fread(fid,numPacket,'uint32');
crcValue = 0;
for iPac = 1:numPacket
    crcValue = bitxor(crcValue,cPacket(iPac,1));
end
if crcValue~=0;
    ok = false;
    return;
    %error('CRC error');
end
if cPacket(1)~=2048;
    ok = false;
    return;
    %error('STX error');
end
status = fseek(fid,cPos,'bof');

function [ok,cPos] = gotoNextSFX(fid,MaxBytes,echoOn)
ok = true;
zeroPos = ftell(fid);
cValue = fread(fid,1,'uint32');
cPos = ftell(fid);
% fprintf(1,'%u\t%u\n',cPos,cValue);
while cValue~= 2048 && (zeroPos-cPos)<MaxBytes
    cValue = fread(fid,1,'uint32');
    cPos = ftell(fid);
%     fprintf(1,'%u\t%u\n',cPos,cValue);
end
if cValue~=2048
    ok = false;
    fclose(fid);
%     error('Couldn''t find a valid STX value!');
    return;
else
    if echoOn
        fprintf(1,'STX %u @%u bytes\n',cValue,cPos);
    end
    status = fseek(fid,-4,'cof');
    cPos = cPos-4;
end

function [cTimeStamp,cData] = readDataPackage(fid,numExtras,numChan,iCh)
numPacket = 7 + numExtras + numChan + 1; 

ok = isValidPackage(fid,numPacket);
if ~ok
    cTimeStamp = [];
    cData = [];
end

% read a record
if nargin<4
    cSTX = fread(fid,1,'int32');
    cPacketID = fread(fid,1,'int32');
    cPacketSize = fread(fid,1,'int32');
    cTSHi = fread(fid,1,'uint32');
    cTSLo = fread(fid,1,'uint32');
    cStatus = fread(fid,1,'int32');
    cParInput = fread(fid,1,'uint32');
    cExtras = int32(zeros(numExtras,1));
    for j=1:numExtras
        cExtras(j,1) = fread(fid,1,'int32');
    end
    cData = int32(zeros(numChan,1));
    for j=1:numChan
        cData(j,1) = fread(fid,1,'int32');
    end
    cCRC = fread(fid,1,'int32');
else
    fseek(fid,4*3,'cof');
    cTSHi = fread(fid,1,'uint32');
    cTSLo = fread(fid,1,'uint32');
    fseek(fid,4*2+4*numExtras+(iCh-1)*4,'cof');
    cData = fread(fid,1,'int32');
    fseek(fid,(numChan-iCh)*4 +4*1,'cof');
end

% process record
cTimeStamp = bitshift(cTSHi,32) + cTSLo;
cData = cData';



function [cTimeStamp,cData] = readDataBuffer(fid,AcqPackNum,numExtras,numChan,ADChan)
numPacket = 7 + numExtras + numChan + 1;
PackageSizeInBytes = numPacket*32/8;

BufferPackNum = 1e6;
BufferPackSize = PackageSizeInBytes*8;

if AcqPackNum<=BufferPackNum
    BufferPackNum = AcqPackNum;
end
n = AcqPackNum./BufferPackNum;

cSFX = zeros(AcqPackNum,1);
cTimeStamp = zeros(AcqPackNum,1);
cData = zeros(AcqPackNum,1);

Buffer = uint8(zeros(BufferPackSize,BufferPackNum));
for j=1:n
    Buffer(:) = fread(fid,BufferPackNum*BufferPackSize,'uint8');
    for i = 1:BufferPackNum
        ci = 1;
        ci = ((ci-1)*32/8)+1;
        cSFX((j-1)*BufferPackNum+i,1) = typecast(Buffer(ci+[0:3],i)','uint32');
        
        ci = 4;
        ci = ((ci-1)*32/8)+1;
        cTimeStamp((j-1)*BufferPackNum+i,1) = typecast( Buffer([ci+[4 5 6 7] ci+[0 1 2 3]],i)'  ,'uint64');
        
        ci = (7+numExtras) + ADChan;
        ci = ((ci-1)*32/8)+1;
        cData((j-1)*BufferPackNum+i,1) = typecast(Buffer(ci+[0:3],i)','int32');
    end
end
