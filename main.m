function main(varargin)
% MAIN — Preliminary Rocket Design Toolkit (MATLAB/Octave)
%   MAIN(PAYLOAD, ORBIT_ALT) runs the design for the specified payload
%   mass [kg] and target orbit altitude [km]. When called with no inputs it
%   prompts the user via a GUI dialog.

clc; close all;

% Parse optional inputs
parser = inputParser;
addOptional(parser, 'payload', []);
addOptional(parser, 'orbit_alt', []);
parse(parser, varargin{:});

payload   = parser.Results.payload;
orbit_alt = parser.Results.orbit_alt;

% If arguments were not supplied, fall back to GUI dialog
if nargin < 2 || isempty(payload) || isempty(orbit_alt)
    prompt   = {'Desired payload mass [kg]', 'Target orbit altitude [km]'};
    dlgtitle = 'Mission setup';
    definput = {'1000', '200'};
    answer   = inputdlg(prompt, dlgtitle, 1, definput);
    if isempty(answer)
        error('User cancelled input dialog.');
    end
    payload   = str2double(answer{1});
    orbit_alt = str2double(answer{2});
end

run_design(payload, orbit_alt);
end
