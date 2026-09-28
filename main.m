function main(varargin)
%MAIN Interactive entry point for the generalized launcher toolkit.
%
% main()            offers integrated design, mass-only sizing and the
%                   earlier simplified trajectory demonstration.
% main(payload,km)  preserves the original run_design(payload,km) API.
%
% Programmatic scientific workflows should call run_integrated_design()
% or run_thesis_sizing() directly rather than depend on GUI menus.

root=fileparts(mfilename('fullpath'));
addpath(root);

if nargin==0
    choice=menu('A Tool for Preliminary Design of Rockets', ...
        'Integrated mass + trajectory design (experimental)', ...
        'Generalized mass sizing only', ...
        'Existing trajectory demo', ...
        'Cancel');
    if choice==1
        run_integrated_design();
        return;
    elseif choice==2
        run_thesis_sizing();
        return;
    elseif choice==4 || choice==0
        return;
    end
end

% Retain backwards compatibility with the earlier demonstration.
if nargin>=2 && ~isempty(varargin{1}) && ~isempty(varargin{2})
    payload=varargin{1};
    orbit_alt=varargin{2};
else
    answers=inputdlg( ...
        {'Desired payload mass [kg]','Target orbit altitude [km]'}, ...
        'Existing trajectory demo',1,{'1000','200'});
    if isempty(answers), return; end
    payload=str2double(answers{1});
    orbit_alt=str2double(answers{2});
end
validateattributes(payload,{'numeric'}, ...
    {'scalar','real','finite','positive'});
validateattributes(orbit_alt,{'numeric'}, ...
    {'scalar','real','finite','nonnegative'});
run_design(payload,orbit_alt);
end
