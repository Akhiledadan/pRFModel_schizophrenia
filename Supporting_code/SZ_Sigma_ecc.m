function SZ_Sigma_ecc
% SZ_Sigma_ecc - Plots Sigma vs eccentricity for the pRF fits to compare
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
opt = getOpts;

%% Initializing required variables

% Plot params
MarkerSize = 3;

% Select the ROIs
rois = {'V1';'V2';'V3'};

% pRF parameters to be compared
if ~exist('plotType','var') || isempty(plotType)
    plotType = opt.plotType;
end

% Define the different conditions to be compared
conditions = [{'ptwH+'};{'ptwH-'};{'HC'}];

dataType = 'Averages';

%%

%conditions = {'Averages'};
numCond = length(conditions);

% Make the directory to save results
if opt.saveFig || opt.saveRes
    cur_time = datestr(now);
    cur_time(cur_time == ' ' | cur_time == ':' | cur_time == '-') = '_';
    save_dir = fullfile(main_dir, ['/Results/Results' '_' cur_time '_' plotType]);
    mkdir(save_dir);
end

% Load types of model to compare
model_file = cell(numCond,1);
coords_file = cell(numCond,1);
meanMap_file = cell(numCond,1);

num_roi = length(rois);
roi_fname = cell(num_roi,numCond,1);

for cond_idx = 1:numCond
    
    cur_cond = conditions{cond_idx};
    switch cur_cond
        case 'ptwH+'
            % subjects = [{'100'},{'101'},{'102'},{'103'},{'104'},{'106'},{'107'},{'108'},{'109'},{'110'},{'111'},{'112'},{'114'}];
            subjects = [{'100'}];
            
        case 'ptwH-'
            subjects = [{'200'}];
            
        case 'HC'
            subjects = [{'301'}];
    end
    
    for sub_idx = 1:length(subjects)
        dirPth.sub_sess_path = fullfile(dirPth.mrvDirPth,'/',subjects{sub_idx},'/');
        dirPth.roi_path = strcat(dirPth.sub_sess_path,'Anatomy/ROIs/');
        dirPth.model_path = strcat(dirPth.sub_sess_path,'Gray/Averages');
        dirPth.coords_path = strcat(dirPth.sub_sess_path,'Gray/');
        dirPth.mean_path = strcat(dirPth.sub_sess_path,'Gray/Averages/');
        
        % Load coordinate file
        coordsFile = fullfile(dirPth.coords_path,'coords.mat');
        %load(coordsFile);
        
        % Mean map
        meanMapFile = fullfile(dirPth.mean_path,'meanMap.mat');
        %Mmap = load(meanFile);
        
        if strcmpi(opt.modelType,'DoGs')
            model_fname =  dir(fullfile(dirPth.model_path,'SZ_DoGs-fFit.mat'));
        elseif strcmpi(opt.modelType,'2DGaussian')
            model_fname =  dir(fullfile(dirPth.model_path,'SZ_2DGaussian-fFit.mat'));
        end
        
        if length(model_fname)>1
            warning('more than one model fit, selecting the latest one. Select a different model otherwise')
            % Update this with a code to determine the date of model and
            % selecting the latest
        end
        
        model_file{cond_idx,sub_idx} = fullfile(dirPth.model_path,model_fname.name);
        coords_file{cond_idx,sub_idx} = coordsFile;
        meanMap_file{cond_idx,sub_idx} = meanMapFile;
        
        % Select ROIs
        
        for roi_idx = 1:num_roi
            roi_fname{roi_idx,cond_idx,sub_idx} = fullfile(dirPth.roi_path,strcat(rois{roi_idx},'.mat'));
        end
        
    end
end

% Create a table with different conditions and their corresponding model
% files
Cond_model = table(conditions,model_file,coords_file,meanMap_file);

% % Select ROIs
% num_roi = length(rois);
% roi_fname = cell(num_roi,1);
% for roi_idx = 1:num_roi
%     roi_fname{roi_idx,1} = fullfile(paths.roi_path,strcat(rois{roi_idx},'.mat'));
% end

