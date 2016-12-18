function test_suite = test_write_lines_with_prefix_generate_valid_classdef_files
    initTestSuite;
end

function fullname = tempfile(filename, contents)
    tempfolder = fullfile(tempdir, 'mocov_fixtures');
    [~, ~, ~] = mkdir(tempfolder);
    fullname = fullfile(tempfolder, filename);
    fid = fopen(fullname, 'w');
    fprintf(fid, contents);
    fclose(fid);
end

function filename = create_classdef
    filename = tempfile('AClass.m', [ ...
        'classdef AClass < handle\n', ...
        '  properties\n', ...
        '    aProp = 1;\n', ...
        '  end\n', ...
        '  properties (SetAccess = private, Dependent)\n', ...
        '    anotherProp;\n', ...
        '  end\n', ...
        '  methods\n', ...
        '    function self = AClass\n', ...
        '      self.anotherProp = 2;\n', ...
        '    end\n', ...
        '  end\n', ...
        '  methods (Access = public)\n', ...
        '    function aMethod(self, x)\n', ...
        '      self.aProp = x;\n', ...
        '    end\n', ...
        '  end\n', ...
        'end\n' ...
    ]);
end

function test_generate_valid_file
    originalPath = path;  % setup
    cleaner = onCleanup(@() path(originalPath));  % teardown

    % Given:
    % `AClass.m` file with a classdef declaration
    filename = create_classdef;
    % a folder where mocov will store the decorated files
    foldername = fullfile(tempdir, 'mocov_decorated');
    [~,~,~] = mkdir(foldername);
    decorated = fullfile(foldername, 'AClass.m');
    % a valid decorator
    decorator = @(line_number) ...
      sprintf('fprintf(0, ''%s:%d'');', filename, line_number);


    % When: the decorated file is generated
    mfile = MOcovMFile(filename);
    write_lines_with_prefix(mfile, decorated, decorator);


    % Then: the decorated file should have a valid syntax
    % Since Octave do not have a linter, run the code to check the syntax.
    addpath(foldername);
    try
      aObject = AClass();
      aObject.aMethod(4);
    catch
      assert(false, ['Problems when running the decorated file: `%s` ', ...
                     'please check for syntax errors.'], decorated);
    end
end
