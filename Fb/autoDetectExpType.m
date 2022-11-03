function expType = autoDetectExpType(Path, verbose)
%% autoDetectExpType
% @Knowblesse 2022 22SEP23
% Automatically detect experiment type
%   Conditioning
%   Extinction
%   Retention
%   Renewal
arguments
    Path {mustBeText} = "";
    verbose logical = true;
end

exp_info = regexp(Path, '.*(fpm|FPM)\d{1,2}_?(?<exp_type>\D*)\d?', 'names');
exp_str = exp_info.exp_type;

if strcmpi(exp_str, "con") || strcmpi(exp_str, "cond") || strcmpi(exp_str, "conditioning")
    expType = "Conditioning";
elseif strcmpi(exp_str, "ex") || strcmpi(exp_str, "ext") || strcmpi(exp_str, "extinction")
    expType = "Extinction";
elseif strcmpi(exp_str, "ret") || strcmpi(exp_str, "retention")
    expType = "Retention";
elseif strcmpi(exp_str, "rew") || strcmpi(exp_str, "ren") || strcmpi(exp_str, "renew") || strcmpi(exp_str, "renewal")
    expType = "Renewal";
else
    error('autoDetectExpType : Unknown experiment type : %s', exp_str);
end

if verbose
    fprintf('autoDetectExpType : %s experiment detected\n', expType);
end

end