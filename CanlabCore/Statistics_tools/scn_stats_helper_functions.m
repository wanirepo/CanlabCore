function varargout = scn_stats_helper_functions(meth, varargin)
%
% Helper functions for stats routines, plotting, and printing
%
% Available methods
% 'print'   : print outcome table from stats structure
% 'gls'     : GLS function, weighted or unweighted; with AR model if
%               specified as last input
% 'boot'    : Boostrapping of GLS
% 'signperm': Sign permutation test for intercept of GLS
%
% 'plot'    :
%
% 'loess_xy'    : loess plots of multilevel X and Y data
%                 X is cell array with X data for each subject, Y is cell array, same format
% 'xycatplot'
% 'loess_partial'
% 'xyplot'        % multilevel line plot of x vs y within subjects, grouping trials by
%                optional G variable. X can be categorical or continuous.
%
% 'xytspanelplot' : X and Y are timeseries data; separate panel plot for each
%                   cell
%
% FORMAT STRINGS
% --------------------------------------------------------------------------------------------
% scn_stats_helper_functions('print', stats, stats_within)
% See glmfit_general for context and usage
%
% [b, s2between_ols, stats] = scn_stats_helper_functions('gls', Y, W, X)
% [b, s2between_ols] = scn_stats_helper_functions('gls', Y, W, X, arorder);
% See glmfit_general for context and usage
%
% stats = scn_stats_helper_functions('boot', Y, W, X, bootsamples, stats, whpvals_for_boot, targetu, verbose )
% stats = scn_stats_helper_functions('boot', Y, stats.W, X, 1000, stats, 1:size(Y,2), .005, 1 )
%
% stats = scn_stats_helper_functions('signperm', Y, W, X, nperms, stats, permsign, verbose )
% stats = scn_stats_helper_functions('signperm', Y, W, X, 5000, stats, [], 1 );
%
% stats = scn_stats_helper_functions('xycatplot', X, Y);
% stats_plot = scn_stats_helper_functions('xycatplot', stats.inputOptions.X, stats.inputOptions.Y, 'weighted', 'samefig');
%
% scn_stats_helper_functions('xyplot', data(1:19), SETUP.data.Y, 'weighted', 'groupby', G, 'colors', {'y' [.2 .2 .2]});'y'
%
% Example: using sign permutation test
% --------------------------------------------------------------------------------------------
% *Note: Out of memory errors for large n!
%
% Y = randn(20, 4); X = Y(:,1) + randn(20,1); X = [ones(size(X)) X];
% first_lev_var = rand(20, 4);
% stats = glmfit_general(Y, X, 'weighted', 's2', first_lev_var, 'dfwithin', 20, 'verbose');
% W = stats.W;
% stats = scn_stats_helper_functions('signperm', Y, W, X, 5000, stats, [], 1 );
% % Re-run using already set-up permsign:
% stats = scn_stats_helper_functions('signperm', Y, W, X, 5000, stats, stats.permsign, 1 );
%
%
% scn_stats_helper_functions('loess_xy', stats.inputOptions.X, stats.inputOptions.Y)
%
%
% Example: Loading mediation clusters and making line plot
% G = SETUP.data.X;
% whcl = 30; cluster_orthviews(clneg_data{1}(whcl));
% clear data, for i = 1:length(clneg_data), data{i} = clneg_data{i}(whcl).timeseries; end
% scn_stats_helper_functions('xyplot', data, SETUP.data.Y, 'weighted', 'groupby', G, 'colors', {'y' [.2 .2 .2]});
% scn_stats_helper_functions('xyplot', SETUP.data.Y, data, 'weighted', 'groupby', G, 'colors', {'y' [.4 .4 .4]}); xlabel('Report'); ylabel('Brain');
%
% Called by:
%   mediation.m
%   glmfit_general.m
%
% Tor Wager, Sept 2007