% Table with different ROIs and their corresponding file paths
ROI_params = table(rois,roi_fname);

%% calculating pRF parameters to compare - this has to be done for each subject separately.

% preallocate variables

model_data = cell(1);
index_thr_tmp = cell(1);
model_data_thr = cell(1);

numSubjects = nan(numCond,1);
for cond_idx = 1:numCond
    
    numSub = sum(~cellfun(@isempty,Cond_model.model_file(cond_idx,:)),2); % check if subjects field is empty
    numSubjects(cond_idx,1) = numSub;
    
    for sub_idx = 1:numSub
        
        % Load coordinate file
        coordsFile = Cond_model.coords_file{cond_idx,sub_idx};
        load(coordsFile);
        
        % Mean map
        meanFile = Cond_model.meanMap_file{cond_idx,sub_idx};
        Mmap = load(meanFile);
        
        % Determine the voxels for different ROIs and the corresponding prf
        % parameters
        for roi_idx = 1:num_roi
            %Load the current roi
            load(ROI_params.roi_fname{roi_idx,cond_idx,sub_idx});
            
            % find the indices of the voxels from the ROI intersecting with all the voxels
            [~, indices_mean] = intersect(coords', ROI.coords', 'rows' );
            mean_map = Mmap.map{1}(1,indices_mean);
            
            % Current model parameters- contains x,y, sigma, from current
            % condition and current subject and for the current ROI
            model_data(cond_idx,sub_idx,roi_idx) = GetInfoModel(Cond_model.model_file{cond_idx,sub_idx},coordsFile,ROI_params.roi_fname{roi_idx,cond_idx,sub_idx});
            
            % Difference of gaussians parameters
            rm = load(Cond_model.model_file{cond_idx});
            if strcmpi(opt.modelType,'DoGs')
                [fwhmax,surroundSize,fwhmin_first, fwhmin_second, diffwhmin] = rmGetDoGFWHM(rm.model{1},{indices_mean});
                model_data{cond_idx,sub_idx,roi_idx}.DoGs_fwhmax = fwhmax;
                model_data{cond_idx,sub_idx,roi_idx}.DoGs_surroundSize = surroundSize;
                model_data{cond_idx,sub_idx,roi_idx}.DoGs_fwhmin_first = fwhmin_first;
                model_data{cond_idx,sub_idx,roi_idx}.DoGs_fwhmin_second = fwhmin_second;
                model_data{cond_idx,sub_idx,roi_idx}.DoGs_diffwhmin = diffwhmin;
            end
            
            % For every condition and roi, save the index_thr and add them to
            % the Cond_model table so that they can be loaded later
            index_thr_tmp{cond_idx,sub_idx,roi_idx} = model_data{cond_idx,sub_idx,roi_idx}.varexp > opt.varExpThr & model_data{cond_idx,sub_idx,roi_idx}.ecc < opt.eccThr(2) & model_data{cond_idx,sub_idx,roi_idx}.ecc > opt.eccThr(1) & mean_map > opt.meanMapThr;
            
            % Determine the thresholded indices for each of the ROIs
            %roi_index{roi_idx,1} = index_thr_tmp{1,1} & index_thr_tmp{2,1};
            roi_index{cond_idx,sub_idx,roi_idx} = index_thr_tmp{cond_idx,sub_idx,roi_idx};
            
            % Apply these thresholds on the pRF parameters for both the conditions
            model_data_thr{cond_idx,sub_idx,roi_idx} = NP_params_thr(model_data{cond_idx,sub_idx,roi_idx},roi_index{cond_idx,sub_idx,roi_idx},opt);
            
            % Store the thresholded pRF values in a table
            %add_t_1{sub_idx} = table(model_data_thr{cond_idx,sub_idx,roi_idx},'VariableNames',ROI_params.rois(roi_idx));
            
            
        end
        
    end
    
    
