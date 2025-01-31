function logPr = calcJointLogPr_ICSCHMMState( Psi, data )
%  OUTPUT
%     logPr : struct with fields
%                .F     : log p( F | hypers)
%                .obs   : log p( obs_ii | F_ii, s_ii )  sum over all ii
%                .z     : log p( s_ii | F_ii, hypers )  sum over all ii
%                .all   : log p( obs, F, s | hypers )

F        = Psi.F > 0;
gamma    = Psi.bpM.gamma;
c        = Psi.bpM.c;
TransM   = Psi.TransM;
ThetaM   = Psi.ThetaM;
stateSeq = Psi.stateSeq;

if isfield(Psi, 'Z_logPrb')
    Z_logPrb =  Psi.Z_logPrb;
else
    Z_logPrb = 0 ;
end
   
% -----------------------------   Compute prob. of binary feature mat F
logPr.F = calcLogPrFeatureMatrix( F, gamma, c );

logPr.z = TransM.calcMargPrStateSeq( F, stateSeq );

% Remember, no arguments means use stored suff stats
if ~exist( 'data', 'var' ) 
    logPr.obs = ThetaM.calcMargPrData( ); 
else
    logPr.obs = ThetaM.calcMargPrData( data, stateSeq );
end

% Extract log probability of Clustered Data
logPr.Z_logPrb = Z_logPrb;

% ============== combine all logPr into joint prob of chain state
logPrFields = fieldnames( logPr );
logPr.all = 0;
for ff = 1:length( logPrFields )
    logPr.all = logPr.all + logPr.( logPrFields{ff} );
end
