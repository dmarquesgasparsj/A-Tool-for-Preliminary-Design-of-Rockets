function out = historical_percent_deviation(reference_value,simulated_value)
%HISTORICAL_PERCENT_DEVIATION Thesis Eq. (6.1) percentage deviation.
%
%   100 * abs(reference - simulated) ./ abs(reference)
%
% NaN reference/simulated entries remain NaN. Zero reference values are
% returned as NaN because the thesis metric is undefined there.

reference_value=double(reference_value);
simulated_value=double(simulated_value);
if ~isequal(size(reference_value),size(simulated_value))
    error('historical_percent_deviation:Size', ...
        'reference_value and simulated_value must have the same size.');
end
out=NaN(size(reference_value));
mask=isfinite(reference_value) & isfinite(simulated_value) & ...
    abs(reference_value)>0;
out(mask)=100*abs(reference_value(mask)-simulated_value(mask))./ ...
    abs(reference_value(mask));
end
