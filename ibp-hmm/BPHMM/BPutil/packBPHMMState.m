function sPsi = packBPHMMState( Psi );

sPsi.F        = Psi.F;
sPsi.gamma    = Psi.bpM.gamma;
sPsi.c        = Psi.bpM.c;
sPsi.Eta      = Psi.TransM.seq;
sPsi.alpha    = Psi.TransM.prior.alpha;
sPsi.kappa    = Psi.TransM.prior.kappa;
sPsi.theta    = Psi.ThetaM.theta;
sPsi.stateSeq = Psi.stateSeq;

if isfield( Psi, 'Z' )
    sPsi.Z = Psi.Z;
    sPsi.K_z = Psi.K_z;
end

end