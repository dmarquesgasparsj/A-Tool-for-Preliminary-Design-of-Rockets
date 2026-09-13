function db = thesis_structural_factor_database()
%THESIS_STRUCTURAL_FACTOR_DATABASE Table 4.2 from the 2014 MSc thesis.
%
% Rows are [min mean max]. Values are structural factor epsilon =
% ms/(ms+mp). The thesis used the mean value as the initial estimate for
% the structural-factor iteration.

cols = {'min','mean','max'};

db.columns = cols;

db.small.stage1 = [0.057 0.073 0.085];
db.small.stage2 = [0.073 0.090 0.095];
db.small.stage3 = [0.095 0.152 0.210];
db.small.stage4 = [0.124 0.153 0.193];

db.medium.booster = [0.087 0.101 0.115];
db.medium.stage1 = [0.049 0.086 0.119];
db.medium.stage2 = [0.095 0.117 0.153];
db.medium.stage3 = [0.065 0.131 0.171];

db.heavy.booster = [0.080 0.117 0.149];
db.heavy.stage1 = [0.039 0.063 0.076];
db.heavy.stage2 = [0.069 0.131 0.239];
db.heavy.stage3 = [0.082 0.121 0.182];
db.heavy.stage4 = [0.134 0.172 0.195];

db.source = 'Gaspar MSc thesis (2014), Table 4.2';
end
