function Data = loadFibData(Path, options)
%% loadFibData
% Select Tank to open, and gather Fiber Photometery Data
% Path : string path to the tank
% verbose : boolean : if true, output all import message

%% Input Parameters
arguments
    Path {mustBeText} = ""
    options.verbose logical = true;
end

%% Load Path
if strcmp(Path, "")
    global CURRENT_DIR;
    if ~isempty(CURRENT_DIR)
        Path = uigetdir(CURRENT_DIR);
    else
        Path = uigetdir();
    end
    if Path == 0
        error('loadFibData : User Cancelled');
    end
end

%% Load TDT
data = TDTbin2mat(Path, 'VERBOSE', options.verbose);

%% Parse CS Data
CSON = data.epocs.CSON.onset;
CSOF = data.epocs.CSOF.onset;

if size(CSON, 1) == size(CSOF, 1)
    CS = [CSON, CSOF];
    numTrial = size(CS,1);
else
    error('CS Size mismatch!');
end

if options.verbose
    fprintf('Total CS : %d\n', size(CS,1));
end

%% Parse Fiber Data
fs = data.streams.x405C.fs;
x465C_data = data.streams.x465C.data;
x405C_data = data.streams.x405C.data;
delta_data = (x465C_data - x405C_data) ./ x405C_data;

Data = struct();
Data.path = Path;
Data.cs = CS;
Data.fs = fs;
Data.x465 = x465C_data;
Data.x405 = x405C_data;
Data.delta = delta_data;

end






