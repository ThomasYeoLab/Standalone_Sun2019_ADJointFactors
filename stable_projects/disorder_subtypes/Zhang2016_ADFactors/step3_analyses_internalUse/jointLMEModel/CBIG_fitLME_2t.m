function stats = CBIG_fitLME_2t(subInfoFile, GMICVFile, q)

% stats = CBIG_fitLME_2t(subInfoFile, GMICVFile, q)
% What is the subtype order?
% Offset by 1, the RID column
%
% Written by CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md

COR_COL = 1+1;
fprintf('\n\n\n');
fprintf('!!! Subtype order assumed to be: cortical, temporal+subcortical.\n');
fprintf('!!! Make sure this is true in the gamma file.\n');

% All these info is baseline info
[RID_dx, RID_ICVoverGM, RID_prob, RID_age, RID_gender, RID_edu] = CBIG_get_data(subInfoFile, GMICVFile, 2);

% RID of 188 AD, 147 a+ MCI, 43 a+ AD
RID_188AD = RID_dx(RID_dx(:, 2)==3, 1);
RID_147MCI = CBIG_select_predementedGrp(RID_dx, 'a+_mci_147');
RID_43HC = CBIG_select_predementedGrp(RID_dx, 'a+_hc_43');
RID = sort([RID_188AD; RID_147MCI; RID_43HC]);

% Quantity of interest as y, and the other as regressor
[qoi, ~] = get_quantityOfInterest(RID, q, 0);
RID_time_score = CBIG_compute_time(qoi, qoi);

%--------------------------------------------- LME

% Construct X
X = zeros(size(RID_time_score, 1), 16);
for idx = 1:size(X, 1)
    RID = RID_time_score(idx, 1);
    t = RID_time_score(idx, 2);
    % Go fetch this subject's data
    rowIdx = RID_prob(:, 1)==RID;
    dx = RID_dx(rowIdx, 2);
    m = dx==2;
    d = dx==3;
    c = RID_prob(rowIdx, COR_COL);
    a = RID_age(rowIdx, 2);
    g = RID_gender(rowIdx, 2);
    e = RID_edu(rowIdx, 2);
    i = RID_ICVoverGM(rowIdx, 2);
    % Fill in one row
    X(idx, :) = [...
        1 m d c m*c d*c...
        t m*t d*t c*t m*c*t d*c*t...
        a g e i...
        ];
end

%!!!!!!
tcol = 7;

% Construct Y
Y = RID_time_score(:, 3);

% Sort by time for each subject -- actually X and Y are already sorted
sID = RID_time_score(:, 1);
[X_sort, Y_sort, ni, RID_sort] = sortData(X, tcol, Y, sID);

%--------- Estimate

% random effects only on constant column
[stats, ~] = lme_fit_FS(X_sort, [1], Y_sort, ni, 10^-15);

