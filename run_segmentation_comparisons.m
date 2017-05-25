%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main demo script for the ICSC-HMM Segmentation Algorithm proposed in:
%
% N. Figueroa and A. Billard, “Transform-Invariant Clustering of SPD Matrices 
% and its Application on Joint Segmentation and Action Discovery}”
% Arxiv, 2017. 
%
% Author: Nadia Figueroa, PhD Student., Robotics
% Learning Algorithms and Systems Lab, EPFL (Switzerland)
% Email address: nadia.figueroafernandez@epfl.ch  
% Website: http://lasa.epfl.ch
% November 2016; Last revision: 18-February-2017
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                    --Select a Dataset to Test--                       %%    
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1) Toy 2D dataset, 3 Unique Emission models, 3 time-series, same swicthing
clc; clear all; close all;
[data, TruePsi] = genToySeqData_Gaussian( 4, 2, 5, 500, 0.5 ); 

%% 2) Toy 2D dataset, 4 Unique Emission models, 5 time-series
clc; clear all; close all;
[data, TruePsi] = genToySeqData_Gaussian( 4, 2, 5, 500, 0.5 ); 

%% 3) Toy 2D dataset, 4 Unique Emission models, 5 time-series
clc; clear all; close all;
[data, TruePsi] = genToySeqData_Gaussian( 4, 2, 5, 500, 0.5 ); 

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%     Run E-M Model Selection for HMM with 10 runs in a range of K     %%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Model Selection for GMM
K_range = [1:10]; repeats = 20; cov_type = 'full';
ml_gmm_eval(Y, K_range, repeats, cov_type)

%%  Compute GMM Stats with 'optimal' K
% Set "Optimal " GMM Hyper-parameters
K = 3; T = 10;
cluster_purity = zeros(1,T);
cluster_NMI    = zeros(1,T);
cluster_F      = zeros(1,T);
for run=1:T    
  [Priors, Mu, Sigma] = ml_gmmEM(Y, K);
  [est_labels] =  ml_gmm_cluster(Y, Priors, Mu, Sigma);
  % Compute Metrics
  [cluster_purity(run) cluster_NMI(run) cluster_F(run)] = cluster_metrics(true_labels, est_labels);
end

% Final Stats for Mixture Model
fprintf('*** Gaussian Mixture Model w/MS Results*** \n Clusters: %d Purity: %3.3f +- %3.3f \n NMI: %3.3f +- %3.3f --- F: %3.3f +- %3.3f \n',[K ...
    mean(cluster_purity) std(cluster_purity) mean(cluster_NMI) std(cluster_NMI) mean(cluster_F) std(cluster_F)])

