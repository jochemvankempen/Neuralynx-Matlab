%% Create html files for documentation
% Create html documentation with publish functions
%
% Run this script as a command.
%
%%% publish-functions
%
% * matlab : publish.m 
% * Alwins : publishPlusFuncs.m
% 
% Options for publish/publishPlusFuncs
%
%         format           : 'html' | 'doc' | 'pdf' | 'ppt' | 'xml' | 'latex'
%         stylesheet       : '' | an XSL filename (ignored when format = 'doc', 'pdf', or 'ppt')
%         outputDir        : '' (an html subfolder below the file) | full path
%         imageFormat      : '' (default based on format)  'bmp' | 'eps' | 'epsc' | 'jpeg' | 'meta' | 'png' | 'ps' | 'psc' | 'tiff'
%         figureSnapMethod : 'entireGUIWindow'| 'print' | 'getframe' | 'entireFigureWindow'
%         useNewFigure     : true | false
%         maxHeight        : [] (unrestricted) | positive integer (pixels)
%         maxWidth         : [] (unrestricted) | positive integer (pixels)
%         showCode         : true | false
%         evalCode         : true | false
%         catchError       : true | false
%         createThumbnail  : true | false
%         maxOutputLines   : Inf | non-negative integer
%         codeToEvaluate   : (the file you are publishing) | any valid code
%

filePath = mfilename('fullpath');
[toolboxFolder,fileName] = fileparts(filePath);
thisDir = dir(toolboxFolder);
mFileList = {};
for i=1:length(thisDir)
    [dumPath,cFileName,cFileExt] = fileparts(thisDir(i).name);
    if ~thisDir(i).isdir && strcmpi(cFileExt,'.m')
        mFileList = cat(1,mFileList,cFileName);
    end
end
nFileNum = length(mFileList);

%% publish THIS script
opts.format    = 'html';
opts.outputDir = fullfile(toolboxFolder,'doc','html');
opts.showCode  = true;
opts.evalCode  = false;

docPath = publish(filePath,opts);

%% create funclist.m
% fid = fopen(fullfile(toolboxFolder,'doc','m','funclist.m'),'w+');
% fprintf(fid,'%%%% Project: LaminarExperiments - Function Reference\n');
% fprintf(fid,'%%\n');
% fprintf(fid,'%%%% Documentation \n');
% fprintf(fid,'%%\n');
% fprintf(fid,'%% * <%s.html %s>\n',fileName,fileName);
% fprintf(fid,'%%\n');
% fprintf(fid,'%%%% Functions \n');
% for i=1:nFileNum
%     fprintf(fid,'%% * <%s.html %s>\n',mFileList{i},mFileList{i});
% %     fprintf(fid,'%% * <%s_plusfuncs.html %s>\n',mFileList{i},mFileList{i});
%     % TODO: extract functions docstring here
% end
% fclose(fid);

%% create toc html-files
% Create TOC files for helptoc.xml.

opts.format    = 'html';
opts.outputDir = fullfile(toolboxFolder,'doc','html');
opts.showCode  = false;
opts.evalCode  = false;

docPath = publish(fullfile(toolboxFolder,'doc','m','myToolbox.m'),opts);
% docPath = publish(fullfile(toolboxFolder,'doc','m','funclist.m'),opts);
docPath = publish(fullfile(toolboxFolder,'doc','m','myExample.m'),opts);

%% create analysis html-files
% Create analysis files.
% opts.outputDir    = fullfile(toolboxFolder,'doc','html');
% opts.showCode     = false;
% opts.evalCode     = false;
% opts.useNewFigure = false;
% for i=1:nFileNum
%     fprintf(1,'publishing %s\n',sprintf('%s.m',mFileList{i}));
%     publish(fullfile(toolboxFolder,sprintf('%s.m',mFileList{i})),opts);
% %     publishPlusFuncs(fullfile(toolboxFolder,sprintf('%s.m',mFileList{i})),opts);
% end

