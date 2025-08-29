function main(varargin)
% MAIN — Preliminary Rocket Design Toolkit (MATLAB/Octave)
%   MAIN(PAYLOAD, ORBIT) runs the design for the specified payload mass
%   [kg] and target ORBIT structure. When called with no inputs it prompts
%   the user via a GUI dialog to select orbit type and parameters.

clc; close all;

% Parse optional inputs
parser = inputParser;
addOptional(parser, 'payload', []);
addOptional(parser, 'orbit', struct());
parse(parser, varargin{:});

payload = parser.Results.payload;
orbit   = parser.Results.orbit;

% If arguments were not supplied, fall back to GUI dialog
if isempty(payload) || ~isfield(orbit, 'type')
    prompt   = {'Desired payload mass [kg]', 'Orbit type (circular/elliptic)'};
    dlgtitle = 'Mission setup';
    definput = {'1000', 'circular'};
    answer   = inputdlg(prompt, dlgtitle, 1, definput);
    if isempty(answer)
        error('User cancelled input dialog.');
    end
    payload = str2double(answer{1});
    orbtype = lower(strtrim(answer{2}));
    switch orbtype
        case 'circular'
            prm = inputdlg({'Target orbit altitude [km]'}, 'Orbit parameters', 1, {'200'});
            if isempty(prm), error('User cancelled input dialog.'); end
            orbit.type = 'circular';
            orbit.altitude_km = str2double(prm{1});
        case {'elliptic','elliptical','eliptica','elíptica'}
            prm = inputdlg({'Periapsis altitude [km]', 'Apoapsis altitude [km]'}, 'Orbit parameters', 1, {'200','500'});
            if isempty(prm), error('User cancelled input dialog.'); end
            orbit.type = 'elliptic';
            orbit.periapsis_km = str2double(prm{1});
            orbit.apoapsis_km = str2double(prm{2});
        otherwise
            error('Unknown orbit type.');
    end
end

mission.orbit = orbit;

run_design(payload, mission);
end