%%%%%%%% Visualize Spectral Manifold Representation for M=2 or M=3 %%%%%%%%
if exist('h1','var') && isvalid(h1), delete(h1);end
h1 = plotSpectralManifold(Y, est_labels, d,thres, s_norm, M);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%    Run Collapsed Gibbs Sampler for CRP-MM 10 times (Mo Chen's Implementation) %%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
T = 10;
cluster_purity = zeros(1,T);
cluster_NMI    = zeros(1,T);
cluster_F      = zeros(1,T);
est_clusters   = zeros(1,T);
for run=1:T  
    % Fit CRP Mixture Model to Data
    tic;
    [est_labels, Theta, w, ll] = mixGaussGb(Y);
    est_clusters(run)  = length(unique(est_labels));
    toc;
    % Compute Metrics
    [cluster_purity(run) cluster_NMI(run) cluster_F(run)] = cluster_metrics(true_labels, est_labels);    
end

%% Final Stats for CRP Mixture Model
fprintf('*** CRP Mixture Model (Mo Chen) Results*** \n Clusters: %3.3f +- %3.3f Purity: %3.3f +- %3.3f \n NMI: %3.3f +- %3.3f --- F: %3.3f +- %3.3f \n',[mean(est_clusters) std(est_clusters) ...
    mean(cluster_purity) std(cluster_purity) mean(cluster_NMI) std(cluster_NMI) mean(cluster_F) std(cluster_F)])

%%%%%%%% Visualize Spectral Manifold Representation for M=2 or M=3 %%%%%%%%
if exist('h1','var') && isvalid(h1), delete(h1);end
h1 = plotSpectralManifold(Y, est_labels, d,thres, s_norm, M);

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%         Run Sampler for DP-MM 10 times (Frank Wood's Implementation)      %%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
T = 10;
cluster_purity = zeros(1,T);
cluster_NMI    = zeros(1,T);
cluster_F      = zeros(1,T);
est_clusters   = zeros(1,T);
for run=1:T  
    % Fit CRP Mixture Model to Data
    iterations = 500;
    [class_id, mean_record, covariance_record, K_record, lP_record, alpha_record] = sampler(Y, iterations);
    [val , Maxiter]   = max(lP_record);
    est_labels        = class_id(:,Maxiter);
    est_clusters(run) = length(unique(est_labels));
    
    % Compute Metrics
    [cluster_purity(run) cluster_NMI(run) cluster_F(run)] = cluster_metrics(true_labels, est_labels);    
end

% Final Stats for CRP Mixture Model
fprintf('*** CRP Mixture Model (Frank Wood) Results*** \n Clusters: %3.3f +- %3.3f Purity: %3.3f +- %3.3f \n NMI: %3.3f +- %3.3f --- F: %3.3f +- %3.3f \n',[mean(est_clusters) std(est_clusters) ...
    mean(cluster_purity) std(cluster_purity) mean(cluster_NMI) std(cluster_NMI) mean(cluster_F) std(cluster_F)])

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%        Run Collapsed Gibbs Sampler for SPCM-CRP 10 times              %%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
T = 10;
Sampler_Stats = [];
cluster_purity = zeros(1,T);
cluster_NMI    = zeros(1,T);
cluster_F      = zeros(1,T);
est_clusters   = zeros(1,T);
for run=1:T    
    
    %%%%%%%% Non-parametric Clustering on Manifold Data with Sim prior %%%%%%%%
    % Setting sampler/model options (i.e. hyper-parameters, alpha, Covariance matrix)
    options                 = [];
    options.type            = 'full';  % Type of Covariance Matrix: 'full' = NIW or 'Diag' = NIG
    options.T               = 200;     % Sampler Iterations
    options.alpha           = 1;       % Concentration parameter
    
    % Standard Base Distribution Hyper-parameter setting
    if strcmp(options.type,'diag')
        lambda.alpha_0       = M;                    % G(sigma_k^-1|alpha_0,beta_0): (degrees of freedom)
        lambda.beta_0        = sum(diag(cov(Y')))/M; % G(sigma_k^-1|alpha_0,beta_0): (precision)
    end
    if strcmp(options.type,'full')
        lambda.nu_0        = M;                           % IW(Sigma_k|Lambda_0,nu_0): (degrees of freedom)
        lambda.Lambda_0    = eye(M)*sum(diag(cov(Y')))/M; % IW(Sigma_k|Lambda_0,nu_0): (Scale matrix)
    end
    lambda.mu_0             = mean(Y,2);    % hyper for N(mu_k|mu_0,kappa_0)
    lambda.kappa_0          = 1;            % hyper for N(mu_k|mu_0,kappa_0)
    
    
    % Run Collapsed Gibbs Sampler
    options.lambda    = lambda;
    [Psi Psi_Stats]   = run_ddCRP_sampler(Y, S, options);
    est_labels        = Psi.Z_C';
    
    % Store Stats
    Sampler_Stats(run).Psi = Psi;
    Sampler_Stats(run).Psi_Stats = Psi_Stats;
    est_clusters(run)  = length(unique(est_labels));
    
    % Compute Metrics
    [cluster_purity(run) cluster_NMI(run) cluster_F(run)] = cluster_metrics(true_labels, est_labels');
end

%% Final Stats for SPCM-CRP Mixture Model
fprintf('*** SPCM-CRM Mixture Model Results*** \n Clusters: %3.3f +- %3.3f Purity: %3.3f +- %3.3f \n NMI: %3.3f +- %3.3f --- F: %3.3f +- %3.3f \n',[mean(est_clusters) std(est_clusters) ...
    mean(cluster_purity) std(cluster_purity) mean(cluster_NMI) std(cluster_NMI) mean(cluster_F) std(cluster_F)])

%%%%%%%% Visualize Spectral Manifold Representation for M=2 or M=3 %%%%%%%%
if exist('h1','var') && isvalid(h1), delete(h1);end
h1 = plotSpectralManifold(Y, est_labels, d,thres, s_norm, M);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%% For Datasets 4a/b: Visualize cluster labels for DTI %%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Visualize Estimated Cluster Labels as DTI
if exist('h3','var') && isvalid(h3), delete(h3);end
title = 'Estimated Cluster Labels of Diffusion Tensors';
h3 = plotlabelsDTI(est_labels, title);