switch meth
    
    
    % descriptives
    % ------------------------------------------
    case 'means'
        
        X = []; % matrix of categorical selection variables
        G = []; % indicator for cases to select
        Y = []; % outcome
        mymeans = [];
        mystes = [];
        gval = [];
        mycounts = [];
        mylevels = cell(1, 2);
        
        for i = 1:length(varargin)
            if ischar(varargin{i})
                switch varargin{i}
                    
                    case {'X'}, X = varargin{i+1};
                    case {'G', 'S'}, G = varargin{i+1};
                    case {'Y'}, Y = varargin{i+1};
                    case 'gval', gval = varargin{i+1};
                        
                    otherwise, warning(['Unknown input string option:' varargin{i}]);
                end
            end
        end
        
        if iscell(X)
            X = cat(1, X{:});
        end
        
        if iscell(Y)
            Y = cat(1, Y{:});
        end
        
        if iscell(G)
            G = cat(1, G{:});
        end
        
        % select cases
        if ~isempty(G)
            if isempty(gval)
                G = logical(G);
                X = X(G, :);
                Y = Y(G, :);
            else
                X = X(G == gval, :);
                Y = Y(G == gval, :);
            end
        end
        
        for i = 1:size(X, 2)
            mylevels{i} = sort(unique(X(:, i)));
        end
        
        % Adjust if no second var entered
        if isempty(mylevels{2})
            X(:, 2) = 1;
            mylevels{2} = 1;
        end
        
        for i = 1:length(mylevels{1})
            
            wh{1} = X(:, 1) == mylevels{1}(i);
            
            for j = 1:length(mylevels{2})
                
                wh{2} = X(:, 2) == mylevels{2}(j);
                
                wh_cases = wh{1} & wh{2};
                
                mycounts(i, j) = sum(wh_cases);
                
                if mycounts(i, j) < 1
                    
                    mymeans(i, j) = NaN;
                    mystes(i, j) = NaN;
                    
                else
                    
                    mymeans(i, j) = nanmean(Y(wh_cases));
                    mystes(i, j) = ste(Y(wh_cases));
                    
                end
                
            end
            
        end
        
        for i = 1:length(mylevels{1})
            levelnames{1}{i} = sprintf('V1 = %3.2f', mylevels{1}(i));
        end
        
        for i = 1:length(mylevels{2})
            levelnames{2}{i} = sprintf('V2 = %3.2f', mylevels{2}(i));
        end
        
        varargout{1} = struct('means', mymeans, 'stes', mystes, 'counts', mycounts, 'levels', [], 'levelnames', []);

        varargout{1}.levels = mylevels;
        varargout{1}.levelnames = levelnames;
        
        
        
        
        % estimation
        % ----------------------------------------------------------------
    case 'gls'
        if nargout == 1
            % fastest
            varargout{1} = GLScalc(varargin{:});
            
        elseif nargout == 2
            [b, s2between_ols] = GLScalc(varargin{:});
            varargout{1} = b;
            varargout{2} = s2between_ols;
            
        else
            % slowest
            [b, s2between_ols, stats] = GLScalc(varargin{:});
            varargout{1} = b;
            varargout{2} = s2between_ols;
            varargout{3} = stats;
        end
        
        % printing and plotting
        % ----------------------------------------------------------------
        
    case 'print'
        try
            print_outcome(varargin{:});
        catch
            disp('Improper use of stats print option.  You must create a valid stats structure,');
            disp('e.g., with mediation.m or glmfit_general.m or igls.m');
            rethrow(lasterror);
        end
        
    case 'xycatplot',       varargout{1} = xycatplot(varargin{:});
        
    case 'loess_xy',        loessxy(varargin{:});
        
    case 'loess_partial',   loess_partial(varargin{:});
        
    case 'xyplot', xyplot(varargin{:});
        
    case 'xytspanelplot', varargout{1} = xytspanelplot(varargin{:});
        
        % bootstrapping and nonparametrics
        % ----------------------------------------------------------------
        
    case 'boot'
        varargout{1} = bootstrap_gls(varargin{:});
        
    case 'signperm'
        varargout{1} = signperm_gls(varargin{:});
        
        
    otherwise
        error('Unknown method: Improper usage of this function.')
end







end






% _________________________________________________________________________
%
%
%
% * GLS Estimation functions
%
%
%
%__________________________________________________________________________




% -------------------------------------------------------------------------
% GLS estimation of betas, ols variances, and full stats if 3rd output
% is requested
% -------------------------------------------------------------------------

function [b, s2between_ols, stats] = GLScalc(Y, W, X, varargin)
% OLScalc
% calculate group betas, group variance
% Optional: full inference outputs (takes longer)

% -------------------------------------------------------------------------
% GLS estimation of betas
% -------------------------------------------------------------------------

arorder = 0;
if ~isempty(varargin), arorder = varargin{1}; end

[n, k] = size(X);
nvars = size(Y, 2);

b = zeros(k, nvars);


