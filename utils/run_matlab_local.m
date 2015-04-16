function run_matlab_local(f, local_storage_dir, varargin)
%RUN_MATLAB_LOCAL   Run a script with all dependency files stored locally.
%
%  run_matlab_local(f, local_storage_dir, ...)
%
%  Dependencies of the function to be run will be automatically
%  determined, and copied to a local directory. After script
%  execution, the copied dependency files will be deleted.
%
%  INPUTS:
%                  f:  handle to a function to run, or a string
%                      giving the name of a function on the path.
%
%  local_storage_dir:  path to a local directory in which to
%                      temporarily store dependency scripts.
%
%  Additional inputs will be passed to f.

if ischar(f)
  f = str2func(f);
end

% determine non-built-in dependencies
fprintf('run_matlab_local\n________________\n')
fprintf('Determining file dependencies...')
dep_files = matlab.codetools.requiredFilesAndProducts(func2str(f));
fprintf('done.\n')

% copy the dependencies to the local directory
fprintf('Copying file dependencies...')
dep_file_copies = cell(1, length(dep_files));
for i = 1:length(dep_files)
  [success, m, mid] = copyfile(dep_files{i}, local_storage_dir);
  [pathstr, name, ext] = fileparts(dep_files{i});
  dep_file_copies{i} = fullfile(local_storage_dir, [name ext]);
end
fprintf('done.\n')

fprintf('Setting path...')
p = path;
restoredefaultpath
addpath(local_storage_dir)
fprintf('done.\n')

% run the function
fprintf('Running %s...\n', func2str(f))
try
  f(varargin{:});
  fprintf('%s complete.\n', func2str(f))
catch err
  fprintf('%s threw an error: %s\n', func2str(f), err.message)
end

% clean up
for i = 1:length(dep_file_copies)
  delete(dep_file_copies{i});
end
path(p)
