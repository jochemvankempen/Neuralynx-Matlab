%% NLX_DOCM2HTML apply m2html function to create documentation
%

selfPath = fileparts(mfilename('fullpath'));
DocDir = fullfile(selfPath,'doc','m2html');

[selfDir,selfFileName,selfFileExt] = fileparts(selfPath);

if nargin<1
    [dummy,classesDir] = strtok(fliplr(selfDir),filesep);
    classesDir = fliplr(classesDir);
    [dummy,DocDir] = strtok(fliplr(classesDir),filesep);
    DocDir = fliplr(DocDir);
end

workingDir = pwd;
cd(selfDir);
cd ..

m2html( ...
    'mFiles', 'Neuralynx-Tools', ...
    'htmldir',DocDir, ...
    'recursive','off', ...
    'ignoredDir',{'.svn' 'cvs' '.git' 'doc'}, ...
    'template','blue'); % '3frame' 'frame' 'brain' 'blue'
cd(workingDir);
