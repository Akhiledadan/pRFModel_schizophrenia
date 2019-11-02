function SZ_pRFsizeEcc(modelData,opt,dirPth)
% Average the prf parameter value from the subjects first and then
% Average the mean value from all the subjects
% x range values for fitting

%conditions = {'Averages'};
conditions = opt.conditions;
numCond = length(conditions);

% Plot params
MarkerSize = 3;

rois = opt.rois;
num_roi = length(rois);
roi_fname = cell(num_roi,numCond,1);

xfit_range = [opt.eccThr(1) opt.eccThr(2)];
xfit = linspace(xfit_range(1),xfit_range(2),8)';
for roi_idx = 1:num_roi
    roi_comp = opt.rois{roi_idx};
    
    % --------------------------------
    % figure 1. Distribution of points
    % --------------------------------
    if opt.verbose
        figName = sprintf('%s vs eccentricity','sigma');
        figPoint_dist_cond1 = figure(1); set(gcf, 'Color', 'w', 'Position',[100 100 1920 1080], 'Name', figName);
        figPoint_dist_cond2 = figure(10); set(gcf, 'Color', 'w', 'Position',[100 100 1920 1080], 'Name', figName);
        figPoint_dist_cond3 = figure(100); set(gcf, 'Color', 'w', 'Position',[100 100 1920 1080], 'Name', figName);
        
        figName = sprintf('%s vs eccentricity','sigma');
        figPoint_fit_comp_cond1 = figure(10001); set(gcf, 'Color', 'w', 'Position',[100 100 1920 1080], 'Name', figName);        
        figPoint_fit_comp_cond2 = figure(10002); set(gcf, 'Color', 'w', 'Position',[100 100 1920 1080], 'Name', figName);        
        figPoint_fit_comp_cond3 = figure(10003); set(gcf, 'Color', 'w', 'Position',[100 100 1920 1080], 'Name', figName); 
        
        figName = sprintf('%s vs eccentricity','sigma');
        figPoint_ve_cond1 = figure(1001); set(gcf, 'Color', 'w', 'Position',[100 100 1920 1080], 'Name', figName);
        figPoint_ve_cond2 = figure(1002); set(gcf, 'Color', 'w', 'Position',[100 100 1920 1080], 'Name', figName);
        figPoint_ve_cond3 = figure(1003); set(gcf, 'Color', 'w', 'Position',[100 100 1920 1080], 'Name', figName);
    end
    
    for cond_idx = 1:numCond
        cur_cond = conditions{cond_idx};
        switch cur_cond
            case 'ptH'
                subjects = opt.subjects.ptH;
            case 'ptNH'
                subjects = opt.subjects.ptNH;
            case 'HC'
                subjects = opt.subjects.HC;
        end
        
        numSub = length(subjects);
        
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
                        idx_surSizeGr0_p1 = modelData.modelInfo_thr{cond_idx,sub_idx,roi_idx}.sigma ~= 0;
                        x_param_comp_1 = modelData.modelInfo_thr{cond_idx,sub_idx,roi_idx}.ecc(idx_surSizeGr0_p1);
                        y_param_comp_1 = modelData.modelInfo_thr{cond_idx,sub_idx,roi_idx}.sigma(idx_surSizeGr0_p1);
                        ve_comp_1 = modelData.modelInfo_thr{cond_idx,sub_idx,roi_idx}.varexp(idx_surSizeGr0_p1);
                        
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
                                figure(10001);subplot(n_rows,n_cols,sub_idx); hold on;
                                plot(xfit,param_comp_1_yfit,'color',[0.4 0.4 1],'LineWidth',3,'color',[0.5+(roi_idx/10), 0.5, 1-(roi_idx/10)]); hold on;
                            end
                            
                            % figure 2. fit to individual data points for every subject and every roi
                            figure(1001);subplot(n_rows,n_cols,sub_idx); hold on;
                            plot(x_param_comp_1,ve_comp_1,'.','color',[0.5+(roi_idx/10), 0.5, 1-(roi_idx/10)],'MarkerSize',10); hold on;
                            
             
                        end
                        
                    elseif cond_idx==2
                        idx_surSizeGr0_p2 = modelData.modelInfo_thr{cond_idx,sub_idx,roi_idx}.sigma ~= 0;
                        x_param_comp_2 = modelData.modelInfo_thr{cond_idx,sub_idx,roi_idx}.ecc(idx_surSizeGr0_p2);
                        y_param_comp_2 = modelData.modelInfo_thr{cond_idx,sub_idx,roi_idx}.sigma(idx_surSizeGr0_p2);
                        ve_comp_2 = modelData.modelInfo_thr{cond_idx,sub_idx,roi_idx}.varexp(idx_surSizeGr0_p2);
                        
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
                                figure(10002);subplot(n_rows,n_cols,sub_idx); hold on;
                                plot(xfit,param_comp_2_yfit,'color',[0.4 1 0.4],'LineWidth',3,'color',[0.5+(roi_idx/10) 1-(roi_idx/10) 0.5+(roi_idx/10)]); hold on;
                            end
                            % figure 2. fit to individual data points for every subject and every roi
                            figure(1002);subplot(n_rows,n_cols,sub_idx); hold on;
                            plot(x_param_comp_2,ve_comp_2,'.','color',[0.5+(roi_idx/10) 1-(roi_idx/10) 0.5+(roi_idx/10)],'MarkerSize',10); hold on;
                            
                        end
                        
                    elseif cond_idx==3
                        idx_surSizeGr0_p3 = modelData.modelInfo_thr{cond_idx,sub_idx,roi_idx}.sigma ~= 0;
                        x_param_comp_3 = modelData.modelInfo_thr{cond_idx,sub_idx,roi_idx}.ecc(idx_surSizeGr0_p3);
                        y_param_comp_3 = modelData.modelInfo_thr{cond_idx,sub_idx,roi_idx}.sigma(idx_surSizeGr0_p3);
                        ve_comp_3 = modelData.modelInfo_thr{cond_idx,sub_idx,roi_idx}.varexp(idx_surSizeGr0_p3);
                        
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
                                figure(10003);subplot(n_rows,n_cols,sub_idx); hold on;
                                plot(xfit,param_comp_3_yfit,'color',[1 0.4 0.4],'LineWidth',3,'color',[1-(roi_idx/10) 0.5+(roi_idx/10) 0.5]); hold on;
                            end
                            % figure 2. fit to individual data points for every subject and every roi
                            figure(1003);subplot(n_rows,n_cols,sub_idx); hold on;
                            plot(x_param_comp_3,ve_comp_3,'.','color',[1-(roi_idx/10) 0.5+(roi_idx/10) 0.5],'MarkerSize',10); hold on;
                            
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
     figure(10001);legend(rois);
    figure(10002);legend(rois);
    figure(10003);legend(rois);
