%*******************************************************************************
% GenerateDGP.m
%
% Generate DGP quantities from Settings
%*******************************************************************************
function DGP = GenerateDGP(Settings)
    %***************************************************************************
    % Distribution of X1 is always uniform discrete
    % Distribution of X2 can either be uniform discrete or continuous
    %   If continuous, then uniform over [-2, 2]
    % In either case they are taken to be independent
    %***************************************************************************
    DGP.X1 = ...
         ((1:1:Settings.N1)' + floor(Settings.N1/2) - Settings.N1)...
        /((Settings.N1 - 1)/2);

    if Settings.Continuous
        QSpacing = 1/(Settings.N2+1);
        QList = QSpacing:QSpacing:(1 - QSpacing);
        DGP.X2 = unifinv(QList, -2, 2);

        % Make sure (0,0) is in the support
        DGP.X2 = [DGP.X2(:); 0];
        DGP.X2 = unique(DGP.X2);
        DGP.X1 = [DGP.X1(:); 0];
        DGP.X1 = unique(DGP.X1);
    else
        DGP.X2 = (1:1:Settings.N2)' + floor(Settings.N2/2) - Settings.N2;
    end
    % Joint probability of (X1, X2)
    DGP.PX = (1/length(DGP.X1))*(1/length(DGP.X2))...
                *ones(length(DGP.X1), length(DGP.X2));

    % Probability of X2 given X1
    DGP.PX2GX1 = nan(length(DGP.X2), length(DGP.X1));
    for k2 = 1:1:length(DGP.X2)
        for k1 = 1:1:length(DGP.X1)
            DGP.PX2GX1(k2,k1) = DGP.PX(k1,k2)/sum(DGP.PX(k1,:));
        end
    end

    %***************************************************************************
    % Generate conditional probabilities of Y observed in the data
    %***************************************************************************
    DGP.g1 = @(y2, x1) Settings.Beta0 + Settings.Beta1*y2 + Settings.Beta2*x1;
    for j2 = 1:1:2
        for k1 = 1:1:length(DGP.X1)
            DGP.PrU1LTg1(j2, k1) = ...
                normcdf(DGP.g1(j2-1,DGP.X1(k1)), 0, Settings.Sigma1);
        end
    end

    DGP.g2 = @(x1, x2) Settings.Pi0 + Settings.Pi1*x1 + Settings.Pi2*x2;
    for k1 = 1:1:length(DGP.X1)
        for k2 = 1:1:length(DGP.X2)
            DGP.PrU2LTg2(k1,k2) = ...
                normcdf(DGP.g2(DGP.X1(k1), DGP.X2(k2)), 0, ...
                    Settings.Sigma2);
        end
    end

    DGP.PrYGX = nan(2,2,length(DGP.X1), length(DGP.X2));
    DGP.FYGX = nan(2,2,length(DGP.X1), length(DGP.X2));
    for k1 = 1:1:length(DGP.X1)
        for k2 = 1:1:length(DGP.X2)
            % Clayton copula with parameter theta
            % Taking theta = 1 corresponds to independence
            DGP.PrYGX(1,1,k1,k2) = ...
            exp(-1*(...
                (-log(DGP.PrU1LTg1(1,k1)))^Settings.Theta ...
                + ...
                (-log(DGP.PrU2LTg2(k1,k2)))^Settings.Theta ...
            )^(1/Settings.Theta));

            DGP.PrYGX(1,2,k1,k2) = DGP.PrU1LTg1(2, k1) - ...
            exp(-1*(...
                (-log(DGP.PrU1LTg1(2,k1)))^Settings.Theta ...
                + ...
                (-log(DGP.PrU2LTg2(k1,k2)))^Settings.Theta ...
            )^(1/Settings.Theta));

            DGP.PrYGX(2,1,k1,k2) = DGP.PrU2LTg2(k1, k2) - ...
            exp(-1*(...
                (-log(DGP.PrU1LTg1(1,k1)))^Settings.Theta ...
                + ...
                (-log(DGP.PrU2LTg2(k1,k2)))^Settings.Theta ...
            )^(1/Settings.Theta));

            DGP.PrYGX(2,2,k1,k2) = 1 - DGP.PrYGX(1,1,k1,k2) ...
                - DGP.PrYGX(1,2,k1,k2) - DGP.PrYGX(2,1,k1,k2);

            DGP.FYGX(1,1,k1,k2) = DGP.PrYGX(1,1,k1,k2);
            DGP.FYGX(1,2,k1,k2) = DGP.PrYGX(1,1,k1,k2) + DGP.PrYGX(1,2,k1,k2);
            DGP.FYGX(2,1,k1,k2) = DGP.PrYGX(1,1,k1,k2) + DGP.PrYGX(2,1,k1,k2);
            DGP.FYGX(2,2,k1,k2) = 1;
        end
    end

    % Value of the ASF and ATE in the DGP
    DGP.ASF = ones(2,1);
    if ~Settings.Continuous
        for k1 = 1:1:length(DGP.X1)
            for k2 = 1:1:length(DGP.X2)
                for j2 = 1:1:2
                    DGP.ASF(j2) = DGP.ASF(j2) - ...
                        normcdf(DGP.g1(j2-1, DGP.X1(k1)),...
                            0, Settings.Sigma1)*DGP.PX(k1,k2);
                end
            end
        end
    else
        DGP.ASF(1) = 1 - normcdf(DGP.g1(0, 0), 0, Settings.Sigma1);
        DGP.ASF(2) = 1 - normcdf(DGP.g1(1, 0), 0, Settings.Sigma1);
    end
    DGP.ATE = DGP.ASF(2) - DGP.ASF(1);
end
