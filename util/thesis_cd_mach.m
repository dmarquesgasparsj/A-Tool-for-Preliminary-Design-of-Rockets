function Cd = thesis_cd_mach(M)
%THESIS_CD_MACH 2014 thesis drag-coefficient fit, equation (3.49).
%
% Cd = -3e-6 M^6 + 2e-4 M^5 - 0.0046 M^4 + 0.053 M^3
%      - 0.2806 M^2 + 0.6211 M + 0.0568
%
% The thesis reports a 6th-order polynomial fit with about 90% regression
% to the source table used in 2014. This function deliberately evaluates
% that equation without adding a modern high-Mach clamp or shape-specific
% correction. Such improvements belong to a separate aerodynamic model.

validateattributes(M,{'numeric'},{'real','finite','nonnegative'});
Cd = -3e-6.*M.^6 + 2e-4.*M.^5 - 0.0046.*M.^4 + ...
     0.053.*M.^3 - 0.2806.*M.^2 + 0.6211.*M + 0.0568;
end
