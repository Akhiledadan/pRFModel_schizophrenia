function SZ_pRFAnalysis(opt)
% SZ_pRFAnalysis - Plots Sigma/fWHM(DoGs)/Surround size(DoGs) vs eccentricity for the pRF fits to compare
% Schizophrenia patients with (ptwH+) and without (ptwH-) hallucinations
% and healthy controls (HC)
%
% Input - modeling results for nat and ph scr
%       - ROIs
%       - main_dir : mrVista session directory (where mrSESSION.mat file is located)
%       - save_results : path of folder to save the results
%       - save_plots : 1- save figures 0 - don't save
% 31/10/2018: [A.E] wrote it

%%
% Go to the root path where a simlink called data is created, containing
% the data
dirPth = loadPaths;

cd(SZ_rootPath);

% set options
%opt = getOpts('modelType','2DGaussian','plotType','Ecc_Sig');

fprintf('Model used: %s \n plotting: %s \n',opt.modelType, opt.plotType);

% for 2D Guassian model - use               opt = getOpts('modelType','2DGaussian'); for
%     Difference of gaussians - use         opt = getOpts('modelType','DoGs');
%
% To plot sigma vs ecc - use                opt = getOpts('plotType','Ecc_Sig');
%     sig vs fwhm DoGs                      opt = getOpts('plotType','Ecc_Sig_fwhm_DoGs');
%     sig vs surround size DoGs             opt = getOpts('plotType','Ecc_SurSize_DoGs');

%% Initializing required variables

fprintf('\n(%s)>>', mfilename);

% Select the ROIs
opt.rois = {'V1';'V2';'V3'};
%rois = {'WangAtlas_V1v';'WangAtlas_V2v';'WangAtlas_V3v'};

% Define the different conditions to be compared
opt.conditions = [{'ptwH+'};{'ptwH-'};{'HC'}];

opt.dataType = 'Averages';


% Make the directory to save results
cur_time = datestr(now);
cur_time(cur_time == ' ' | cur_time == ':' | cur_time == '-') = '_';


%% Extract the pRF parameters for individual subject, condition and ROI

if opt.extractPrfParams
    [Cond_model,ROI_params] = SZ_getModelParams(opt,dirPth);
else
    dirPth.saveDirPrfParams = fullfile(dirPth.saveDirRes,strcat(opt.modelType,'_',opt.plotType));
    load(fullfile(dirPth.saveDirPrfParams,'prfParams.mat'));
end

%% Basic exploratory analysis

SZ_expAnalysis(Cond_model,ROI_params,opt);

SZ_pRFsizeEcc(Cond_model,ROI_params,opt,dirPth);