if k == 1 && all(X == X(1)) && (nargout == 1)
    
    % intercept only; fast computation
    % Weighted mean function:
    % Very efficient when there are no predictors other than the intercept
    % Faster than looping, and faster than using mean() for equal weights
    
    b = diag(W'*Y)';
    
    
else
    % predictors; need full computation
    % OR we are getting variances, and need full computation for them
    % anyway
    % Full GLS function, needed if there are predictors
    
    
    % setup stuff
    
    Wi = cell(1, k);
    invxvx = cell(1, nvars);
    bforming = cell(1, nvars);
    equal_weights = false(1, nvars);
    
    for i = 1:nvars
        
        if all(W(:, i) == W(1, i))
            % weights are equal
            equal_weights(i) = 1;
            
        end
        
    end
    
    isweighted = 0;
    
    % get matrices for outcome vars in OLS case
    if any(equal_weights)
        
        tmp = inv(X' * X);       % Save these for later, for speed; don't need to re-use
        invxvx(equal_weights) = {tmp};
        bforming(equal_weights) = {tmp * X'};
    end
    
    % get betas (coefficients) and other necessary matrices for weighted columns
    for i = 1:nvars
        
        if ~equal_weights(i)
            isweighted = 1;
            
            Wi{i} = diag(W(:, i));              % Wi = V^-1, inverse of cov.matrix
            
            invxvx{i} = inv(X' * Wi{i} * X);       % Save these for later, for speed; don't need to re-use
            bforming{i} = invxvx{i} * X' * Wi{i};
            
        end
        
        b(:, i) = bforming{i} * Y(:, i);
        %b(:, i) = inv(X' * Wi * X) * X' * Wi * Y(:, i);
        
        
        % Add AR(p) model stuff here
        if arorder > 0
            % Warning: Tested March08...not same as fit_gls, check.****
            disp('Warning: Check AR code');
            [b(:, i),stebetatmp, varbetatmp, tmpi, tmpv, dfe_ols(i), Phi] = ...
                ar_iterate_core(X, Y(:, i), b(:, i), n, arorder);
            
        end
        
    end
end


% Optional additional computations: optional in case we want to return just b
% and go really fast (e.g., for bootstrapping)

if nargout > 1
    
    % --------------------------------------
    % * Residuals
    % --------------------------------------
    
    e = Y - X * b;         % residuals
    
    %
    % OLS residual variance
    % If bootstrapping or permuting, use this to get weights
    
    if ~(arorder > 0)
        dfe_ols = (n - k) .* ones(1, nvars);
    end
    
    % --------------------------------------
    % * Residual variance
    % --------------------------------------
    %s2between = diag(e' * e)' ./ dfe;               % var for each col of Y, 1 x nvars
    s2between_ols = (1 ./ dfe_ols .* sum(e .^ 2));  % Estimates of Sigma^2 for each col. of Y
    
end

if nargout > 2
    % Weighted variance (s2) and full stats
    
    % --------------------------------------
    % * Degrees of freedom for each column of Y
    % --------------------------------------
    dfe = dfe_ols;
    
    
    % Get design-related component of STE (includes n)
    % replace dfe with Sattherwaite approx. if necessary
    
    Xste = zeros(k, nvars);
    
    
    % --------------------------------------
    % * Residual variances, std. errors for each column of Y
    % --------------------------------------
    for i = 1:nvars
        
        Xste(:, i) = diag(invxvx{i});                  % design-related contribution to variance, k x nvars
        
        if equal_weights(i)
            % weights are equal
            
            s2between(i) = s2between_ols(i);            % Residual variance for this outcome variable
            
        else
            % all weights are not equal
            % Update dfe and s2between
            
            % R = Wi.^.5 * (eye(n) - X * invxvx * X' * Wi{i});          % Residual inducing matrix
            R = Wi{i} .^ .5 * (eye(n) - X * bforming{i});               % Residual inducing matrix
            
            Q = R * inv(Wi{i});                                         % Q = RV
            dfe(i) = (trace(Q).^2)./trace(Q * Q);                       % Satterthwaite approximation for degrees of freedom
            
            % --------------------------------------
            % * Residual variance
            % --------------------------------------
            e = R * Y(:, i);                                            % weighted residuals
            s2between(i) = diag(e' * e)' ./ dfe(i);                     % var for each col of Y, 1 x nvars
        end
        
    end
    
    % --------------------------------------
    % * Standard errors of coefficients
    % --------------------------------------
    sterrs =  ( Xste .* repmat(s2between, k, 1) ) .^ .5;
    
    % -------------------------------------------------------------------------
    % Get statistic structure from OLS regression, including p-values and conf. intervals
    % -------------------------------------------------------------------------
    
    
    stats.mean = b(1, :);           % intercept;  mean response
    stats.mean_descrip = 'Intercept of each col. of Y; (mean response if predictors are centered)';
    
    stats.beta = b;
    stats.beta_descrip = 'betas (regression coefficients), k predictors x nvars';
    
    stats.var = s2between;
    stats.var_descrip = 'Residual variance of each col. of Y';
    
    stats.ste = sterrs;
    stats.ste_descrip = 'Std. error of each beta for each col. of Y, k predictors x nvars';
    
    stats.t = b ./ sterrs;
    
    stats.dfe = dfe;
    stats.dfe_descrip = 'error DF for each col. of Y, Satterthwaite corrected if necessary;  1 x nvars';
    
    
    
    stats.e = e;
    if ~isweighted
        stats.e_descrip = 'unweighted (OLS) residuals';
    else
        stats.e_descrip = 'weighted residuals (resid. from weighted GLS model.)';
    end
    
    for i = 1:k
        
        stats.p(i, :) = min(1, (2 .* (1 - tcdf(abs(stats.t(i, :)), stats.dfe))));
        
        stats.p(i, :) = max(stats.p(i, :), eps);
        
    end
    
    stats.p_descrip = 'Two-tailed p-values';
    
end

end






% _________________________________________________________________________
%
%
%
% * Printing and plotting
%
%
%
%__________________________________________________________________________




% -------------------------------------------------------------------------
% Print summary of mediation analysis/stats results to screen
% -------------------------------------------------------------------------
function print_outcome(stats, stats1)

if nargin < 2, stats1 = []; end

fprintf('\n________________________________________\n')
if isfield(stats.inputOptions, 'inference_option')
    infopt = stats.inputOptions.inference_option;
else
    infopt = 'GLS';
end

if isfield(stats, 'nresample')
    fprintf('Final %s samples: %3.0f\n', infopt, stats.nresample)
end
if strcmp(infopt, 'bootstrap') && isfield(stats, 'alphaaccept')
    fprintf('Average p-value tolerance (average max alpha): %3.4f\n', stats.alphaaccept)
end

% convergence values (first level)
if ~isempty(stats1)
    if isfield(stats1, 'isconverged') && isfield(stats1, 'mean')
        N = size(stats1.mean, 1);
        mysum = sum(stats1.isconverged);
        myperc = 100*mysum ./ N;
        fprintf('Number converged: %3.0f, %3.0f%%\n', mysum, myperc)
    end
end


Z = abs(norminv(stats.p)) .* sign(stats.beta);
n_predictors = size(stats.beta, 1);

if isfield(stats.inputOptions, 'beta_names')
    pred_names = stats.inputOptions.beta_names;
else
    for i = 1:n_predictors
        pred_names{i} = sprintf('Predictor %02d', i);
    end
end

fprintf('\n%s\n\tOutcome variables:\n', stats.analysisname)
fprintf('\t')
fprintf('%s\t', stats.inputOptions.names{:})
fprintf('\n')
if isfield(stats, 'mean')
    print_line('Adj. mean', stats.mean);
end

for i = 1:n_predictors
    fprintf('\n');
    fprintf('%s\n\t', pred_names{i})
    fprintf('%s\t', stats.inputOptions.names{:})
    fprintf('\n');
    
    print_line('Coeff', stats.beta(i,:));
    print_line('STE', stats.ste(i,:))
    
    if isfield(stats, 't')
        print_line('t', stats.t(i,:))
    else
        print_line('t (~N)', stats.beta(i,:) ./stats.ste(i,:))
    end
    
    print_line('Z', Z(i,:))
    
    print_line('p', stats.p(i,:), 4)
    fprintf('\n')
    
end




fprintf('________________________________________\n')
end


function print_line(hdr, data, dec)
if nargin == 2
    dec = num2str(2);
else
    dec = num2str(dec);
end

fprintf('%s\t', hdr)
if iscell(data)
    eval(['fprintf(''%3.' dec 'f\t'', data{:})']);
else
    eval(['fprintf(''%3.' dec 'f\t'', data)']);
end
fprintf('\n');
end


% -------------------------------------------------------------------------
% LOESS plots of N subjects, categorical X vs Y
% -------------------------------------------------------------------------
function stats = xycatplot(X, Y, varargin)

regularization = .8; % for loess
newfig = 1;
weight_option = 'unweighted';  % for glmfit
doloess = 0;
doind = 1;
groupvar = []; % should be cell for each subject with integer values

for i = 1:length(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            % General Defaults
            case {'reg', 'regularization'}, regularization = varargin{i + 1};
            case 'samefig', newfig = 0;
            case 'beta_names', beta_names = varargin{i+1}; varargin{i+1} = [];
                
                % Estimation Defaults
            case {'weight', 'weighted', 'var', 's2'}, weight_option = 'weighted';
                
            case 'loess', doloess = 1;
            case 'noind', doind = 0;
                
            case {'groupby', 'groupvar'}, groupvar = varargin{i+1};
                
            otherwise
                disp('Warning! Unknown input string option.');
                
        end
    end
end

if newfig, create_figure('Y as a function of categorical X'); end

N = length(X);
xlevels = cell(1, N);
Xdes = cell(1, N);

for i = 1:N
    
    [Xdes{i}, xlevels{i}] = condf2indic(X{i});
    
    if ~isempty(groupvar)
        % Split Xdes up by high vs. low on group var, within each subject
        gv = repmat(contrast_code(groupvar{i}), 1, length(xlevels{i}));
        Xdes{i} = [Xdes{i} .* (gv == 1) Xdes{i} .* (gv == -1)];
        
        xlevels{i} = [xlevels{i}; xlevels{i}];
    end
    
    yavgs{i} = pinv(Xdes{i}) * Y{i};
    
    if doind
        plot(xlevels{i}, yavgs{i}, 'o-', 'Color', [.6 .6 .6], 'MarkerSize', 6, 'MarkerFaceColor', [.8 .8 .8]);
    end
end

% get group average and stats
stats = glmfit_multilevel(Y, X, [], 'beta_names', {'Intercept' 'Slope'}, weight_option, 'noverbose');

%stats_cat = glmfit_multilevel(Y, Xdes, [], 'beta_names', {'Intercept' 'Slope'}, weight_option, 'noverbose');

stats.individual.Xdes = Xdes;
stats.individual.xlevels = xlevels;
stats.individual.yavgs = yavgs;

% Loess regression line for group average
if doloess
    regularization = .8;
    x = get(gca, 'XLim');
    xx = linspace(x(1), x(2), 50);
    
    yy = loess(cat(1, xlevels{:}), cat(1, yavgs{:}), xx, regularization, 1);
    
    plot(xx, yy, 'r', 'LineWidth', 3);
    
    disp('Bootstrapping group avg. error')
    fcnhandle = @(x, y) loess(x, y, xx, regularization, 1);
    yyboot = bootstrp(100, fcnhandle, cat(1, xlevels{:}), cat(1, yavgs{:}));
    
    upperlim = yy + std(yyboot);
    lowerlim = yy - std(yyboot);
    
    plot(xx, upperlim, 'r--', 'LineWidth', 2);
    plot(xx, lowerlim, 'r--', 'LineWidth', 2);
    
else
    % standard categorical plot: Fixed effects
    % ------------------------------------------
    XX = cat(1, X{:});
    YY = cat(1, Y{:});
    
    if ~isempty(groupvar)
        GG = cat(1, groupvar{:});
    end
    
    mylevels = sort(unique(XX));
    
    for i = 1:length(mylevels)
        if ~isempty(groupvar)
            % two groups
            mymeans(i) = nanmean(YY(XX == mylevels(i) & GG == 1));
            mystes(i) = ste(YY(XX == mylevels(i) & GG == 1));
            mymeans2(i) = nanmean(YY(XX == mylevels(i) & GG == -1));
            mystes2(i) = ste(YY(XX == mylevels(i) & GG == -1));
            
        else
            % single group
            mymeans(i) = nanmean(YY(XX == mylevels(i)));
            mystes(i) = ste(YY(XX == mylevels(i)));
        end
    end
    
    
    h = tor_line_steplot(mymeans, mystes, {'k'}, mylevels);
    set(h, 'LineWidth', 2);
    h = tor_line_steplot(mymeans, -mystes, {'k'}, mylevels);
    set(h, 'LineWidth', 2);
    plot(mylevels, mymeans, 'ko-', 'MarkerSize', 12, 'MarkerFaceColor', [0 .7 .2], 'LineWidth', 4);
    
    if ~isempty(groupvar)
        h = tor_line_steplot(mymeans2, mystes2, {'b'}, mylevels);
        set(h, 'LineWidth', 2);
        h = tor_line_steplot(mymeans2, -mystes2, {'b'}, mylevels);
        set(h, 'LineWidth', 2);
        plot(mylevels, mymeans2, 'o-', 'Color', [.3 .3 1], 'MarkerSize', 12, 'MarkerFaceColor', [0 0 1], 'LineWidth', 4);
    end
    
    % ------------------------------------------
    % standard categorical plot: centered Empirical Bayes estimates
    % NOTE: ASSUMES ALL LEVELS ARE SAME ACROSS SUBJECTS RIGHT NOW!
    % ------------------------------------------
    
    create_figure('X vs. Y with centered Empirical Bayes estimates');
    stats_cat = glmfit_multilevel(Y, Xdes, [], 'beta_names', {'Intercept' 'Slope'}, weight_option, 'noverbose', 'noint');
    
    % Individuals: Center Empirical Bayes estimates of individual means and add in grand
    % mean
    Y2 = stats_cat.Y_star - repmat(nanmean(stats_cat.Y_star, 2), 1, length(xlevels{1}));
    Y2 = Y2 + nanmean(stats_cat.Y_star(:));
    hold on; plot(xlevels{1}, Y2, 'o-', 'Color', [.6 .6 .6],'MarkerSize', 6, 'MarkerFaceColor', [.8 .8 .8]);
    
    h = tor_line_steplot(stats_cat.b_star, mystes, {'k'}, mylevels);
    set(h, 'LineWidth', 2);
    h = tor_line_steplot(stats_cat.b_star, -mystes, {'k'}, mylevels);
    set(h, 'LineWidth', 2);
    
    % could use b_star, but check this...
    hold on; plot(xlevels{1}, stats_cat.b_star, 'ks-', 'MarkerSize', 12, 'MarkerFaceColor', [0 .7 .2], 'LineWidth', 4);
    
    
end


end


% -------------------------------------------------------------------------
% LOESS plots of N subjects, X vs Y
% -------------------------------------------------------------------------
function loessxy(X, Y, varargin)
% loessxy(X, Y)
%
% Loess plot; X is cell array with X data for each subject, Y is cell
% array, same format

%LOESS PLOTS

regularization = .8;
if ~isempty(varargin), regularization = varargin{1}; end

create_figure('X - Y plot');
N = length(X);
for i = 1:N
    hh(i) = plot(X{i}, Y{i}, 'ko', 'MarkerSize', 4);
    
    %refline(hh);
end

x = get(gca, 'XLim');
xx = linspace(x(1), x(2), 50);

for i = 1:N
    
    yy(i, :) = loess(X{i}, Y{i}, xx, regularization, 1);
    plot(xx, yy(i,:))
    
end

title('Loess: X - Y');
xlabel('Temperature');
ylabel('Pain report');

plot(xx, mean(yy), 'r', 'LineWidth', 2);


end


% -------------------------------------------------------------------------
% Print summary of mediation analysis/stats results to screen
% -------------------------------------------------------------------------
function loess_partial(M, Y, X, varargin)
% partial regression LOESS plots, M vs Y controlling for X


regularization = .8; % for loess
newfig = 1;
weight_option = 'unweighted';  % for glmfit

for i = 1:length(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            % General Defaults
            case {'reg', 'regularization'}, regularization = varargin{i + 1};
                
            case 'samefig', newfig = 0;
                
            case 'beta_names', beta_names = varargin{i+1}; varargin{i+1} = [];
                
                % Estimation Defaults
            case {'weight', 'weighted', 'var', 's2'}, weight_option = 'weighted';
                
                
            otherwise
                disp('Warning! Unknown input string option.');
                
        end
    end
end

newy = {};
newm = {};

if newfig, create_figure('M - Y partial plot'); end

N = length(X);
for i = 1:N
    
    [b, dev, stat1] = glmfit(X{i}, Y{i});
    newy{i} = stat1.resid;
    [b, dev, stat2] = glmfit(X{i}, M{i});
    newm{i} = stat2.resid;
    
end

for i = 1:N
    hh(i) = plot(newm{i}, newy{i}, 'ko', 'MarkerSize', 4);
end

% get range of support for loess
alldat = cat(1, newm{:});
x(1) = prctile(alldat, 1);
x(2) = prctile(alldat, 99);
xx = linspace(x(1), x(2), 50);

for i = 1:N
    
    yy(i, :) = loess(newm{i}, newy{i}, xx, regularization, 1);
    plot(xx, yy(i,:))
    
end

plot(xx, mean(yy), 'r', 'LineWidth', 2);

title('Loess: M - Y partial plot');
xlabel('Brain activity (partial)');
ylabel('Pain report (partial)');

end



% -------------------------------------------------------------------------
% LOESS plots of N subjects, categorical X vs Y
% -------------------------------------------------------------------------
function stats = xyplot(X, Y, varargin)

regularization = .8; % for loess
newfig = 1;
weight_option = 'unweighted';  % for glmfit

G = cell(size(X));  % grouping variable for trial types
for i = 1:length(G), G{i} = ones(size(X{i}, 1), 1); end

npredictors = size(X{1}, 2);
names = {'Intercept'};
for i = 1:npredictors
    names{i + 1} = ['X' num2str(i)];
end

colors = {'b' 'g' 'r' [1 .5 0] [0 .5 1] [.5 0 1]};
iscatx = 0;

dostats = 1;
doind = 1;

for i = 1:length(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            % General Defaults
            case {'reg', 'regularization'}, regularization = varargin{i + 1};
                
            case 'samefig', newfig = 0;
                
            case 'beta_names', beta_names = varargin{i+1}; varargin{i+1} = [];
                
            case 'names', names = varargin{i+1}; varargin{i+1} = [];
                
            case 'groupby', G = varargin{i+1};
                
            case 'colors', colors = varargin{i+1};
                
            case {'cat', 'catx'}, iscatx = 1;
                
                % Estimation Defaults
            case {'weight', 'weighted', 'var', 's2'}, weight_option = 'weighted';
                
            case 'nostats', dostats = 0;
            case 'noind', doind = 0;
                
            otherwise
                disp('Warning! Unknown input string option.');
                
        end
    end
end

if newfig
    f1 = create_figure('Y as a function of X', 1, 2);
else
    f1 = gcf;
end


N = length(X);
xlevels = cell(1, N);
Xdes = cell(1, N);

npanels = ceil(sqrt(N));
if doind
    f2 = create_figure('Individual X-Y', npanels, npanels);
end

figure(f1);

Glevels = unique(cat(1, G{:}));

if length(Glevels) > 1
    disp('Grouping levels, from lowest to highest:');
    disp(Glevels)
    disp(colors);
end

while length(colors) < length(Glevels), colors = [colors colors]; end

for group = 1:length(Glevels)
    
    if doind
        figure(f1);
        subplot(1, 2, 2);
        title('Individuals');
    end
    
    for i = 1:N
        
        wh = G{i} == Glevels(group);
        
        xvals{i} = X{i}(wh);
        yvals{i} = Y{i}(wh);
        
        if iscatx % categorical X
            [Xdes{i}, xlevels{i}] = condf2indic(xvals{i});
            
        else  % continuous X
            
            % exclude bad continuous values (exact 0 or NaN)
            whbad = isnan(xvals{i})| xvals{i} == 0 | isnan(yvals{i}) | yvals{i} == 0;
            xvals{i}(whbad) = [];
            yvals{i}(whbad) = [];
            
            if isempty(xvals{i})
                fprintf('No valid data for subject %3.0f. Skipping.\n', i);
                xlevels{i} = [];
                yavgs{i} = [];
                continue
            end
            
            Xdes{i} = xvals{i};
            Xdes{i}(:, end+1) = 1;
            xlevels{i} = [nanmean(xvals{i}) - nanstd(xvals{i}) nanmean(xvals{i}) + nanstd(xvals{i})]'; %[prctile(X{i}, 20) prctile(X{i}, 80)]';
        end
        
        if size(Xdes{i}, 1) ~= size(yvals{i}, 1), error('Lengths of X and Y do not match.'); end
        
        if iscatx % categorical X
            yavgs{i} = pinv(Xdes{i}) * yvals{i};
            
        else  % continuous X, get fits
            b{i} = pinv(Xdes{i}) * yvals{i};
            yavgs{i} = [xlevels{i} ones(size(xlevels{i}))] * b{i};
        end
        
        if doind
            
            figure(f1);
            subplot(1, 2, 2);
            plot( xvals{i}, yvals{i}, '.', 'Color', [.5 .5 .5] );  % trials
            plot(xlevels{i}, yavgs{i}, 'o-', 'Color', colors{group}, 'MarkerSize', 6, 'MarkerFaceColor', [.3 .3 .3]);
            
            % Individual panels figure
            
            figure(f2);
            subplot(npanels, npanels, i)
            
            plot( xvals{i}, yvals{i}, '.', 'Color', [.5 .5 .5] );  % trials
            plot(xlevels{i}, yavgs{i}, 'o-', 'Color', colors{group}, 'MarkerSize', 6, 'MarkerFaceColor', [.3 .3 .3]);
        end
        
    end
    
    
    % Group average for this group of trials
    % % % % % % % % %
    xmean = nanmean(cat(2, xlevels{:}), 2);
    xste = ste(cat(2, xlevels{:})')';
    
    ymean = nanmean(cat(2, yavgs{:}), 2);
    yste = ste(cat(2, yavgs{:})')';
    
    figure(f1)
    subplot(1, 2, 1);
    title('Group average');
    
    for i = 1:length(xmean)
        plot([xmean(i) xmean(i)], [ymean(i) - yste(i) ymean(i) + yste(i)],  'Color', colors{group}, 'LineWidth', 4);
        plot([xmean(i) - xste(i) xmean(i) + xste(i)], [ymean(i) ymean(i)],  'Color', colors{group}, 'LineWidth', 4);
    end
    plot(xmean, ymean, 'o-', 'Color', colors{group}, 'MarkerSize', 10, 'MarkerFaceColor', colors{group}, 'LineWidth', 4);
    hold on
    
end % end groups

% add group effects and interactions with group for stats
% Create a set of group contrast vars [group - prev group]


gnames = {};
ncon = length(Glevels) - 1;
if ncon > 0
    
    
    for group = 2:length(Glevels)
        for i = 1:N
            X{i}(:, end+1) = double(G{i} == Glevels(group - 1));    % subsequent is neg
            X{i}(:, end) = double(G{i} == Glevels(group));          % first is pos
            
            % interaction with X (centered pred.)
            X{i}(:, end+1) = scale(X{i}(:, end), 1) .* scale(X{i}(:, 1));
            
        end
        
        gnames{end + 1} = sprintf('Trial_group%01d-%01d', group - 1, group);
        gnames{end + 1} = sprintf('X x Grp%01d-%01d', group - 1, group);
    end
    
    names = [names gnames];
end

% get stats
if dostats
    stats = glmfit_multilevel(Y, X, [], weight_option, 'verbose', 'noplots', 'names', names);
    
    stats.individual.Xdes = Xdes;
    stats.individual.xlevels = xlevels;
    stats.individual.yavgs = yavgs;
else
    stats = [];
end



end



% -------------------------------------------------------------------------
% Panel plot for each subject
% -------------------------------------------------------------------------
function stats = xytspanelplot(X, Y, varargin)

stats = [];
newfig = 1;
weight_option = 'unweighted';  % for glmfit
dofit = 0;
dozscore = 0;
colors = {'r' 'k'};

for i = 1:length(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            % General Defaults
            case {'t', 'T'}, t = varargin{i + 1}; varargin{i + 1} = [];
                
            case 'samefig', newfig = 0;
                
            case {'fit', 'dofit'}, dofit = 1;
                
                % Estimation Defaults
            case {'weight', 'weighted', 'var', 's2'}, weight_option = 'weighted';
                
            case 'zscore', dozscore = 1;
                
            otherwise
                disp('Warning! Unknown input string option.');
                
        end
    end
end

if ~iscell(X), X = mat2cell(X, size(X, 1), ones(1, size(X, 2))); end
if ~iscell(Y), Y = mat2cell(Y, size(Y, 1), ones(1, size(Y, 2))); end

N = length(X);
nr = ceil(sqrt(N));
nc = floor(sqrt(N));

if nr * nc < N, nc = nc + 1; end % just in case

if newfig, create_figure('XY Panel Plot', nr, nc); end

for i = 1:N
    if dozscore
        X{i} = scale(X{i});
        Y{i} = scale(Y{i});
    end
end

stats = glmfit_multilevel(Y, X, [], weight_option, 'names', {'Intcpt' 'X'});

if dofit
    
    % get fits
    for i = 1:N
        model = X{i}; model = [ones(size(model)) model];
        X{i} = model * stats.first_level.beta(:, i);
    end
end

for i = 1:N
    
    subplot(nr, nc, i)
    
    if ~exist('t', 'var'), t = 1:size(X{i}, 1); end
    
    plot(t, X{i}, colors{1});
    plot(t, Y{i}, colors{2});
    
end

end



% _________________________________________________________________________
%
%
%
% * Bootstrapping functions
%
%
%
%__________________________________________________________________________



% -------------------------------------------------------------------------
% Bootstrap test for 2nd level
% -------------------------------------------------------------------------
function stats = bootstrap_gls(Y, W, X, bootsamples, stats, whpvals_for_boot, targetu, verbose )

% stats structure should already have b's (coeffs, will remain same) and p-values (will be
% updated) from a GLS model.
% Updates:
%   .means, .p, .ste using bootstrapping
%
% pass in weights based on OLS

nvars = size(Y, 2);
k = size(X, 2);

myb = stats.beta(:);
if diff(size(myb)) < 0, myb = myb'; end

stats.gls_p = stats.p;


% Get boot samples needed based on OLS
% Add samples as needed to ensure p-value is reasonably accurate
% Be: Boot samples needed so that Expected (average) p-value
% error due to limited-sample bootstrap is targetu*100 %
% pass in OLS p-values




[final_boot_samples, alphaaccept] = get_boot_samples_needed(stats.p, whpvals_for_boot, targetu, bootsamples, verbose); % uses whpvals_for_boot, returns Be


% set up boostrap beta-generating function
% generic for multiple cols of Y (outcomes), multiple cols. of X
% (predictors), weights equal or not (W)
% much faster if X is intercept only!
% with multiple predictors, much faster if W are equal
% will not work as-is for multiple predictors!  must string out and
% reshape with wrapper function
wmean = @(Y, W, X) gls_wrapper(Y, W, X);

if verbose, fprintf('Bootstrapping %3.0f samples...', final_boot_samples); end

% initalize random number generator to new values; bootstrp uses this
rand('twister',sum(100*clock))

% start with weights all equal whether multilevel or not
means = bootstrp(final_boot_samples, wmean, Y, W, X);

stats = getstats(means, stats, k, nvars);
stats.analysisname = 'Bootstrapped statistics';

if verbose, t12 = clock; end

% bias correction for final bootstrap samples
%[p, z] = bootbca_pval(testvalue, bootfun, bstat, stat, [x], [other inputs to bootfun])

stats.prctilep = reshape(stats.p, k, nvars); % percentile method, biased
[stats.p, stats.z] = bootbca_pval(0, wmean, means, myb, Y, W, X);
stats.p = reshape(stats.p, k, nvars);
stats.z = reshape(stats.z, k, nvars);

stats.biascorrect = 'BCa bias corrected';
stats.alphaaccept = alphaaccept;

if verbose, t13 = clock; end
if verbose, fprintf(' Bootstrap done in %3.2f s, bias correct in %3.2f s \n', etime(clock, t12), etime(clock, t13)); end
end


% -------------------------------------------------------------------------
% Wrapper to return beta matrix strung out in a line, for bootstrapping
% -------------------------------------------------------------------------
function b = gls_wrapper(Y, W, X)
b = scn_stats_helper_functions('gls', Y, W, X);
b = b(:);

if diff(size(b)) < 0, b = b'; end
end


% -------------------------------------------------------------------------
% Figure out how many more bootstrap samples to run (general)
% -------------------------------------------------------------------------
function [Be, alphaaccept] = get_boot_samples_needed(p, whpvals_for_boot, targetu, bootsamples, verbose)
minp = min(p(whpvals_for_boot));
[B95, Be, alphaaccept] = Bneeded(max(.005, minp), targetu);
Be = max(bootsamples, ceil(Be));   % additional number to run

if verbose, fprintf(' Min p-value is %3.6f. Needed: %3.0f samples\n ', minp, Be), end
end

% -------------------------------------------------------------------------
% Get statistic structure from bootstrapped samples, including p-values and conf. intervals
% -------------------------------------------------------------------------
function stats = getstats(bp, stats, k, nvars)

stats.mean = reshape(mean(bp), k, nvars);
stats.ste = reshape(std(bp), k, nvars);

stats.p = 2.*(min(sum(bp<=0), sum(bp>=0)) ./ size(bp, 1));

% avoid exactly-zero p-values
% replace with 1/# bootstrap samples
stats.p = max(stats.p, 1./size(bp, 1));

stats.p = reshape(stats.p, k, nvars);
end






% _________________________________________________________________________
%
%
%
% * Nonparametric test functions
%
%
%
%__________________________________________________________________________




% -------------------------------------------------------------------------
% Permutation test for 2nd level
% -------------------------------------------------------------------------
function stats = signperm_gls(Y, W, X, nperms, stats, permsign, verbose )
%
% Sign permutation test on intercept only!
%
%
% First column of X must be interecept!
%
% if permsign is passed in: uses exact permutations passed in
% set up valid perms using permute_setupperms.m
% save time by keeping permutations the same once we've got them.
% may *not* want to do this in sims, as it introduces some
% dependence across replications!
%
% if permsign is empty, creates new permsign matrix
%
% stats structure should be output from GLS analysis (see glmfit_general or
% GLS helper function in scn_stats_helper_functions
% Updates:
% stats.p, stats.z
% Does not update:
% stats.beta b's (coeffs, will remain same)
% stats.ste
% stats.means
% stats.names
%
% pass in weights based on OLS (Get weights from GLS fit)

if verbose, fprintf('Nonparametric sign permutation test with %3.0f permutations...', nperms); t12 = clock; end

% start with weights all equal whether multilevel or not

% residuals adjusted for intercept, if multiple columns entered
% for intercept only, this is not necessary
k = size(X, 2);
[n, nvars] = size(Y);

if k == 1
    % intercept only
    resid = Y;
else
    resid = zeros(n, nvars);
    
    for i = 1:nvars
        if all(W(:, i) == W(1, i))
            resid(:, i) = Y(:, i) - X(:, 2:end) * stats.beta(2:end, :); % unweighted
        else
            % weighted.  But probably won't matter
            % ****this needs to be checked for accuracy
            Wi = diag(W(:, i));
            resid(:, i) =  Wi * Y(:, i) - Wi * X(:, 2:end) * stats.beta(2:end, i); % unweighted
        end
    end
end


[p, Z, xbar, permsign] = permute_signtest(resid, nperms, W, permsign);

stats.p_descrip2 = 'Intercept p-values: Based on sign permutation test';
stats.z_descrip2 = 'Intercept z-values: Based on sign permutation test';

stats.z(1,:) = Z;
stats.p(1,:) = p;
stats.permsign = permsign;

if verbose, fprintf(' Done in %3.2f s \n', etime(clock, t12)); end

end
