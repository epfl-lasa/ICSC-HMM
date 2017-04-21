function [newPsi, Stats] = sampleSplitMerge_SeqAlloc( Psi, data, algParams, dis)
% Split Merge via Sequential Allocation
% Proposes new candidate configuration for feat matrix F and stateSeq z
%  and accepts or rejects via Metropolis-Hastings
% Proposal selects anchor objects and features to split/merge at random,
%   unless provided (see DEBUG NOTE below)
%INPUT:
%  Psi  : model config input
%  data : SeqData object
%  algParams : relevant params for this method
%    ** SM.featSelectDistr can be one of          
%       'random' : choose features to merge at random
%       'splitBias+margLik' (default) : use smart criteria to
%                    make successful proposals
%    ** SM.doSeqUpdateThetaHatOnMerge
%       if 1, refine Theta after visiting every seq. during merge proposal
%          0 (default), just estimate Theta initially and stick with it
%OUTPUT:
%  newPsi : model configuration as result of MH proposal
%    equals a new configuration when proposal accepted
%    or the input config Psi when rejected
%  Stats  : struct indicating type of move and whether accepted/rejected
%ASSUMES:
%  Psi comes with correct sufficient statistics for observed data (Xstats)
%DEBUG NOTE:
%   Can provide input "Psi" with fields "anchorIDs" and "activeFeatIDs"
%     to indicatea specific proposal to try. 
%   E.g. to merge features 1 and 5 using objects 101 and 202 as seeds, set
%    Psi.anchorIDs = [101 202];
%    Psi.activeFeatIDs = [1 5];  Note F(101,1) and F(202,5) must be ON.

% ---------- Selecting Anchors step ---------- %
% fprintf('Computing forward q and selecting features \n');

if isfield( Psi, 'activeFeatIDs' )
    [anchorIDs, featIDs, qFWD] = sampleAnchorAndFeatIDsToSplitMerge( Psi, data, algParams);
else
    [anchorIDs, featIDs, qFWD] = sampleAnchorAndFeatIDsToSplitMerge( Psi, data, algParams);
    Psi.anchorIDs        = anchorIDs;
    Psi.activeFeatIDs = featIDs;
end

% ---------- Do split/merge depending on anchor indices ---------- %
% Lines 4-9 of Alg B.1 SplitMergeBPHMM(x,Psi,alpha,kappa,lamnda)
% is_merge = 0;
if featIDs(1) == featIDs(2)
    if dis
        fprintf('Computing split proposal between feat %d and %d \n', featIDs(1), featIDs(2));
    end
    % =========================================== SPLIT    
    moveDescrStr = 'ADD';
    [propPsi, logQ] = sampleSplitConfig( Psi, data, anchorIDs, featIDs(1), algParams );
    [~, logQ_Rev]   = sampleMergeConfig( propPsi, data, anchorIDs, propPsi.activeFeatIDs, algParams, Psi );
else
    if dis
        fprintf('Computing merge proposal between feat %d and %d \n', featIDs(1), featIDs(2));
    end
    % =========================================== MERGE
%     is_merge = 1;
    moveDescrStr = 'DEL';   
    [propPsi, logQ] = sampleMergeConfig( Psi, data, anchorIDs, featIDs, algParams );
    [~, logQ_Rev]   = sampleSplitConfig( propPsi, data, anchorIDs, propPsi.activeFeatIDs, algParams, Psi );    
end

% Total up probabilities of FORWARD (Q) and REVERSE (Q_Rev) moves
[~, ~, qREV] = sampleAnchorAndFeatIDsToSplitMerge( propPsi, data, algParams );
% logQ_Rev
% logQ
logQ_Rev.all = log(qREV) + logQ_Rev.F + logQ_Rev.z;
logQ.all     = log(qFWD) + logQ.F + logQ.z;



% Line 11 of Alg B.1 SplitMergeBPHMM(x,Psi,alpha,kappa,lamnda)
% Calculate joint log prob of current and proposed states
% NB: not passing data as an arg here
%   means that we trust the stored X suff stats in Psi! Yay efficiency.
logPr_Cur  = calcJointLogPr_BPHMMState( Psi );
logPr_Prop = calcJointLogPr_BPHMMState( propPsi );

% fprintf('logPR_Prop: %f logPR_Curr: %f \n',logPr_Prop.all, logPr_Cur.all);
% fprintf('logQ_Rev: %f logQ: %f \n',logQ_Rev.all, logQ.all);

logQ_Hastings = logQ_Rev.all - logQ.all;
if algParams.doAnneal
    assert( ~isnan( logQ_Hastings ), 'Badness!' );
    if Psi.invTemp == 0 && isinf(logQ_Hastings)
        logQ_Hastings = -Inf; % always want to reject this proposal
        % this is a sign of something seriously bad with construction
    else
        logQ_Hastings = Psi.invTemp * logQ_Hastings;
    end
end

logPrAccept = logPr_Prop.all - logPr_Cur.all + logQ_Hastings;
rho = exp( logPrAccept );
% fprintf('rho: %f \n',rho);
assert( ~isnan( rho ), 'Accept rate should never be NaN!' );
rho = min(1, rho);
doAccept = rand < rho;

if (  doAccept )
    if dis
        fprintf ('Accepted move with %f probability\n', rho);
    end
    newPsi = propPsi;
    % Remove empty columns of F, and rename state sequence appropriately
    newPsi = reallocateFeatIDs( newPsi );
    if isfield( Psi, 'invTemp')
        newPsi.invTemp = Psi.invTemp;
    end
else
    if dis
        fprintf ('Rejected move.\n');
    end
    newPsi = Psi;
end

% Strip off info used internally to identify how to construct proposals
newPsi = rmfield( newPsi, 'anchorIDs');
newPsi = rmfield( newPsi, 'activeFeatIDs');

Stats.nAccept = doAccept;
Stats.rho = rho;
Stats.moveDescr = moveDescrStr;

end % main function