end

% Update Cond_model with number of subjects for each conditions
add_t_sub = table(numSubjects);
Cond_model = [Cond_model add_t_sub];

for roi_idx = 1:num_roi
    for cond_idx = 1:numCond
        numSub = Cond_model.numSubjects(cond_idx);
        for sub_idx = 1:numSub
            model_data_thr_t{cond_idx,sub_idx} = model_data_thr{cond_idx,sub_idx,roi_idx};
            
        end
    end
    add_t_1 = table(model_data_thr_t,'VariableNames',ROI_params.rois(roi_idx));
    
    
    if roi_idx == 1
        add_t_rois = add_t_1;
    else
        add_t_rois = [add_t_rois add_t_1];
    end
    
end

% Update Cond_model table with the model parameters. Each row contains same
% condition, with ROIs marked with their respective names. Within each roi,
% there is a structure with all model parameters for each subject.


Cond_model = [Cond_model add_t_rois];


% Update the ROI_params with the thresholded index values
% add_t_1_roi = table(roi_index);
% ROI_params = [ROI_params add_t_1_roi];

%%
%Analysis = 'subave_Ave';
Analysis = 'alltog';

switch Analysis
    case 'subave_Ave'
        
        for roi_idx = 1:num_roi
            roi_comp = ROI_params.rois{roi_idx};
            for cond_idx = 1:numCond
                numSub = Cond_model.numSubjects(1);
                for sub_idx = 1:numSub
                    x_param_comp_1 = Cond_model{1,roi_comp}{1,sub_idx}.ecc;
                    y_param_comp_1 = Cond_model{1,roi_comp}{1,sub_idx}.sigma;
                    ve_comp_1 = Cond_model{1,roi_comp}{1,sub_idx}.varexp;
                    
                    x_param_comp_2 = Cond_model{2,roi_comp}{1,sub_idx}.ecc;
                    y_param_comp_2 = Cond_model{2,roi_comp}{1,sub_idx}.sigma;
                    ve_comp_2 = Cond_model{2,roi_comp}{1,sub_idx}.varexp;
                    
                    x_param_comp_3 = Cond_model{3,roi_comp}{1,sub_idx}.ecc;
                    y_param_comp_3 = Cond_model{3,roi_comp}{1,sub_idx}.sigma;
                    ve_comp_3 = Cond_model{3,roi_comp}{1,sub_idx}.varexp;
                    
                    % fit
                    % Axis limits for plotting
                    xaxislim = [0 10.21];
                    yaxislim = [0 6];
                    
                    % x range values for fitting
                    xfit_range = [opt.eccThr(1) opt.eccThr(2)];
                    xfit = linspace(xfit_range(1),xfit_range(2),8)';
                    param_comp_1_yfit = NP_fit(x_param_comp_1,y_param_comp_1,ve_comp_1,xfit);
                    param_comp_2_yfit = NP_fit(x_param_comp_2,y_param_comp_2,ve_comp_2,xfit);
                    param_comp_3_yfit = NP_fit(x_param_comp_3,y_param_comp_3,ve_comp_3,xfit);
                    
                    
                    xfit_all(cond_idx).val(:,sub_idx,roi_idx) = xfit;
                    param_comp_1_yfit_all(cond_idx).val(:,sub_idx,roi_idx) = param_comp_1_yfit;
                    param_comp_2_yfit_all(cond_idx).val(:,sub_idx,roi_idx) = param_comp_2_yfit;
                    param_comp_3_yfit_all(cond_idx).val(:,sub_idx,roi_idx) = param_comp_3_yfit;
                    
                    % Bootstrap the data and bin the x parameter
                    [param_comp_1_data,param_comp_1_b_xfit,param_comp_1_b_upper,param_comp_1_b_lower] = NP_bin_param(x_param_comp_1,y_param_comp_1,ve_comp_1,xfit_range);
                    [param_comp_2_data,param_comp_2_b_xfit,param_comp_2_b_upper,param_comp_2_b_lower] = NP_bin_param(x_param_comp_2,y_param_comp_2,ve_comp_2,xfit_range);
                    [param_comp_3_data,param_comp_3_b_xfit,param_comp_3_b_upper,param_comp_3_b_lower] = NP_bin_param(x_param_comp_3,y_param_comp_3,ve_comp_3,xfit_range);
                    
                    param_comp_1_b_xfit_all(cond_idx).val(:,sub_idx,roi_idx) = param_comp_1_data.x'  ; param_comp_1_data_all(cond_idx).val(:,sub_idx,roi_idx) = param_comp_1_data.y;
                    param_comp_2_b_xfit_all(cond_idx).val(:,sub_idx,roi_idx) = param_comp_2_data.x'  ; param_comp_2_data_all(cond_idx).val(:,sub_idx,roi_idx) = param_comp_2_data.y;
                    param_comp_3_b_xfit_all(cond_idx).val(:,sub_idx,roi_idx) = param_comp_3_data.x'  ; param_comp_3_data_all(cond_idx).val(:,sub_idx,roi_idx) = param_comp_3_data.y;
                    
                end
            end
        end
        
        for cond_idx = 1:numCond
            xfit_all_ave  = mean(xfit_all(cond_idx).val,2);
            param_comp_1_yfit_all_ave = mean(param_comp_1_yfit_all(cond_idx).val,2);
            param_comp_2_yfit_all_ave = mean(param_comp_2_yfit_all(cond_idx).val,2);
            param_comp_3_yfit_all_ave = mean(param_comp_3_yfit_all(cond_idx).val,2);
            
            param_comp_1_b_xfit_all_ave = mean(param_comp_1_b_xfit_all(cond_idx).val,2);
            param_comp_2_b_xfit_all_ave = mean(param_comp_2_b_xfit_all(cond_idx).val,2);
            param_comp_3_b_xfit_all_ave = mean(param_comp_3_b_xfit_all(cond_idx).val,2);
            
            param_comp_1_b_data_all_ave = mean(param_comp_1_data_all(cond_idx).val,2);
            param_comp_2_b_data_all_ave = mean(param_comp_2_data_all(cond_idx).val,2);
            param_comp_3_b_data_all_ave = mean(param_comp_3_data_all(cond_idx).val,2);
            
        end
        
        for roi_idx = 1:num_roi
            for cond_idx = 1:numCond
                % Plot the fit line
                figPoint_fit = figure;
                plot(xfit_all_ave(:,:,roi_idx),param_comp_1_yfit_all_ave(:,:,roi_idx)','b'); hold on;
                plot(xfit_all_ave(:,:,roi_idx),param_comp_2_yfit_all_ave(:,:,roi_idx)','g');hold on;
                plot(xfit_all_ave(:,:,roi_idx),param_comp_3_yfit_all_ave(:,:,roi_idx)','r');
                
                %         hold on;
                %         plot(param_comp_1_b_xfit_all_ave(:,:,roi_idx),param_comp_1_b_upper_all_ave(:,:,roi_idx),'b--');
                %         plot(param_comp_1_b_xfit,param_comp_1_b_lower,'b--');
                %
                %         plot(param_comp_2_b_xfit,param_comp_2_b_upper,'g--');
                %         plot(param_comp_2_b_xfit,param_comp_2_b_lower,'g--');
                %
                %         plot(param_comp_3_b_xfit,param_comp_3_b_upper,'r--');
                %         plot(param_comp_3_b_xfit,param_comp_3_b_lower,'r--')
                
                hold on;
                plot(param_comp_1_b_xfit_all_ave(:,:,roi_idx),param_comp_1_b_data_all_ave(:,:,roi_idx)','b--'); hold on;
                plot(param_comp_2_b_xfit_all_ave(:,:,roi_idx),param_comp_2_b_data_all_ave(:,:,roi_idx)','g--');hold on;
                plot(param_comp_3_b_xfit_all_ave(:,:,roi_idx),param_comp_3_b_data_all_ave(:,:,roi_idx)','r--');
                
                
                
                
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
                
                
                
            end
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
                        x_param_comp_1 = [x_param_comp_1 Cond_model{1,roi_comp}{1,sub_idx}.ecc];
                        y_param_comp_1 = [y_param_comp_1 Cond_model{1,roi_comp}{1,sub_idx}.DoGs_surroundSize];
                        
                        ve_comp_1 = [ve_comp_1 Cond_model{1,roi_comp}{1,sub_idx}.varexp];
                    end
                    
                    num_sub_comp_2 = Cond_model.numSubjects(2);
                    for sub_idx= 1:num_sub_comp_2
                        x_param_comp_2 = [x_param_comp_2 Cond_model{2,roi_comp}{1,sub_idx}.ecc];
                        y_param_comp_2 = [y_param_comp_2 Cond_model{2,roi_comp}{1,sub_idx}.DoGs_surroundSize];
                        
                        ve_comp_2 = [ve_comp_2 Cond_model{2,roi_comp}{1,sub_idx}.varexp];
                    end
                    
                    num_sub_comp_3 = Cond_model.numSubjects(3);
                    for sub_idx= 1:num_sub_comp_3
                        x_param_comp_3 = [x_param_comp_3 Cond_model{3,roi_comp}{1,sub_idx}.ecc];
                        y_param_comp_3 = [y_param_comp_3 Cond_model{3,roi_comp}{1,sub_idx}.DoGs_surroundSize];
                        
                        ve_comp_3 = [ve_comp_3 Cond_model{3,roi_comp}{1,sub_idx}.varexp];
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
            
            figPoint_raw = figure;
            plot(x_param_comp_1,y_param_comp_1,'b*');
            hold on; plot(x_param_comp_2,y_param_comp_2,'g*');
            hold on; plot(x_param_comp_3,y_param_comp_3,'r*');
            % figure attributes
            %titleName = strcat(Cond_model{1,1},'and',Cond_model{2,1});
            titleall = sprintf('%s', roi_comp) ;
            title(titleall);
            legend([{data_comp_1},{data_comp_2},{data_comp_3}]);
            ylim(yaxislim);
            xlim(xaxislim);
            
            hold off;
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
            figPoint_fit = figure;
            plot(xfit,param_comp_1_yfit','b'); hold on;
            plot(xfit,param_comp_2_yfit','g');hold on;
            plot(xfit,param_comp_3_yfit','r');
            
            fprintf('Binning and bootstrapping the data for roi %d \n',roi_idx')
            
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
            plot(param_comp_1_b_xfit,param_comp_1_b_upper,'b--');
            plot(param_comp_1_b_xfit,param_comp_1_b_lower,'b--');
            
            plot(param_comp_2_b_xfit,param_comp_2_b_upper,'g--');
            plot(param_comp_2_b_xfit,param_comp_2_b_lower,'g--');
            
            plot(param_comp_3_b_xfit,param_comp_3_b_upper,'r--');
            plot(param_comp_3_b_xfit,param_comp_3_b_lower,'r--');
            
            hold on;
            errorbar(param_comp_1_data.x,param_comp_1_data.y,param_comp_1_data.ysterr,'bo','MarkerFaceColor','b','MarkerSize',MarkerSize);
            errorbar(param_comp_2_data.x,param_comp_2_data.y,param_comp_2_data.ysterr,'go','MarkerFaceColor','g','MarkerSize',MarkerSize);
            errorbar(param_comp_2_data.x,param_comp_3_data.y,param_comp_3_data.ysterr,'ro','MarkerFaceColor','r','MarkerSize',MarkerSize);
            
            titleall = sprintf('%s', roi_comp) ;
            title(titleall);
            legend([{data_comp_1},{data_comp_2},{data_comp_3}]);
            ylim(yaxislim);
            xlim(xaxislim);
            
            hold off;
            
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

end