%%
switch opt.analysis
    case 'subave_Ave'
        % Average the prf parameter value from the subjects first and then
        % Average the mean value from all the subjects
        % x range values for fitting
        xfit_range = [opt.eccThr(1) opt.eccThr(2)];
        xfit = linspace(xfit_range(1),xfit_range(2),8)';
        for roi_idx = 1:num_roi
            roi_comp = ROI_params.rois{roi_idx};
            
            % --------------------------------
            % figure 1. Distribution of points
            % --------------------------------
            if opt.verbose
                figName = sprintf('%s vs eccentricity','ecc');
                figPoint_dist_cond1 = figure(1); set(gcf, 'Color', 'w', 'Position',[100 100 1920 1080], 'Name', figName);
                figPoint_dist_cond2 = figure(10); set(gcf, 'Color', 'w', 'Position',[100 100 1920 1080], 'Name', figName);
                figPoint_dist_cond3 = figure(100); set(gcf, 'Color', 'w', 'Position',[100 100 1920 1080], 'Name', figName);
                
                figName = sprintf('%s vs eccentricity','ecc');
                
                if roi_idx == 1
                    figPoint_fit_comp_V1 = figure(1000+roi_idx); set(gcf, 'Color', 'w', 'Position',[100 100 1920 1080], 'Name', figName);
                elseif roi_idx == 2
                    figPoint_fit_comp_V2 = figure(1000+roi_idx); set(gcf, 'Color', 'w', 'Position',[100 100 1920 1080], 'Name', figName);
                else
                    figPoint_fit_comp_V3 = figure(1000+roi_idx); set(gcf, 'Color', 'w', 'Position',[100 100 1920 1080], 'Name', figName);
                end
                
            end
            
            for cond_idx = 1:numCond
                numSub = Cond_model.numSubjects(cond_idx);
                
                n_rows = 4;
                n_cols = 4;
                
                for sub_idx = 1:numSub
                    xfit_all(cond_idx).val(:,sub_idx,roi_idx) = xfit;
                    
                    switch opt.plotType
                        case 'Ecc_Sig'
                            yAxis = 'sigma';
                            yl = [0 6];
                            
                            yl_auc = [0 30];
                            
                            if cond_idx==1
                                idx_surSizeGr0_p1 = Cond_model{1,roi_comp}{1,sub_idx}.sigma ~= 0;
                                x_param_comp_1 = Cond_model{1,roi_comp}{1,sub_idx}.ecc(idx_surSizeGr0_p1);
                                y_param_comp_1 = Cond_model{1,roi_comp}{1,sub_idx}.sigma(idx_surSizeGr0_p1);
                                ve_comp_1 = Cond_model{1,roi_comp}{1,sub_idx}.varexp(idx_surSizeGr0_p1);
                                
                                if opt.verbose
                                    if opt.plot.dist
                                        % figure 1
                                        figure(1), subplot(n_rows,n_cols,sub_idx); hold on;
                                        plot(x_param_comp_1,y_param_comp_1,'.','color',[0.5+(roi_idx/10), 0.5, 1-(roi_idx/10)],'MarkerSize',10);
                                        %titleall = sprintf('%s', roi_comp) ;
                                        %legend(titleall);
                                        xlabel('eccentricity'); ylabel('pRF size');
                                        ylim([0 inf]);
                                    end
                                end
                                [param_comp_1_yfit,b] = NP_fit(x_param_comp_1,y_param_comp_1,ve_comp_1,xfit);
                                param_comp_1_yfit_all.val(:,sub_idx,roi_idx) = param_comp_1_yfit;
                                
                                % Bootstrap the data and bin the x parameter
                                [param_comp_1_data,param_comp_1_b_xfit,param_comp_1_b_upper,param_comp_1_b_lower] = NP_bin_param(x_param_comp_1,y_param_comp_1,ve_comp_1,xfit_range);
                                param_comp_1_b_xfit_all.val(:,sub_idx,roi_idx) = param_comp_1_data.x'  ; param_comp_1_data_all.val(:,sub_idx,roi_idx) = param_comp_1_data.y;
                                
                                if opt.verbose
                                    if opt.plot.fitComp
                                        % figure 2. fit to individual data points for every subject and every roi
                                        figure(1000+roi_idx);
                                        plot(xfit,param_comp_1_yfit,'color',[0.4 0.4 1],'LineWidth',1); hold on;
                                        if b.p(1)<0
                                            fprintf('sub: %d cond: %d roi: %d \n',sub_idx,cond_idx,roi_idx);
                                            plot(xfit,param_comp_1_yfit,'k','LineWidth',1); hold on;
                                        end
                                    end
                                end
                                
                            elseif cond_idx==2
                                idx_surSizeGr0_p2 = Cond_model{2,roi_comp}{1,sub_idx}.sigma ~= 0;
                                x_param_comp_2 = Cond_model{2,roi_comp}{1,sub_idx}.ecc(idx_surSizeGr0_p2);
                                y_param_comp_2 = Cond_model{2,roi_comp}{1,sub_idx}.sigma(idx_surSizeGr0_p2);
                                ve_comp_2 = Cond_model{2,roi_comp}{1,sub_idx}.varexp(idx_surSizeGr0_p2);
                                
                                if opt.verbose
                                    if opt.plot.dist
                                        % figure 1
                                        figure(10); subplot(n_rows,n_cols,sub_idx);hold on;
                                        plot(x_param_comp_2,y_param_comp_2,'.','color',[0.5+(roi_idx/10) 1-(roi_idx/10) 0.5+(roi_idx/10)],'MarkerSize',10);
                                        %titleall = sprintf('%s', roi_comp) ;
                                        %legend(titleall);
                                        xlabel('eccentricity'); ylabel('pRF size');
                                        ylim([0 inf]);
                                    end
                                end
                                
                                [param_comp_2_yfit,b] = NP_fit(x_param_comp_2,y_param_comp_2,ve_comp_2,xfit);
                                param_comp_2_yfit_all.val(:,sub_idx,roi_idx) = param_comp_2_yfit;
                                
                                [param_comp_2_data,param_comp_2_b_xfit,param_comp_2_b_upper,param_comp_2_b_lower] = NP_bin_param(x_param_comp_2,y_param_comp_2,ve_comp_2,xfit_range);
                                param_comp_2_b_xfit_all.val(:,sub_idx,roi_idx) = param_comp_2_data.x'  ; param_comp_2_data_all.val(:,sub_idx,roi_idx) = param_comp_2_data.y;
                                
                                if opt.verbose
                                    if opt.plot.fitComp
                                        % figure 2. fit to individual data points for every subject and every roi
                                        figure(1000+roi_idx);
                                        plot(xfit,param_comp_2_yfit,'color',[0.4 1 0.4],'LineWidth',1); hold on;
                                        if b.p(1)<0
                                            fprintf('sub: %d cond: %d roi: %d \n',sub_idx,cond_idx,roi_idx);
                                            plot(xfit,param_comp_2_yfit,'k','LineWidth',1); hold on;
                                            
                                        end
                                    end
                                end
                                
                            elseif cond_idx==3
                                idx_surSizeGr0_p3 = Cond_model{3,roi_comp}{1,sub_idx}.sigma ~= 0;
                                x_param_comp_3 = Cond_model{3,roi_comp}{1,sub_idx}.ecc(idx_surSizeGr0_p3);
                                y_param_comp_3 = Cond_model{3,roi_comp}{1,sub_idx}.sigma(idx_surSizeGr0_p3);
                                ve_comp_3 = Cond_model{3,roi_comp}{1,sub_idx}.varexp(idx_surSizeGr0_p3);
                                
                                if opt.verbose
                                    if opt.plot.dist
                                        % figure 1
                                        figure(100); subplot(n_rows,n_cols,sub_idx); hold on;
                                        plot(x_param_comp_3,y_param_comp_3,'.','color',[1-(roi_idx/10) 0.5+(roi_idx/10) 0.5],'MarkerSize',10);
                                        %titleall = sprintf('%s', roi_comp) ;
                                        %legend(titleall);
                                        xlabel('eccentricity'); ylabel('pRF size');
                                        ylim([0 inf]);
                                    end
                                end
                                
                                [param_comp_3_yfit,b] = NP_fit(x_param_comp_3,y_param_comp_3,ve_comp_3,xfit);
                                param_comp_3_yfit_all.val(:,sub_idx,roi_idx) = param_comp_3_yfit;
                                
                                [param_comp_3_data,param_comp_3_b_xfit,param_comp_3_b_upper,param_comp_3_b_lower] = NP_bin_param(x_param_comp_3,y_param_comp_3,ve_comp_3,xfit_range);
                                param_comp_3_b_xfit_all.val(:,sub_idx,roi_idx) = param_comp_3_data.x'  ; param_comp_3_data_all.val(:,sub_idx,roi_idx) = param_comp_3_data.y;
                                
                                if opt.verbose
                                    if opt.plot.fitComp
                                        % figure 2. fit to individual data points for every subject and every roi
                                        figure(1000+roi_idx);
                                        plot(xfit,param_comp_3_yfit,'color',[1 0.4 0.4],'LineWidth',1); hold on;
                                        if b.p(1)<0
                                            fprintf('sub: %d cond: %d roi: %d \n',sub_idx,cond_idx,roi_idx);
                                            plot(xfit,param_comp_3_yfit,'k','LineWidth',1); hold on;
                                        end
                                    end
                                end
                            end
                            
                        case 'Ecc_Sig2'
                            yAxis = 'sigma2';
                            yl = [0 6];
                            yl_auc = [0 25];
                            
                            x_param_comp_1 = Cond_model{1,roi_comp}{1,sub_idx}.ecc;
                            y_param_comp_1 = Cond_model{1,roi_comp}{1,sub_idx}.sigma2;
                            ve_comp_1 = Cond_model{1,roi_comp}{1,sub_idx}.varexp;
                            
                            x_param_comp_2 = Cond_model{2,roi_comp}{1,sub_idx}.ecc;
                            y_param_comp_2 = Cond_model{2,roi_comp}{1,sub_idx}.sigma2;
                            ve_comp_2 = Cond_model{2,roi_comp}{1,sub_idx}.varexp;
                            
                            x_param_comp_3 = Cond_model{3,roi_comp}{1,sub_idx}.ecc;
                            y_param_comp_3 = Cond_model{3,roi_comp}{1,sub_idx}.sigma2;
                            ve_comp_3 = Cond_model{3,roi_comp}{1,sub_idx}.varexp;
                            
                        case 'Ecc_Sig_fwhm_DoGs'
                            yAxis = 'DoGs fWHM';
                            yl = [0 12];
                            yl_auc = [0 inf];
                            
                            if cond_idx==1
                                idx_surSizeGr0_p1 = Cond_model{1,roi_comp}{1,sub_idx}.DoGs_fwhmax ~= 0;
                                x_param_comp_1 = Cond_model{1,roi_comp}{1,sub_idx}.ecc(idx_surSizeGr0_p1);
                                y_param_comp_1 = Cond_model{1,roi_comp}{1,sub_idx}.DoGs_fwhmax(idx_surSizeGr0_p1);
                                ve_comp_1 = Cond_model{1,roi_comp}{1,sub_idx}.varexp(idx_surSizeGr0_p1);
                                if opt.verbose
                                    if opt.plot.dist
                                        figure(1), subplot(n_rows,n_cols,sub_idx); hold on;
                                        plot(x_param_comp_1,y_param_comp_1,'.','color',[0.5+(roi_idx/10), 0.5, 1-(roi_idx/10)],'MarkerSize',10);
                                        xlabel('eccentricity'); ylabel('pRF size');
                                        ylim([0 inf]);
                                    end
                                end
                                [param_comp_1_yfit,b] = NP_fit(x_param_comp_1,y_param_comp_1,ve_comp_1,xfit);
                                param_comp_1_yfit_all.val(:,sub_idx,roi_idx) = param_comp_1_yfit;
                                
                                % Bootstrap the data and bin the x parameter
                                [param_comp_1_data,param_comp_1_b_xfit,param_comp_1_b_upper,param_comp_1_b_lower] = NP_bin_param(x_param_comp_1,y_param_comp_1,ve_comp_1,xfit_range);
                                param_comp_1_b_xfit_all.val(:,sub_idx,roi_idx) = param_comp_1_data.x'  ; param_comp_1_data_all.val(:,sub_idx,roi_idx) = param_comp_1_data.y;
                                if opt.verbose
                                    if opt.plot.fitComp
                                        figure(1000+roi_idx);
                                        plot(xfit,param_comp_1_yfit,'color',[0.4 0.4 1],'LineWidth',1); hold on;
                                        if b.p(1)<0
                                            fprintf('sub: %d cond: %d roi: %d \n',sub_idx,cond_idx,roi_idx);
                                            plot(xfit,param_comp_1_yfit,'k','LineWidth',1); hold on;
                                        end
                                    end
                                end
                            elseif cond_idx==2
                                idx_surSizeGr0_p2 = Cond_model{2,roi_comp}{1,sub_idx}.DoGs_fwhmax ~= 0;
                                x_param_comp_2 = Cond_model{2,roi_comp}{1,sub_idx}.ecc(idx_surSizeGr0_p2);
                                y_param_comp_2 = Cond_model{2,roi_comp}{1,sub_idx}.DoGs_fwhmax(idx_surSizeGr0_p2);
                                ve_comp_2 = Cond_model{2,roi_comp}{1,sub_idx}.varexp(idx_surSizeGr0_p2);
                                if opt.verbose
                                    if opt.plot.dist
                                        figure(10); subplot(n_rows,n_cols,sub_idx);hold on;
                                        plot(x_param_comp_2,y_param_comp_2,'.','color',[0.5+(roi_idx/10) 1-(roi_idx/10) 0.5+(roi_idx/10)],'MarkerSize',10);
                                        xlabel('eccentricity'); ylabel('pRF size');
                                        ylim([0 inf]);
                                    end
                                end
                                [param_comp_2_yfit,b] = NP_fit(x_param_comp_2,y_param_comp_2,ve_comp_2,xfit);
                                param_comp_2_yfit_all.val(:,sub_idx,roi_idx) = param_comp_2_yfit;
                                
                                [param_comp_2_data,param_comp_2_b_xfit,param_comp_2_b_upper,param_comp_2_b_lower] = NP_bin_param(x_param_comp_2,y_param_comp_2,ve_comp_2,xfit_range);
                                param_comp_2_b_xfit_all.val(:,sub_idx,roi_idx) = param_comp_2_data.x'  ; param_comp_2_data_all.val(:,sub_idx,roi_idx) = param_comp_2_data.y;
                                
                                figure(1000+roi_idx);
                                plot(xfit,param_comp_2_yfit,'color',[0.4 1 0.4],'LineWidth',1); hold on;
                                
                                if b.p(1)<0
                                    fprintf('sub: %d cond: %d roi: %d \n',sub_idx,cond_idx,roi_idx);
                                    plot(xfit,param_comp_2_yfit,'k','LineWidth',1); hold on;
                                end
                                
                            elseif cond_idx==3
                                idx_surSizeGr0_p3 = Cond_model{3,roi_comp}{1,sub_idx}.DoGs_fwhmax ~= 0;
                                x_param_comp_3 = Cond_model{3,roi_comp}{1,sub_idx}.ecc(idx_surSizeGr0_p3);
                                y_param_comp_3 = Cond_model{3,roi_comp}{1,sub_idx}.DoGs_fwhmax(idx_surSizeGr0_p3);
                                ve_comp_3 = Cond_model{3,roi_comp}{1,sub_idx}.varexp(idx_surSizeGr0_p3);
                                if opt.verbose
                                    if opt.plot.dist
                                        figure(100); subplot(n_rows,n_cols,sub_idx); hold on;
                                        plot(x_param_comp_3,y_param_comp_3,'.','color',[1-(roi_idx/10) 0.5+(roi_idx/10) 0.5],'MarkerSize',10);
                                        xlabel('eccentricity'); ylabel('pRF size');
                                        ylim([0 inf]);
                                    end
                                end
                                [param_comp_3_yfit,b] = NP_fit(x_param_comp_3,y_param_comp_3,ve_comp_3,xfit);
                                param_comp_3_yfit_all.val(:,sub_idx,roi_idx) = param_comp_3_yfit;
                                
                                [param_comp_3_data,param_comp_3_b_xfit,param_comp_3_b_upper,param_comp_3_b_lower] = NP_bin_param(x_param_comp_3,y_param_comp_3,ve_comp_3,xfit_range);
                                param_comp_3_b_xfit_all.val(:,sub_idx,roi_idx) = param_comp_3_data.x'  ; param_comp_3_data_all.val(:,sub_idx,roi_idx) = param_comp_3_data.y;
                                if opt.verbose
                                    if opt.plot.fitComp
                                        figure(1000+roi_idx);
                                        plot(xfit,param_comp_3_yfit,'color',[1 0.4 0.4],'LineWidth',1); hold on;
                                        
                                        if b.p(1)<0
                                            fprintf('sub: %d cond: %d roi: %d \n',sub_idx,cond_idx,roi_idx);
                                            plot(xfit,param_comp_3_yfit,'k','LineWidth',1); hold on;
                                        end
                                    end
                                end
                            end
                            
                            
                        case 'Ecc_SurSize_DoGs'
                            yAxis = 'DoGs Surround size';
                            yl = [0 40];
                            
                            yl_auc = [0 300];
                            
                            if cond_idx==1
                                idx_surSizeGr0_p1 = Cond_model{1,roi_comp}{1,sub_idx}.DoGs_surroundSize ~= 0;
                                x_param_comp_1 = Cond_model{1,roi_comp}{1,sub_idx}.ecc(idx_surSizeGr0_p1);
                                y_param_comp_1 = Cond_model{1,roi_comp}{1,sub_idx}.DoGs_surroundSize(idx_surSizeGr0_p1);
                                ve_comp_1 = Cond_model{1,roi_comp}{1,sub_idx}.varexp(idx_surSizeGr0_p1);
                                if opt.verbose
                                    if opt.plot.dist
                                        figure(1), subplot(n_rows,n_cols,sub_idx); hold on;
                                        plot(x_param_comp_1,y_param_comp_1,'.','color',[0.5+(roi_idx/10), 0.5, 1-(roi_idx/10)],'MarkerSize',10);
                                        xlabel('eccentricity'); ylabel('pRF size');
                                        ylim([0 inf]);
                                    end
                                end
                                [param_comp_1_yfit,b] = NP_fit(x_param_comp_1,y_param_comp_1,ve_comp_1,xfit);
                                param_comp_1_yfit_all.val(:,sub_idx,roi_idx) = param_comp_1_yfit;
                                
                                % Bootstrap the data and bin the x parameter
                                [param_comp_1_data,param_comp_1_b_xfit,param_comp_1_b_upper,param_comp_1_b_lower] = NP_bin_param(x_param_comp_1,y_param_comp_1,ve_comp_1,xfit_range);
                                param_comp_1_b_xfit_all.val(:,sub_idx,roi_idx) = param_comp_1_data.x'  ; param_comp_1_data_all.val(:,sub_idx,roi_idx) = param_comp_1_data.y;
                                if opt.verbose
                                    if opt.plot.fitComp
                                        figure(1000+roi_idx);
                                        plot(xfit,param_comp_1_yfit,'color',[0.4 0.4 1],'LineWidth',1); hold on;
                                        if b.p(1)<0
                                            fprintf('sub: %d cond: %d roi: %d \n',sub_idx,cond_idx,roi_idx);
                                            plot(xfit,param_comp_1_yfit,'k','LineWidth',1); hold on;
                                        end
                                    end
                                end
                            elseif cond_idx==2
                                idx_surSizeGr0_p2 = Cond_model{2,roi_comp}{1,sub_idx}.DoGs_surroundSize ~= 0;
                                x_param_comp_2 = Cond_model{2,roi_comp}{1,sub_idx}.ecc(idx_surSizeGr0_p2);
                                y_param_comp_2 = Cond_model{2,roi_comp}{1,sub_idx}.DoGs_surroundSize(idx_surSizeGr0_p2);
                                ve_comp_2 = Cond_model{2,roi_comp}{1,sub_idx}.varexp(idx_surSizeGr0_p2);
                                if opt.verbose
                                    if opt.plot.dist
                                        figure(10); subplot(n_rows,n_cols,sub_idx);hold on;
                                        plot(x_param_comp_2,y_param_comp_2,'.','color',[0.5+(roi_idx/10) 1-(roi_idx/10) 0.5+(roi_idx/10)],'MarkerSize',10);
                                        xlabel('eccentricity'); ylabel('pRF size');
                                        ylim([0 inf]);
                                    end
                                end
                                [param_comp_2_yfit,b] = NP_fit(x_param_comp_2,y_param_comp_2,ve_comp_2,xfit);
                                param_comp_2_yfit_all.val(:,sub_idx,roi_idx) = param_comp_2_yfit;
                                
                                [param_comp_2_data,param_comp_2_b_xfit,param_comp_2_b_upper,param_comp_2_b_lower] = NP_bin_param(x_param_comp_2,y_param_comp_2,ve_comp_2,xfit_range);
                                param_comp_2_b_xfit_all.val(:,sub_idx,roi_idx) = param_comp_2_data.x'  ; param_comp_2_data_all.val(:,sub_idx,roi_idx) = param_comp_2_data.y;
                                if opt.verbose
                                    if opt.plot.fitComp
                                        figure(1000+roi_idx);
                                        plot(xfit,param_comp_2_yfit,'color',[0.4 1 0.4],'LineWidth',1); hold on;
                                        if b.p(1)<0
                                            fprintf('sub: %d cond: %d roi: %d \n',sub_idx,cond_idx,roi_idx);
                                            plot(xfit,param_comp_2_yfit,'k','LineWidth',1); hold on;
                                        end
                                    end
                                end
                            elseif cond_idx==3
                                idx_surSizeGr0_p3 = Cond_model{3,roi_comp}{1,sub_idx}.DoGs_surroundSize ~= 0;
                                x_param_comp_3 = Cond_model{3,roi_comp}{1,sub_idx}.ecc(idx_surSizeGr0_p3);
                                y_param_comp_3 = Cond_model{3,roi_comp}{1,sub_idx}.DoGs_surroundSize(idx_surSizeGr0_p3);
                                ve_comp_3 = Cond_model{3,roi_comp}{1,sub_idx}.varexp(idx_surSizeGr0_p3);
                                if opt.verbose
                                    if opt.plot.dist
                                        figure(100); subplot(n_rows,n_cols,sub_idx); hold on;
                                        plot(x_param_comp_3,y_param_comp_3,'.','color',[1-(roi_idx/10) 0.5+(roi_idx/10) 0.5],'MarkerSize',10);
                                        xlabel('eccentricity'); ylabel('pRF size');
                                        ylim([0 inf]);
                                    end
                                end
                                [param_comp_3_yfit,b] = NP_fit(x_param_comp_3,y_param_comp_3,ve_comp_3,xfit);
                                param_comp_3_yfit_all.val(:,sub_idx,roi_idx) = param_comp_3_yfit;
                                
                                [param_comp_3_data,param_comp_3_b_xfit,param_comp_3_b_upper,param_comp_3_b_lower] = NP_bin_param(x_param_comp_3,y_param_comp_3,ve_comp_3,xfit_range);
                                param_comp_3_b_xfit_all.val(:,sub_idx,roi_idx) = param_comp_3_data.x'  ; param_comp_3_data_all.val(:,sub_idx,roi_idx) = param_comp_3_data.y;
                                if opt.verbose
                                    if opt.plot.fitComp
                                        figure(1000+roi_idx);
                                        plot(xfit,param_comp_3_yfit,'color',[1 0.4 0.4],'LineWidth',1); hold on;
                                        
                                        if b.p(1)<0
                                            fprintf('sub: %d cond: %d roi: %d \n',sub_idx,cond_idx,roi_idx);
                                            plot(xfit,param_comp_3_yfit,'k','LineWidth',1); hold on;
                                        end
                                    end
                                end
                            end
                            
                        case 'Ecc_SurDepth_DoGs'
                            yAxis = 'DoGs Surround depth';
                            yl = [0 1];
                            
                            yl_auc = [0 inf];
                            
                            if cond_idx==1
                                idx_surDepthGr0_p1 = Cond_model{1,roi_comp}{1,sub_idx}.DoGs_surr_depth ~= 0;
                                x_param_comp_1 = Cond_model{1,roi_comp}{1,sub_idx}.ecc(idx_surDepthGr0_p1);
                                y_param_comp_1 = Cond_model{1,roi_comp}{1,sub_idx}.DoGs_surr_depth(idx_surDepthGr0_p1);
                                ve_comp_1 = Cond_model{1,roi_comp}{1,sub_idx}.varexp(idx_surDepthGr0_p1);
                                
                                % remove outliers for the surround depth,
                                % (surDepth > mean + 2*std) should be
                                % removed ?
                                y_param_1_avg = mean(y_param_comp_1);
                                y_param_1_std = std(y_param_comp_1);
                                outL_idx = y_param_comp_1 > y_param_1_avg + 2*y_param_1_std;
                                y_param_comp_1 = y_param_comp_1(~outL_idx);
                                x_param_comp_1 = x_param_comp_1(~outL_idx);
                                ve_comp_1 = ve_comp_1(~outL_idx);
                                
                                if opt.verbose
                                    if opt.plot.dist
                                        figure(1), subplot(n_rows,n_cols,sub_idx); hold on;
                                        plot(x_param_comp_1,y_param_comp_1,'.','color',[0.5+(roi_idx/10), 0.5, 1-(roi_idx/10)],'MarkerSize',10);
                                        xlabel('eccentricity'); ylabel('pRF surround depth');
                                        ylim([0 1]);
                                    end
                                end
                                
                                
                                % average the surround depth across the
                                % whole subjects and eccentricities
                                % weighted with variance explained
                                y_param_comp_1_avg = wstat(y_param_comp_1,ve_comp_1);
                                y_param_comp_1_avg_all.val(:,sub_idx,roi_idx) = y_param_comp_1_avg.mean;                                
                                
                                [param_comp_1_yfit,b] = NP_fit(x_param_comp_1,y_param_comp_1,ve_comp_1,xfit);
                                param_comp_1_yfit_all.val(:,sub_idx,roi_idx) = param_comp_1_yfit;
                                
                                % Bootstrap the data and bin the x parameter
                                [param_comp_1_data,param_comp_1_b_xfit,param_comp_1_b_upper,param_comp_1_b_lower] = NP_bin_param(x_param_comp_1,y_param_comp_1,ve_comp_1,xfit_range);
                                param_comp_1_b_xfit_all.val(:,sub_idx,roi_idx) = param_comp_1_data.x'  ; param_comp_1_data_all.val(:,sub_idx,roi_idx) = param_comp_1_data.y;
                                if opt.verbose
                                    if opt.plot.fitComp
                                        figure(1000+roi_idx);
                                        plot(xfit,param_comp_1_yfit,'color',[0.4 0.4 1],'LineWidth',1); hold on;
                                        if b.p(1)<0
                                            fprintf('sub: %d cond: %d roi: %d \n',sub_idx,cond_idx,roi_idx);
                                            plot(xfit,param_comp_1_yfit,'k','LineWidth',1); hold on;
                                             ylim([0 1]);
                                        end
                                    end
                                end
                            elseif cond_idx==2
                                idx_surDepthGr0_p2 = Cond_model{2,roi_comp}{1,sub_idx}.DoGs_surr_depth ~= 0;
                                x_param_comp_2 = Cond_model{2,roi_comp}{1,sub_idx}.ecc(idx_surDepthGr0_p2);
                                y_param_comp_2 = Cond_model{2,roi_comp}{1,sub_idx}.DoGs_surr_depth(idx_surDepthGr0_p2);
                                ve_comp_2 = Cond_model{2,roi_comp}{1,sub_idx}.varexp(idx_surDepthGr0_p2);
                               
                                % remove outliers for the surround depth,
                                % (surDepth > mean + 2*std) should be
                                % removed ?
                                y_param_2_avg = mean(y_param_comp_2);
                                y_param_2_std = std(y_param_comp_2);
                                outL_idx = y_param_comp_2 > y_param_2_avg + 2*y_param_2_std;
                                y_param_comp_2 = y_param_comp_2(~outL_idx);
                                x_param_comp_2 = x_param_comp_2(~outL_idx);
                                ve_comp_2 = ve_comp_2(~outL_idx);
                                
                                if opt.verbose
                                    if opt.plot.dist
                                        figure(10); subplot(n_rows,n_cols,sub_idx);hold on;
                                        plot(x_param_comp_2,y_param_comp_2,'.','color',[0.5+(roi_idx/10) 1-(roi_idx/10) 0.5+(roi_idx/10)],'MarkerSize',10);
                                        xlabel('eccentricity'); ylabel('pRF surround depth');
                                        ylim([0 1]);
                                    end
                                end
                                
                                % average the surround depth across the
                                % whole subjects and eccentricities
                                % weighted with variance explained
                                y_param_comp_2_avg = wstat(y_param_comp_2,ve_comp_2);
                                y_param_comp_2_avg_all.val(:,sub_idx,roi_idx) = y_param_comp_2_avg.mean;
                                
                                [param_comp_2_yfit,b] = NP_fit(x_param_comp_2,y_param_comp_2,ve_comp_2,xfit);
                                param_comp_2_yfit_all.val(:,sub_idx,roi_idx) = param_comp_2_yfit;
                                
                                [param_comp_2_data,param_comp_2_b_xfit,param_comp_2_b_upper,param_comp_2_b_lower] = NP_bin_param(x_param_comp_2,y_param_comp_2,ve_comp_2,xfit_range);
                                param_comp_2_b_xfit_all.val(:,sub_idx,roi_idx) = param_comp_2_data.x'  ; param_comp_2_data_all.val(:,sub_idx,roi_idx) = param_comp_2_data.y;
                                if opt.verbose
                                    if opt.plot.fitComp
                                        figure(1000+roi_idx);
                                        plot(xfit,param_comp_2_yfit,'color',[0.4 1 0.4],'LineWidth',1); hold on;
                                        if b.p(1)<0
                                            fprintf('sub: %d cond: %d roi: %d \n',sub_idx,cond_idx,roi_idx);
                                            plot(xfit,param_comp_2_yfit,'k','LineWidth',1); hold on;
                                        end
                                        ylim([0 1]);
                                    end
                                end
                            elseif cond_idx==3
                                idx_surDepthGr0_p3 = Cond_model{3,roi_comp}{1,sub_idx}.DoGs_surr_depth ~= 0;
                                x_param_comp_3 = Cond_model{3,roi_comp}{1,sub_idx}.ecc(idx_surDepthGr0_p3);
                                y_param_comp_3 = Cond_model{3,roi_comp}{1,sub_idx}.DoGs_surr_depth(idx_surDepthGr0_p3);
                                ve_comp_3 = Cond_model{3,roi_comp}{1,sub_idx}.varexp(idx_surDepthGr0_p3);
                                
                                % remove outliers for the surround depth,
                                % (surDepth > mean + 2*std) should be
                                % removed ?
                                y_param_3_avg = mean(y_param_comp_3);
                                y_param_3_std = std(y_param_comp_3);
                                outL_idx = y_param_comp_3 > y_param_3_avg + 2*y_param_3_std;
                                y_param_comp_3 = y_param_comp_3(~outL_idx);
                                x_param_comp_3 = x_param_comp_3(~outL_idx);
                                ve_comp_3 = ve_comp_3(~outL_idx);
                                
                                if opt.verbose
                                    if opt.plot.dist
                                        figure(100); subplot(n_rows,n_cols,sub_idx); hold on;
                                        plot(x_param_comp_3,y_param_comp_3,'.','color',[1-(roi_idx/10) 0.5+(roi_idx/10) 0.5],'MarkerSize',10);
                                        xlabel('eccentricity'); ylabel('pRF surround depth');
                                        ylim([0 1]);
                                    end
                                end
                                
                                % average the surround depth across the
                                % whole subjects and eccentricities
                                % weighted with variance explained
                                y_param_comp_3_avg = wstat(y_param_comp_3,ve_comp_3);
                                y_param_comp_3_avg_all.val(:,sub_idx,roi_idx) = y_param_comp_3_avg.mean;
                                
                                [param_comp_3_yfit,b] = NP_fit(x_param_comp_3,y_param_comp_3,ve_comp_3,xfit);
                                param_comp_3_yfit_all.val(:,sub_idx,roi_idx) = param_comp_3_yfit;
                                
                                [param_comp_3_data,param_comp_3_b_xfit,param_comp_3_b_upper,param_comp_3_b_lower] = NP_bin_param(x_param_comp_3,y_param_comp_3,ve_comp_3,xfit_range);
                                param_comp_3_b_xfit_all.val(:,sub_idx,roi_idx) = param_comp_3_data.x'  ; param_comp_3_data_all.val(:,sub_idx,roi_idx) = param_comp_3_data.y;
                                if opt.verbose
                                    if opt.plot.fitComp
                                        figure(1000+roi_idx);
                                        plot(xfit,param_comp_3_yfit,'color',[1 0.4 0.4],'LineWidth',1); hold on;
                                        
                                        if b.p(1)<0
                                            fprintf('sub: %d cond: %d roi: %d \n',sub_idx,cond_idx,roi_idx);
                                            plot(xfit,param_comp_3_yfit,'k','LineWidth',1); hold on;
                                        end
                                        ylim([0 1]);
                                    end
                                end
                            end
                            
                            
                    end
                    
                    
                    
                end
            end
        end
        if opt.verbose
            figure(1);legend(rois);
            figure(10);legend(rois);
            figure(100);legend(rois);
        end
        
        param_comp_1_yfit_all_ave = mean(param_comp_1_yfit_all.val,2);
        param_comp_2_yfit_all_ave = mean(param_comp_2_yfit_all.val,2);
        param_comp_3_yfit_all_ave = mean(param_comp_3_yfit_all.val,2);
        
        param_comp_1_b_xfit_all_ave = mean(param_comp_1_b_xfit_all.val,2);
        param_comp_2_b_xfit_all_ave = mean(param_comp_2_b_xfit_all.val,2);
        param_comp_3_b_xfit_all_ave = mean(param_comp_3_b_xfit_all.val,2);
        
        if strcmpi(opt.plotType,'Ecc_SurDepth_DoGs')
            param_comp_1_avg_all_avg = mean(y_param_comp_1_avg_all.val,2);
            param_comp_1_avg_all_sterr = std(y_param_comp_1_avg_all.val,[],2)./sqrt(size(y_param_comp_1_avg_all.val,2));
            
            param_comp_2_avg_all_avg = mean(y_param_comp_2_avg_all.val,2);
            param_comp_2_avg_all_sterr = std(y_param_comp_2_avg_all.val,[],2)./sqrt(size(y_param_comp_2_avg_all.val,2));
            
            param_comp_3_avg_all_avg = mean(y_param_comp_3_avg_all.val,2);
            param_comp_3_avg_all_sterr = std(y_param_comp_3_avg_all.val,[],2)./sqrt(size(y_param_comp_3_avg_all.val,2));

            data_comp_1 = Cond_model{1,1}{1};
            data_comp_2 = Cond_model{2,1}{1};
            data_comp_3 = Cond_model{3,1}{1};
            for roi_idx = 1:num_roi
                %                 figPoint_avg = figure;
                %                 h = bar([param_comp_1_avg_all_avg(:,:,roi_idx),nan,nan],'FaceColor',[0.3010, 0.7450, 0.9330]);hold on;
                %                 bar([nan,param_comp_2_avg_all_avg(:,:,roi_idx),nan],'FaceColor',[0.4 1 0.4]);hold on;
                %                 bar([nan,nan,param_comp_3_avg_all_avg(:,:,roi_idx)],'FaceColor',[1 0.4 0.4]);hold on;
                %                 xlim([0 4]);
                %                 ylim(yl_auc);
                %                 titleall = sprintf('%s', roi_comp) ;
                %                 title(titleall);
                %                 hold off;
                %                 set(h.Parent,'XTickLabel',[{data_comp_1},{data_comp_2},{data_comp_3}]);
                roi_comp = ROI_params.rois{roi_idx};
                figName = sprintf('DoGs surround depth %s',roi_comp);
                figPoint_avg = figure;  set(gcf, 'Color', 'w', 'Position',[100 100 1920/2 1920/2], 'Name', figName);
                errorbar([1,nan,nan],[param_comp_1_avg_all_avg(:,:,roi_idx);nan;nan],...
                    [param_comp_1_avg_all_sterr(:,:,roi_idx);nan; nan]...
                    ,'LineStyle','None','LineWidth',2,'Color',[0.5 0.5 1],'Marker','.','MarkerSize',50);
                hold on;
                errorbar([nan,2,nan],[nan; param_comp_2_avg_all_avg(:,:,roi_idx); nan],...
                    [nan; param_comp_2_avg_all_sterr(:,:,roi_idx); nan]...
                    ,'LineStyle','None','LineWidth',2,'Color',[0.5 1 0.5],'Marker','.','MarkerSize',50);
                errorbar([nan,nan,3],[nan;  nan;param_comp_3_avg_all_avg(:,:,roi_idx)],...
                    [nan; nan; param_comp_3_avg_all_sterr(:,:,roi_idx)]...
                    ,'LineStyle','None','LineWidth',2,'Color',[1 0.5 0.5],'Marker','.','MarkerSize',50);
                xlim([0 4]);
                ylim(yl_auc);
                titleall = sprintf('%s', roi_comp) ;
                title(titleall);
                ylabel('Surround depth');
                hold off;
                set(gca, 'XTick',1:3, 'XTickLabel',{data_comp_1,data_comp_2,data_comp_3})
                
                if opt.saveFig == 1
                    cur_dir = regexprep(yAxis,' ','_');
                    save_dir = fullfile(SZ_rootPath, [sprintf('data/plots/%s/',cur_dir) cur_time '_' opt.plotType '_']);
                    
                    if ~exist(save_dir,'dir')
                        mkdir(save_dir);
                    end
                    filename_avg = fullfile(save_dir,strcat(opt.plotType, roi_comp,'_avg','.png'));
                    saveas(figPoint_avg,filename_avg);
                    
                end
            end
            
        end
        
        param_comp_1_b_data_all_ave_tmp = mean(param_comp_1_data_all.val,2);
        param_comp_1_b_data_all_std = std(param_comp_1_data_all.val,[],2);
        param_comp_1_b_data_all_sem = param_comp_1_b_data_all_std./sqrt(size(param_comp_1_data_all.val,2));
        % Set the thresholds for excluding outliers as mean values > 2
        % standard deviations from the mean
        fprintf('\n(%s) excluding points greater than 2 std from the mean',mfilename);
        
        stdThr_up = param_comp_1_b_data_all_ave_tmp + 2.*param_comp_1_b_data_all_std;
        stdThr_lo = param_comp_1_b_data_all_ave_tmp - 2.*param_comp_1_b_data_all_std;
        tmp = param_comp_1_data_all.val < stdThr_up & param_comp_1_data_all.val > stdThr_lo;
        for cur_roi = 1:size(param_comp_1_data_all.val,3)
            for cur_bin = 1:size(param_comp_1_data_all.val,1)
                param_comp_1_b_data_all_ave_cur = param_comp_1_data_all.val(cur_bin,:,cur_roi);
                tmp_cur = tmp(cur_bin,:,cur_roi);
                param_comp_1_b_data_all_ave(cur_bin,:,cur_roi) = mean(param_comp_1_b_data_all_ave_cur(tmp_cur),2);
            end
        end
        
        param_comp_2_b_data_all_ave_tmp = mean(param_comp_2_data_all.val,2);
        param_comp_2_b_data_all_std = std(param_comp_2_data_all.val,[],2);
        param_comp_2_b_data_all_sem = param_comp_2_b_data_all_std./sqrt(size(param_comp_2_data_all.val,2));
        % Set the thresholds for excluding outliers as mean values > 2
        % standard deviations from the mean
        stdThr_up = param_comp_2_b_data_all_ave_tmp + 2.*param_comp_2_b_data_all_std;
        stdThr_lo = param_comp_2_b_data_all_ave_tmp - 2.*param_comp_2_b_data_all_std;
        tmp = param_comp_2_data_all.val < stdThr_up & param_comp_2_data_all.val > stdThr_lo;
        for cur_roi = 1:size(param_comp_2_data_all.val,3)
            for cur_bin = 1:size(param_comp_2_data_all.val,1)
                param_comp_2_b_data_all_ave_cur = param_comp_2_data_all.val(cur_bin,:,cur_roi);
                tmp_cur = tmp(cur_bin,:,cur_roi);
                param_comp_2_b_data_all_ave(cur_bin,:,cur_roi) = mean(param_comp_2_b_data_all_ave_cur(tmp_cur),2);
            end
        end
        
        param_comp_3_b_data_all_ave_tmp = mean(param_comp_3_data_all.val,2);
        param_comp_3_b_data_all_std = std(param_comp_3_data_all.val,[],2);
        param_comp_3_b_data_all_sem = param_comp_3_b_data_all_std./sqrt(size(param_comp_3_data_all.val,2));
        % Set the thresholds for excluding outliers as mean values > 2
        % standard deviations from the mean
        stdThr_up = param_comp_3_b_data_all_ave_tmp + 2.*param_comp_3_b_data_all_std;
        stdThr_lo = param_comp_3_b_data_all_ave_tmp - 2.*param_comp_3_b_data_all_std;
        tmp = param_comp_3_data_all.val < stdThr_up & param_comp_3_data_all.val > stdThr_lo;
        for cur_roi = 1:size(param_comp_3_data_all.val,3)
            for cur_bin = 1:size(param_comp_3_data_all.val,1)
                param_comp_3_b_data_all_ave_cur = param_comp_3_data_all.val(cur_bin,:,cur_roi);
                tmp_cur = tmp(cur_bin,:,cur_roi);
                param_comp_3_b_data_all_ave(cur_bin,:,cur_roi) = mean(param_comp_3_b_data_all_ave_cur(tmp_cur),2);
            end
        end
        
        fprintf('\n ...DONE');
        
        
        for roi_idx = 1:num_roi
            roi_comp = ROI_params.rois{roi_idx};
            
            param_comp_1_b_data_all_ave_fit = NP_fit(param_comp_1_b_xfit_all_ave(:,:,roi_idx),param_comp_1_b_data_all_ave(:,:,roi_idx),[],param_comp_1_b_xfit_all_ave(:,:,roi_idx));
            param_comp_2_b_data_all_ave_fit = NP_fit(param_comp_2_b_xfit_all_ave(:,:,roi_idx),param_comp_2_b_data_all_ave(:,:,roi_idx),[],param_comp_2_b_xfit_all_ave(:,:,roi_idx));
            param_comp_3_b_data_all_ave_fit = NP_fit(param_comp_3_b_xfit_all_ave(:,:,roi_idx),param_comp_3_b_data_all_ave(:,:,roi_idx),[],param_comp_3_b_xfit_all_ave(:,:,roi_idx));
            
            fprintf('\n (%s) bootstrapping AUC differences for a pair of conditions at a time',mfilename);
            % bootstrap the fit (resample each group 1000 times; refit
            % the curve, recalculate AUC_1 - AUC_2 for each iteration)
            x_data = [param_comp_1_b_xfit_all_ave(:,:,roi_idx), param_comp_2_b_xfit_all_ave(:,:,roi_idx), param_comp_3_b_xfit_all_ave(:,:,roi_idx)];
            y_data = [param_comp_1_b_data_all_ave(:,:,roi_idx), param_comp_2_b_data_all_ave(:,:,roi_idx), param_comp_3_b_data_all_ave(:,:,roi_idx)];
            [auc_diff_HcSzP_bs(:,roi_idx),~,~] = SZ_AUC_bootstrap(x_data(:,[3,1]),y_data(:,[3,1]));
            [auc_diff_HcSzM_bs(:,roi_idx),~,~] = SZ_AUC_bootstrap(x_data(:,[3,2]),y_data(:,[3,2]));
            [auc_diff_SzMSzP_bs(:,roi_idx),~,~] = SZ_AUC_bootstrap(x_data(:,[2,1]),y_data(:,[2,1]));
            
            fprintf('\n ...DONE');
            
            % Plot the fit line
            figName = sprintf('%s vs eccentricity',yAxis);
            figPoint_fit = figure; set(gcf, 'Color', 'w', 'Position',[100 100 1920/2 1080/2], 'Name', figName); hold on;
            
            plot(param_comp_1_b_xfit_all_ave(:,:,roi_idx),param_comp_1_b_data_all_ave(:,:,roi_idx)','.','color',[0.5 0.5 1],'MarkerSize',25); hold on;
            plot(param_comp_2_b_xfit_all_ave(:,:,roi_idx),param_comp_2_b_data_all_ave(:,:,roi_idx)','.','color',[0.5 1 0.5],'MarkerSize',25); hold on;
            plot(param_comp_3_b_xfit_all_ave(:,:,roi_idx),param_comp_3_b_data_all_ave(:,:,roi_idx)','.','color',[1 0.5 0.5],'MarkerSize',25);
            hold on;
            errorbar(param_comp_1_b_xfit_all_ave(:,:,roi_idx),param_comp_1_b_data_all_ave(:,:,roi_idx)',param_comp_1_b_data_all_sem(:,:,roi_idx),'color',[0.5 0.5 1],'MarkerFaceColor','b','MarkerSize',25,'LineStyle','none');hold on;
            errorbar(param_comp_2_b_xfit_all_ave(:,:,roi_idx),param_comp_2_b_data_all_ave(:,:,roi_idx)',param_comp_2_b_data_all_sem(:,:,roi_idx),'color',[0.5 1 0.5],'MarkerFaceColor','b','MarkerSize',25,'LineStyle','none');
            errorbar(param_comp_3_b_xfit_all_ave(:,:,roi_idx),param_comp_3_b_data_all_ave(:,:,roi_idx)',param_comp_3_b_data_all_sem(:,:,roi_idx),'color',[1 0.5 0.5],'MarkerFaceColor','b','MarkerSize',25,'LineStyle','none');
            
            
            titleall = sprintf('%s', roi_comp) ;
            title(titleall);
            xlabel('eccentricity');
            ylbl = sprintf('%s (degrees)',yAxis);
            ylabel(ylbl);
            ylim(yl);
            
            data_comp_1 = Cond_model{1,1}{1};
            data_comp_2 = Cond_model{2,1}{1};
            data_comp_3 = Cond_model{3,1}{1};
            
            hold on;
            plot(param_comp_1_b_xfit_all_ave(:,:,roi_idx),param_comp_1_b_data_all_ave_fit,'color','b','LineWidth',2); hold on;
            plot(param_comp_2_b_xfit_all_ave(:,:,roi_idx),param_comp_2_b_data_all_ave_fit,'color','g','LineWidth',2); hold on;
            plot(param_comp_3_b_xfit_all_ave(:,:,roi_idx),param_comp_3_b_data_all_ave_fit,'color','r','LineWidth',2);
            legend([{data_comp_1},{data_comp_2},{data_comp_3}],'Location','northWest');
            
            %             hold on;
            %             plot(param_comp_1_b_xfit_all_ave(:,:,roi_idx),param_comp_1_b_data_all_ave(:,:,roi_idx)','b--'); hold on;
            %             plot(param_comp_2_b_xfit_all_ave(:,:,roi_idx),param_comp_2_b_data_all_ave(:,:,roi_idx)','g--');hold on;
            %             plot(param_comp_3_b_xfit_all_ave(:,:,roi_idx),param_comp_3_b_data_all_ave(:,:,roi_idx)','r--');
            
            %             hold on;
            %             % Plot the confidence intervals as patch
            %             patch([param_comp_1_b_xfit, fliplr(param_comp_1_b_xfit)], [param_comp_1_b_lower', fliplr(param_comp_1_b_upper')], [0.3010, 0.7450, 0.9330], 'FaceAlpha', 0.5, 'LineStyle','none');
            %             patch([param_comp_2_b_xfit, fliplr(param_comp_2_b_xfit)], [param_comp_2_b_lower', fliplr(param_comp_2_b_upper')], [0.4 1 0.4], 'FaceAlpha', 0.5, 'LineStyle','none');
            %             patch([param_comp_3_b_xfit, fliplr(param_comp_3_b_xfit)], [param_comp_3_b_lower', fliplr(param_comp_3_b_upper')], [1 0.4 0.4], 'FaceAlpha', 0.5, 'LineStyle','none');
            %
            
            %         errorbar(param_comp_1_data.x,param_comp_1_data.y,param_comp_1_data.ysterr,'bo','MarkerFaceColor','b','MarkerSize',MarkerSize);
            %         errorbar(param_comp_2_data.x,param_comp_2_data.y,param_comp_2_data.ysterr,'go','MarkerFaceColor','g','MarkerSize',MarkerSize);
            %         errorbar(param_comp_2_data.x,param_comp_3_data.y,param_comp_3_data.ysterr,'ro','MarkerFaceColor','r','MarkerSize',MarkerSize);
            %
            %         titleall = sprintf('%s', roi_comp) ;
            %         title(titleall);
            %         legend([{data_comp_1},{data_comp_2},{data_comp_3}]);
            %         ylim(yaxislim);
            %         xlim(xaxislim);
            
            hold off;
            
            %% Area under the curve
            
            if opt.AUC
                fprintf('\n Calculating the area under the curve for roi %d \n',roi_idx);
                
                param_comp_1_auc = trapz(param_comp_1_b_xfit_all_ave(:,:,roi_idx),param_comp_1_b_data_all_ave_fit);
                param_comp_2_auc = trapz(param_comp_2_b_xfit_all_ave(:,:,roi_idx),param_comp_2_b_data_all_ave_fit);
                param_comp_3_auc = trapz(param_comp_3_b_xfit_all_ave(:,:,roi_idx),param_comp_3_b_data_all_ave_fit);
                
                auc_diff_HcSzP(:,roi_idx) = param_comp_3_auc - param_comp_1_auc;
                auc_diff_HcSzM(:,roi_idx) = param_comp_3_auc - param_comp_2_auc;
                auc_diff_SzMSzP(:,roi_idx) = param_comp_2_auc - param_comp_1_auc;
                
                % Proportion of differences which is different from the
                % observed difference...
                HcSzP_prop = sum(auc_diff_HcSzP_bs(:,roi_idx)>auc_diff_HcSzP(:,roi_idx))/size(auc_diff_HcSzP_bs(:,roi_idx),1);
                HcSzM_prop = sum(auc_diff_HcSzM_bs(:,roi_idx)>auc_diff_HcSzM(:,roi_idx))/size(auc_diff_HcSzP_bs(:,roi_idx),1);
                SzMSzP_prop = sum(auc_diff_SzMSzP_bs(:,roi_idx)<auc_diff_SzMSzP(:,roi_idx))/size(auc_diff_HcSzP_bs(:,roi_idx),1);
                
                fprintf('\n-----------------------------------\n');
                fprintf('ROI %d - Proportion of diff < 0: HC - SzP - %f \n',roi_idx, HcSzP_prop);
                fprintf('ROI %d - Proportion of diff < 0: HC - SzM - %f \n',roi_idx, HcSzM_prop);
                fprintf('ROI %d - Proportion of diff < 0: SZM - SzP - %f \n',roi_idx, SzMSzP_prop);
                fprintf('\n-----------------------------------\n');
                
                if opt.verbose
                    figPoint_auc_prob_1 = figure;
                    histogram(auc_diff_HcSzP_bs(:,roi_idx)); hold on;
                    plot(repmat(auc_diff_HcSzP(:,roi_idx),[100,1]),0:100-1,'LineWidth',2);
                    
                    figPoint_auc_prob_2 = figure;
                    histogram(auc_diff_HcSzM_bs(:,roi_idx)); hold on;
                    plot(repmat(auc_diff_HcSzM(:,roi_idx),[100,1]),0:100-1,'LineWidth',2);
                    
                    figPoint_auc_prob_3 = figure;
                    histogram(auc_diff_SzMSzP_bs(:,roi_idx)); hold on;
                    plot(repmat(auc_diff_SzMSzP(:,roi_idx),[100,1]),0:100-1,'LineWidth',2);
                end
                
                figPoint_auc = figure;
                h = bar([param_comp_1_auc,nan,nan],'FaceColor',[0.3010, 0.7450, 0.9330]);hold on;
                bar([nan,param_comp_2_auc,nan],'FaceColor',[0.4 1 0.4]);hold on;
                bar([nan,nan,param_comp_3_auc],'FaceColor',[1 0.4 0.4]);hold on;
                xlim([0 4]);
                ylim(yl_auc);
                titleall = sprintf('%s', roi_comp) ;
                title(titleall);
                hold off;
                set(h.Parent,'XTickLabel',[{data_comp_1},{data_comp_2},{data_comp_3}]);
                
                %                 conditions = [Cond_model.conditions(1),Cond_model.conditions(2),Cond_model.conditions(3)];
                %                 figure,
                %                 boxplot([auc_bs_1(:,roi_idx), auc_bs_2(:,roi_idx), auc_bs_3(:,roi_idx)],conditions,'Colors',[0.3010, 0.7450, 0.9330;0.4 1 0.4;1 0.4 0.4]);
                %                 xlabel('conditions');
                %                 ylabel('area under curve');
                %                 title_auc = sprintf('%s : AUC bootstrapped', roi_comp) ;
                %                 title(title_auc);
                
            end
            
            %% Save the plots and results
            if opt.saveFig == 1
                cur_dir = regexprep(yAxis,' ','_');
                save_dir = fullfile(SZ_rootPath, [sprintf('data/plots/%s/',cur_dir) cur_time '_' opt.plotType '_']);
                
                if ~exist(save_dir,'dir')
                    mkdir(save_dir);
                end
                
                if opt.verbose
                    filename_dist_cond1 =  fullfile(save_dir,strcat(opt.plotType,'_dist_cond1','.png'));
                    saveas(figPoint_dist_cond1,filename_dist_cond1);
                    filename_dist_cond2 = fullfile(save_dir,strcat(opt.plotType,'_dist_cond2','.png'));
                    saveas(figPoint_dist_cond2,filename_dist_cond2);
                    filename_dist_cond3 = fullfile(save_dir,strcat(opt.plotType,'_dist_cond3','.png'));
                    saveas(figPoint_dist_cond3,filename_dist_cond3);
                    
                    filename_fit_comp_V1 = fullfile(save_dir,strcat(opt.plotType, roi_comp,'_fit_comp','.png'));
                    saveas(figPoint_fit_comp_V1,filename_fit_comp_V1);
                    filename_fit_comp_V2 = fullfile(save_dir,strcat(opt.plotType, roi_comp,'_fit_comp','.png'));
                    saveas(figPoint_fit_comp_V2,filename_fit_comp_V2);
                    filename_fit_comp_V3 = fullfile(save_dir,strcat(opt.plotType, roi_comp,'_fit_comp','.png'));
                    saveas(figPoint_fit_comp_V3,filename_fit_comp_V3);
                    
                    filename_fit = fullfile(save_dir,strcat(opt.plotType, roi_comp,'.png'));
                    saveas(figPoint_fit,filename_fit);
                    
                    filename_auc = fullfile(save_dir,strcat(opt.plotType, roi_comp,'_AUC','.png'));
                    saveas(figPoint_auc,filename_auc);
                    
                    filename_auc_prob_1 = fullfile(save_dir,strcat(opt.plotType, roi_comp,'_AUC_prob_1','.png'));
                    saveas(figPoint_auc_prob_1,filename_auc_prob_1);
                    
                    filename_auc_prob_2 = fullfile(save_dir,strcat(opt.plotType, roi_comp,'_AUC_prob_2','.png'));
                    saveas(figPoint_auc_prob_2,filename_auc_prob_2);
                    
                    filename_auc_prob_3 = fullfile(save_dir,strcat(opt.plotType, roi_comp,'_AUC_prob_3','.png'));
                    saveas(figPoint_auc_prob_3,filename_auc_prob_3);
                    
                end
            end
            
            
        end
        
        
        
        
        if opt.saveRes == 1
            % save the results
            cur_dir = regexprep(yAxis,' ','_');
            save_dir = fullfile(SZ_rootPath, [sprintf('data/results/%s/',opt.plotType) cur_time '_' opt.plotType]);
            mkdir(save_dir);
            
            filename_fit = fullfile(save_dir,strcat('results','.mat'));
            save(filename_fit,'Cond_model','ROI_params');
        end
        
        
    case 'alltog'
        
        %% Plots
        % Plot raw data and the fits
        param_comp_diff_data_cen_allroi = nan(num_roi,1);
        param_comp_diff_data_cen_allroi_up = nan(num_roi,1);
        param_comp_diff_data_cen_allroi_lo = nan(num_roi,1);
        param_comp_diff_data_cen_allroi_bin = nan(num_roi,1);
        
        param_comp_diff_data_auc_allroi = nan(num_roi,1);
        
        for roi_idx = 1:num_roi
            
            roi_comp = ROI_params.rois{roi_idx};
            
            data_comp_1 = Cond_model{1,1}{1};
            data_comp_2 = Cond_model{2,1}{1};
            data_comp_3 = Cond_model{3,1}{1};
            
            %   data_comp_1(data_comp_1 == '_') = ' ';
            %data_comp_2(data_comp_2 == '_') = ' ';
            
            % Choose the pRF parameters to compare
            switch plotType
                
                case 'Ecc_Sig'
                    x_param_comp_1 = [];
                    x_param_comp_2 = [];
                    x_param_comp_3 = [];
                    
                    y_param_comp_1 = [];
                    y_param_comp_2 = [];
                    y_param_comp_3 = [];
                    
                    ve_comp_1 = [];
                    ve_comp_2 = [];
                    ve_comp_3 = [];
                    
                    
                    num_sub_comp_1 = Cond_model.numSubjects(1);
                    for sub_idx= 1:num_sub_comp_1
                        x_param_comp_1 = [x_param_comp_1 Cond_model{1,roi_comp}{1,sub_idx}.ecc];
                        y_param_comp_1 = [y_param_comp_1 Cond_model{1,roi_comp}{1,sub_idx}.sigma];
                        
                        ve_comp_1 = [ve_comp_1 Cond_model{1,roi_comp}{1,sub_idx}.varexp];
                    end
                    
                    num_sub_comp_2 = Cond_model.numSubjects(2);
                    for sub_idx= 1:num_sub_comp_2
                        x_param_comp_2 = [x_param_comp_2 Cond_model{2,roi_comp}{1,sub_idx}.ecc];
                        y_param_comp_2 = [y_param_comp_2 Cond_model{2,roi_comp}{1,sub_idx}.sigma];
                        
                        ve_comp_2 = [ve_comp_2 Cond_model{2,roi_comp}{1,sub_idx}.varexp];
                    end
                    
                    num_sub_comp_3 = Cond_model.numSubjects(3);
                    for sub_idx= 1:num_sub_comp_3
                        x_param_comp_3 = [x_param_comp_3 Cond_model{3,roi_comp}{1,sub_idx}.ecc];
                        y_param_comp_3 = [y_param_comp_3 Cond_model{3,roi_comp}{1,sub_idx}.sigma];
                        
                        ve_comp_3 = [ve_comp_3 Cond_model{3,roi_comp}{1,sub_idx}.varexp];
                    end
                    
                    % Axis limits for plotting
                    xaxislim = [0 10.21];
                    yaxislim = [0 6];
                    
                    % x range values for fitting
                    xfit_range = opt.eccThr;
                    
                case 'Ecc_SurSize_DoGs'
                    x_param_comp_1 = [];
                    x_param_comp_2 = [];
                    x_param_comp_3 = [];
                    
                    y_param_comp_1 = [];
                    y_param_comp_2 = [];
                    y_param_comp_3 = [];
                    
                    ve_comp_1 = [];
                    ve_comp_2 = [];
                    ve_comp_3 = [];
                    
                    
                    num_sub_comp_1 = Cond_model.numSubjects(1);
                    for sub_idx= 1:num_sub_comp_1
                        idx_surSizeGr0_p1 = Cond_model{1,roi_comp}{1,sub_idx}.DoGs_surroundSize ~= 0;
                        
                        x_param_comp_1 = [x_param_comp_1 Cond_model{1,roi_comp}{1,sub_idx}.ecc(idx_surSizeGr0_p1)];
                        y_param_comp_1 = [y_param_comp_1 Cond_model{1,roi_comp}{1,sub_idx}.DoGs_surroundSize(idx_surSizeGr0_p1)];
                        
                        ve_comp_1 = [ve_comp_1 Cond_model{1,roi_comp}{1,sub_idx}.varexp(idx_surSizeGr0_p1)];
                    end
                    
                    num_sub_comp_2 = Cond_model.numSubjects(2);
                    for sub_idx= 1:num_sub_comp_2
                        idx_surSizeGr0_p2 = Cond_model{2,roi_comp}{1,sub_idx}.DoGs_surroundSize ~= 0;
                        
                        x_param_comp_2 = [x_param_comp_2 Cond_model{2,roi_comp}{1,sub_idx}.ecc(idx_surSizeGr0_p2)];
                        y_param_comp_2 = [y_param_comp_2 Cond_model{2,roi_comp}{1,sub_idx}.DoGs_surroundSize(idx_surSizeGr0_p2)];
                        
                        ve_comp_2 = [ve_comp_2 Cond_model{2,roi_comp}{1,sub_idx}.varexp(idx_surSizeGr0_p2)];
                    end
                    
                    num_sub_comp_3 = Cond_model.numSubjects(3);
                    for sub_idx= 1:num_sub_comp_3
                        idx_surSizeGr0_p3 = Cond_model{3,roi_comp}{1,sub_idx}.DoGs_surroundSize ~= 0;
                        
                        x_param_comp_3 = [x_param_comp_3 Cond_model{3,roi_comp}{1,sub_idx}.ecc(idx_surSizeGr0_p3)];
                        y_param_comp_3 = [y_param_comp_3 Cond_model{3,roi_comp}{1,sub_idx}.DoGs_surroundSize(idx_surSizeGr0_p3)];
                        
                        ve_comp_3 = [ve_comp_3 Cond_model{3,roi_comp}{1,sub_idx}.varexp(idx_surSizeGr0_p3)];
                    end
                    
                    % Axis limits for plotting
                    xaxislim = [0 inf];
                    yaxislim = [0 inf];
                    
                    % x range values for fitting
                    xfit_range = opt.eccThr;
                    
                case 'Pol_Sig'
                    x_param_comp_1 = Cond_model{1,roi_comp}{1}.pol;
                    x_param_comp_2 = Cond_model{2,roi_comp}{1}.pol;
                    
                    y_param_comp_1 = Cond_model{1,roi_comp}{1}.sigma;
                    y_param_comp_2 = Cond_model{2,roi_comp}{1}.sigma;
                    
                    % Axis limits for plotting
                    xaxislim = [0 2*pi];
                    yaxislim = [0 10];
                    
                    % x range values for fitting
                    Pol_Thr_low = 0;
                    Pol_Thr = 2*pi;
                    xfit_range = [Pol_Thr_low Pol_Thr];
                    
                case 'X_Sig'
                    x_param_comp_1 = Cond_model{1,roi_comp}{1}.x;
                    x_param_comp_2 = Cond_model{2,roi_comp}{1}.x;
                    
                    y_param_comp_1 = Cond_model{1,roi_comp}{1}.sigma;
                    y_param_comp_2 = Cond_model{2,roi_comp}{1}.sigma;
                case 'Y_Sig'
                    x_param_comp_1 = Cond_model{1,roi_comp}{1}.y;
                    x_param_comp_2 = Cond_model{2,roi_comp}{1}.y;
                    
                    y_param_comp_1 = Cond_model{1,roi_comp}{1}.sigma;
                    y_param_comp_2 = Cond_model{2,roi_comp}{1}.sigma;
            end
            
            %%
            %---------- plot Raw data----------------%
            
            fprintf('\n Plotting raw data for roi %d \n',roi_idx);
            figName = 'prf size vs eccentricity';
            figPoint_raw = figure;set(gcf, 'Color', 'w', 'Position',[100 100 1920/2 1080/2], 'Name', figName);hold on;
            plot(x_param_comp_1,y_param_comp_1,'.','color',[0.3010, 0.7450, 0.9330]);
            hold on; plot(x_param_comp_2,y_param_comp_2,'.','color',[0.4 1 0.4]);
            hold on; plot(x_param_comp_3,y_param_comp_3,'.','color',[1 0.4 0.4]);
            % figure attributes
            %titleName = strcat(Cond_model{1,1},'and',Cond_model{2,1});
            titleall = sprintf('%s', roi_comp) ;
            title(titleall);
            %legend([{data_comp_1},{data_comp_2},{data_comp_3}]);
            xlabel('eccentricity (degrees)');
            ylabel('pRF size (degrees)');
            
            ylim(yaxislim);
            xlim(xaxislim);
            
            %hold off;
            fprintf('\n Done \n');
            
            %%
            
            %---------- Plot the fit line and mean values in the bins -----------%
            
            fprintf('\n Calculating slope and intercept for the best fitting line for the conditions for roi %d \n',roi_idx)
            
            % Do a linear regression of the two parameters weighted with the variance explained
            
            xfit = linspace(xfit_range(1),xfit_range(2),8)';
            [param_comp_1_yfit] = NP_fit(x_param_comp_1,y_param_comp_1,ve_comp_1,xfit);
            [param_comp_2_yfit] = NP_fit(x_param_comp_2,y_param_comp_2,ve_comp_2,xfit);
            [param_comp_3_yfit] = NP_fit(x_param_comp_3,y_param_comp_3,ve_comp_3,xfit);
            
            
            % Plot the fit line
            figPoint_fit = figure; set(gcf, 'Color', 'w', 'Position',[100 100 1920/2 1080/2], 'Name', figName);hold on;
            plot(xfit,param_comp_1_yfit','b','LineWidth',3); hold on;
            plot(xfit,param_comp_2_yfit','g','LineWidth',3);hold on;
            plot(xfit,param_comp_3_yfit','r','LineWidth',3);
            
            fprintf('Binning and bootstrapping the data for roi: %s \n',roi_comp)
            
            % Bootstrap the data and bin the x parameter
            [param_comp_1_data,param_comp_1_b_xfit,param_comp_1_b_upper,param_comp_1_b_lower] = NP_bin_param(x_param_comp_1,y_param_comp_1,ve_comp_1,xfit_range);
            [param_comp_2_data,param_comp_2_b_xfit,param_comp_2_b_upper,param_comp_2_b_lower] = NP_bin_param(x_param_comp_2,y_param_comp_2,ve_comp_2,xfit_range);
            [param_comp_3_data,param_comp_3_b_xfit,param_comp_3_b_upper,param_comp_3_b_lower] = NP_bin_param(x_param_comp_3,y_param_comp_3,ve_comp_3,xfit_range);
            
            %     % Plot the fit line
            %     figPoint_fit = figure;
            %     plot(param_comp_1_b_xfit,param_comp_1_data.y,'b'); hold on;
            %     plot(param_comp_2_b_xfit,param_comp_2_data.y,'g');hold on;
            %     plot(param_comp_3_b_xfit,param_comp_3_data.y,'r');
            
            hold on;
            % Plot the confidence intervals as patch
            patch([param_comp_1_b_xfit, fliplr(param_comp_1_b_xfit)], [param_comp_1_b_lower', fliplr(param_comp_1_b_upper')], [0.3010, 0.7450, 0.9330], 'FaceAlpha', 0.5, 'LineStyle','none');
            patch([param_comp_2_b_xfit, fliplr(param_comp_2_b_xfit)], [param_comp_2_b_lower', fliplr(param_comp_2_b_upper')], [0.4 1 0.4], 'FaceAlpha', 0.5, 'LineStyle','none');
            patch([param_comp_3_b_xfit, fliplr(param_comp_3_b_xfit)], [param_comp_3_b_lower', fliplr(param_comp_3_b_upper')], [1 0.4 0.4], 'FaceAlpha', 0.5, 'LineStyle','none');
            %
            %             plot(param_comp_1_b_xfit,param_comp_1_b_upper,'b--');
            %             plot(param_comp_1_b_xfit,param_comp_1_b_lower,'b--');
            %
            %             plot(param_comp_2_b_xfit,param_comp_2_b_upper,'g--');
            %             plot(param_comp_2_b_xfit,param_comp_2_b_lower,'g--');
            %
            %             plot(param_comp_3_b_xfit,param_comp_3_b_upper,'r--');
            %             plot(param_comp_3_b_xfit,param_comp_3_b_lower,'r--');
            
            hold on;
            errorbar(param_comp_1_data.x,param_comp_1_data.y,param_comp_1_data.ysterr,'bo','MarkerFaceColor','b','MarkerSize',MarkerSize);
            errorbar(param_comp_2_data.x,param_comp_2_data.y,param_comp_2_data.ysterr,'go','MarkerFaceColor','g','MarkerSize',MarkerSize);
            errorbar(param_comp_2_data.x,param_comp_3_data.y,param_comp_3_data.ysterr,'ro','MarkerFaceColor','r','MarkerSize',MarkerSize);
            
            titleall = sprintf('%s', roi_comp) ;
            title(titleall);
            legend([{data_comp_1},{data_comp_2},{data_comp_3}]);
            ylim(yaxislim);
            xlim(xaxislim);
            
            %hold off;
            
            %%
            
            %------- Plot the central values------------%
            % Calculate the central value from the fit
            % Bootstrap the data and bin the x parameter
            
            fprintf('\n Binning the data, bootstrapping the bins and caluculating the median, 97.5 and 2.5 percent confidence interval for roi %d \n',roi_idx)
            %
            fprintf('\n ************************** \n  Not finished yet \n ************************** \n');
            
            
            
            %     param_comp_1_data_cen = NP_central_val(param_comp_1_b_xfit,param_comp_1_yfit,param_comp_1_b_upper,param_comp_1_b_lower,xfit);
            % %    param_comp_2_data_cen = NP_central_val(param_comp_2_b_xfit,param_comp_2_yfit,param_comp_2_b_upper,param_comp_2_b_lower,xfit);
            %
            %     figPoint_cen = figure(3);
            %     h = bar([param_comp_1_data_cen.y,nan],'FaceColor',[0 0 1]);hold on;
            % %    bar([nan,param_comp_2_data_cen.y],'FaceColor',[0 1 0]);hold on;
            %  %   errorbar([1,2],[param_comp_1_data_cen.y,param_comp_2_data_cen.y],[param_comp_1_data_cen.y-param_comp_1_data_cen.lo,param_comp_2_data_cen.y-param_comp_2_data_cen.lo],[param_comp_1_data_cen.up-param_comp_1_data_cen.y,param_comp_2_data_cen.up-param_comp_2_data_cen.y],'k','LineStyle','none');
            %     xlim([0 3]);
            %     ylim(yaxislim);
            %     titleall = sprintf('%s', roi_comp) ;
            %     title(titleall);
            %     hold off;
            %  %   set(h.Parent,'XTickLabel',[{data_comp_1},{data_comp_2}]);
            %
            %     % Scrambled - Natural (all rois)
            %     param_comp_diff_data_cen_allroi(roi_idx) = param_comp_2_data_cen.y - param_comp_1_data_cen.y;
            %
            %
            %
            %     % Calculate the difference between sigma values, bin them and bootstrap across bins
            %     assertEqual(x_param_comp_1,x_param_comp_2);
            %     x_param_comp = x_param_comp_1;
            %
            %     [~,param_comp_b_xfit_diff,param_comp_b_upper_diff,param_comp_b_lower_diff,param_comp_b_y] = NP_bin_param(x_param_comp,((y_param_comp_2-y_param_comp_1)./((y_param_comp_2+y_param_comp_1)./2)),[],xfit);
            %
            %     param_comp_data_diff_cen = NP_central_val(param_comp_b_xfit_diff,param_comp_b_y,param_comp_b_upper_diff,param_comp_b_lower_diff,xfit);
            %     param_comp_diff_data_cen_allroi_bin(roi_idx,1) = param_comp_data_diff_cen.y;
            %     param_comp_diff_data_cen_allroi_up(roi_idx,1) = param_comp_data_diff_cen.up;
            %     param_comp_diff_data_cen_allroi_lo(roi_idx,1) = param_comp_data_diff_cen.lo;
            
            %%
            %---------Plot the Area under curve-----------%
            
            fprintf('\n Calculating the area under the curve for roi %d \n',roi_idx);
            
            fprintf('\n ************************** \n  Not finished yet \n ************************** \n');
            
            %     param_comp_1_auc = trapz(xfit_plot,param_comp_1_yfit);
            %     param_comp_2_auc = trapz(xfit_plot,param_comp_2_yfit);
            %
            %     figPoint_auc = figure(4);
            %     h = bar([param_comp_1_auc,nan],'FaceColor',[0 0 1]);hold on;
            %     bar([nan,param_comp_2_auc],'FaceColor',[0 1 0]);hold on;
            %     xlim([0 3]);
            %     ylim([0 15]);
            %     titleall = sprintf('%s', roi_comp) ;
            %     title(titleall);
            %     hold off;
            %     set(h.Parent,'XTickLabel',[{data_comp_1},{data_comp_2}]);
            %
            %     % Scrambled - Natural (all rois)
            %     param_comp_diff_data_auc_allroi(roi_idx) = param_comp_2_auc - param_comp_1_auc;
            
            
            %%
            
            %-----------------------------------------
            fprintf('\n Saving the plots for roi %d \n',roi_idx)
            
            if opt.saveFig == 1
                filename_raw = strcat(save_dir, '/', 'plot', roi_comp,'raw', '.png');
                saveas(figPoint_raw,filename_raw);
                
                filename_fit = strcat(save_dir, '/', 'plot', roi_comp,'fit', '.png');
                saveas(figPoint_fit,filename_fit);
                
                filename_cen = strcat(save_dir, '/', 'plot', roi_comp,'central', '.png');
                saveas(figPoint_cen,filename_cen);
                
                filename_auc = strcat(save_dir, '/', 'plot', roi_comp,'auc', '.png');
                saveas(figPoint_auc,filename_auc);
                
            end
            
        end
        
        % close all;
        % fprintf('Plotting the difference in central values');
        %
        % % Scrambled - Natural
        % figPoint_cen_diff = figure(31);
        % h = bar(param_comp_diff_data_cen_allroi_bin,'FaceColor',[0 0 1]);hold on;
        % errorbar([1:num_roi]',param_comp_diff_data_cen_allroi_bin,param_comp_diff_data_cen_allroi_bin-param_comp_diff_data_cen_allroi_lo,param_comp_diff_data_cen_allroi_up-param_comp_diff_data_cen_allroi_bin,'k','LineStyle','none');
        % %xlim([0 3]);
        % ylim([-0.25 0.5]);
        % titleall = sprintf('Central value difference') ;
        % title(titleall);
        % set(h.Parent,'XTickLabel',rois);
        % hold off;
        %
        %
        % % Scrambled - Natural
        % figPoint_auc_diff = figure(41);
        % h = bar(param_comp_diff_data_auc_allroi,'FaceColor',[0 0 1]);
        % %xlim([0 3]);
        % ylim([-0.2 0.5]);
        % titleall = sprintf('AUC difference') ;
        % title(titleall);
        % hold off;
        % set(h.Parent,'XTickLabel',rois);
        
        if opt.saveFig == 1
            filename_cen_diff = strcat(save_dir, '/', 'plot','cen_diff', '.png');
            saveas(figPoint_cen_diff,filename_cen_diff);
            
            filename_auc_diff = strcat(save_dir, '/', 'plot','auc_diff', '.png');
            saveas(figPoint_auc_diff,filename_auc_diff);
        end
        %% Save the plots and results
        
        if opt.saveRes == 1
            % save the results
            save(strcat(save_dir,'/','results.mat'),'Cond_model','ROI_params');
            
        end
        
        %close all;
end
fprintf('\n(%s): Done!', mfilename)

end

