function a = third_body_acceleration(r_sc_eci_m,r_body_eci_m,mu_body)
%THIRD_BODY_ACCELERATION Differential third-body gravity in Earth frame.
%
% a = mu * ((rb-r)/|rb-r|^3 - rb/|rb|^3)
%
% The indirect term removes acceleration of the Earth-centred origin.

r=r_sc_eci_m(:); rb=r_body_eci_m(:);
if numel(r)~=3 || numel(rb)~=3
    error('third_body_acceleration:Dimension', ...
        'Spacecraft and body positions must be 3-vectors.');
end
validateattributes(mu_body,{'numeric'}, ...
    {'scalar','real','finite','positive'});
d=rb-r;
nd=norm(d); nb=norm(rb);
if nd<=0 || nb<=0
    error('third_body_acceleration:Position', ...
        'Third-body and separation distances must be positive.');
end
a=mu_body*(d/nd^3-rb/nb^3);
end
