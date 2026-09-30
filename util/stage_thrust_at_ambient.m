function [T,detail] = stage_thrust_at_ambient(stage,ambient_pressure_Pa)
%STAGE_THRUST_AT_AMBIENT Evaluate constant or pressure-aware thrust.
%
% If stage.pressure_nozzle.enabled is true, the chamber/nozzle extension is
% used and thrust varies with ambient pressure. Otherwise stage.thrust_N is
% returned unchanged.

if isfield(stage,'pressure_nozzle') && isstruct(stage.pressure_nozzle) && ...
        isfield(stage.pressure_nozzle,'enabled') && stage.pressure_nozzle.enabled
    s=stage;
    fields=fieldnames(stage.pressure_nozzle);
    for i=1:numel(fields)
        if ~strcmp(fields{i},'enabled')
            s.(fields{i})=stage.pressure_nozzle.(fields{i});
        end
    end
    detail=pressure_aware_nozzle(s,ambient_pressure_Pa);
    T=detail.thrust_N;
else
    if ~isfield(stage,'thrust_N') || ~isfinite(stage.thrust_N)
        error('stage_thrust_at_ambient:MissingThrust', ...
            'stage.thrust_N is required for constant-thrust stages.');
    end
    T=stage.thrust_N;
    detail=struct('thrust_N',T,'ambient_pressure_Pa',ambient_pressure_Pa, ...
        'model','constant');
end
end