end


if opt.saveFig
    
    dirPth.saveDirSizeSigma = fullfile(dirPth.saveDirFig,strcat('expAnalysis/',opt.modelType,'_',opt.plotType));
    if ~exist('saveDir','dir')
        mkdir(dirPth.saveDirSizeSigma);
    end
    
    % save prf size vs eccentricity distribution
    filename_dist_cond1 =  fullfile(dirPth.saveDirSizeSigma,strcat(opt.plotType,'_dist_cond1','.png'));
    saveas(figPoint_dist_cond1,filename_dist_cond1);
    filename_dist_cond2 = fullfile(dirPth.saveDirSizeSigma,strcat(opt.plotType,'_dist_cond2','.png'));
    saveas(figPoint_dist_cond2,filename_dist_cond2);
    filename_dist_cond3 = fullfile(dirPth.saveDirSizeSigma,strcat(opt.plotType,'_dist_cond3','.png'));
    saveas(figPoint_dist_cond3,filename_dist_cond3);
    
    % save fit plots
    filename_fit_comp_cond1 = fullfile(dirPth.saveDirSizeSigma,strcat(opt.plotType,'_fit_comp_cond1','.png'));
    saveas(figPoint_fit_comp_cond1,filename_fit_comp_cond1);
    
    filename_fit_comp_cond2 = fullfile(dirPth.saveDirSizeSigma,strcat(opt.plotType,'_fit_comp_cond2','.png'));
    saveas(figPoint_fit_comp_cond2,filename_fit_comp_cond2);
    
    filename_fit_comp_cond3 = fullfile(dirPth.saveDirSizeSigma,strcat(opt.plotType,'_fit_comp_cond3','.png'));
    saveas(figPoint_fit_comp_cond3,filename_fit_comp_cond3);
    

    % save variance explained plots
    filename_ve_cond1 = fullfile(dirPth.saveDirSizeSigma,strcat(opt.plotType,'_ve_cond1','.png'));
    saveas(figPoint_ve_cond1,filename_ve_cond1);
    
    filename_ve_cond2 = fullfile(dirPth.saveDirSizeSigma,strcat(opt.plotType,'_ve_cond2','.png'));
    saveas(figPoint_ve_cond2,filename_ve_cond2);
    
    filename_ve_cond3 = fullfile(dirPth.saveDirSizeSigma,strcat(opt.plotType,'_ve_cond3','.png'));
    saveas(figPoint_ve_cond3,filename_ve_cond3);
    
end

end