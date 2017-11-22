#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# BivBinResp.mod
#
# The AMPL model file.
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#*******************************************************************************
# Data
#*******************************************************************************
param N1, default 3;
param N2, default 3;
set K1 = 1..N1 ordered by Integers;
set K2 = 1..N2 ordered by Integers;
param X1 {k1 in K1} default 0;
param X2 {k2 in K2} default 0;

# This is redundant but helps keep the indexing clear
# J1, J2 follows the indexing in the paper, while Y1 and Y2
# are the values the internal variables take in bivariate binary response
set J1 = 1..2;
param Y1 {j1 in J1} = j1 - 1;
set J2 = 1..2;
param Y2 {j2 in J2} = j2 - 1;

param FYGX {j1 in J1, j2 in J2, k1 in K1, k2 in K2} in [0,1] default .5;
param PX {k1 in K1, k2 in K2} in [0,1] default .5;
param PX2GX1 {k2 in K2, k1 in K1} default .5;

#*******************************************************************************
# Derived sets/parameters
#*******************************************************************************
param beta0 default .5;
param beta1 default -.75;
param beta2 default 1;

param g1 {j1 in ({0} union J1), j2 in J2, k1 in K1} =
    if (j1 == 1) then (beta0 + beta1*Y2[j2] + beta2*X1[k1])
    else if (j1 == 0) then (-Infinity)
    else if (j1 == 2) then (+Infinity);

#*******************************************************************************
# With no first stage equation just set g2(x) = P[Y2 = 0 | X]
# Observational equivalence will then force
# F[+Infinity,u2,x] = P[Y2 = 0 | X]
# which forces the marginal of U2 to be uniform, independently of X
#*******************************************************************************
param pi0 default .3;
param pi1 default 1;
param pi2 default .2;

param ParametricFS binary default 0;
param g2 {j2 in ({0} union J2), k1 in K1, k2 in K2} =
    if (j2 == 1) then
        (if (ParametricFS) then
            (pi0 + pi1*X1[k1] + pi2*X2[k2])
        else
            (FYGX[2,1,k1,k2])
        )
    else if (j2 == 0) then (-Infinity)
    else if (j2 == 2) then (+Infinity);

set Ug1 =
    (setof {j1 in ({0} union J1), j2 in J2, k1 in K1} g1[j1,j2,k1])
    union (setof {j1 in ({0} union J1), j2 in J2, k1 in K1} -1*g1[j1,j2,k1])
    union {-Infinity, +Infinity, 0}
    ordered by Reals;

set Ug2 =
    (setof {j2 in ({0} union J2), k1 in K1, k2 in K2} g2[j2,k1,k2])
    union (setof {j2 in ({0} union J2), k1 in K1, k2 in K2} -1*g2[j2,k1,k2])
    union {-Infinity, +Infinity,0}
    ordered by Reals;

#*******************************************************************************
# Variables
#
# F is the key variable of optimization
# The other variables below are derived from it
#*******************************************************************************
var F {u1 in Ug1, u2 in Ug2, k1 in K1, k2 in K2} in [0,1] default 0;

var ASF0 = 1 - sum {k1 in K1, k2 in K2} (
    F[g1[1,1,k1], +Infinity, k1, k2]*PX[k1, k2]);
var ASF1 = 1 - sum {k1 in K1, k2 in K2} (
    F[g1[1,2,k1], +Infinity, k1, k2]*PX[k1, k2]);
var ATE = ASF1 - ASF0;

param k1fix, default 1 in K1;
param k2fix, default 1 in K2;
var ASF0Fixed = 1 - F[g1[1,1,k1fix], +Infinity, k1fix, k2fix];
var ASF1Fixed = 1 - F[g1[1,2,k1fix], +Infinity, k1fix, k2fix];
var ATEFixed = ASF1Fixed - ASF0Fixed;

#*******************************************************************************
# Objective functions
#*******************************************************************************
minimize Constant: 1; # For checking feasibility
minimize ObjMinATE: ATE;
maximize ObjMaxATE: ATE;
minimize ObjMinATEFixed: ATEFixed;
maximize ObjMaxATEFixed: ATEFixed;

#*******************************************************************************
# Observational equivalence
#*******************************************************************************
var ObsEq_Gap {j1 in J1, j2 in J2, k1 in K1, k2 in K2} =
    sum {jj2 in J2 : jj2 <= j2} (
        F[g1[j1,jj2,k1], g2[jj2,k1,k2], k1, k2]
        -
        F[g1[j1,jj2,k1], g2[jj2 - 1,k1,k2], k1, k2]
    ) - FYGX[j1,j2,k1,k2];
subject to ObsEq {j1 in J1, j2 in J2, k1 in K1, k2 in K2}:
    ObsEq_Gap[j1,j2,k1,k2] = 0;

#*******************************************************************************
# Subdistribution shape properties
#*******************************************************************************
subject to Grounded1 {u2 in Ug2, k1 in K1, k2 in K2}:
    F[-Infinity,u2,k1,k2] = 0;
subject to Grounded2 {u1 in Ug1, k1 in K1, k2 in K2}:
    F[u1,-Infinity,k1,k2] = 0;
subject to HasMargins {k1 in K1, k2 in K2}:
    F[+Infinity,+Infinity,k1,k2] = 1;
subject to Increasing {t1 in 2..card(Ug1), t2 in 2..card(Ug2),
    k1 in K1, k2 in K2}:
          F[member(t1,Ug1),member(t2,Ug2),k1,k2]
        - F[member(t1-1,Ug1),member(t2,Ug2),k1,k2]
        - F[member(t1,Ug1),member(t2-1,Ug2),k1,k2]
        + F[member(t1-1,Ug1),member(t2-1,Ug2),k1,k2] >= 0;

#*******************************************************************************
#*******************************************************************************
#*******************************************************************************
#*******************************************************************************
# SINGLE EQUATION RESTRICTIONS
#*******************************************************************************
#*******************************************************************************
#*******************************************************************************
#*******************************************************************************

#*******************************************************************************
# U1 | Y2, X1 has median 0. Not using X2 at all here.
#*******************************************************************************
subject to U1MedZeroGivenY2X1 {j2 in J2, k1 in K1}:
    (sum {k2 in K2} (
        (F[0,g2[j2,k1,k2],k1,k2] - F[0,g2[j2-1,k1,k2],k1,k2])
        *PX2GX1[k2,k1]
    ))
    /
    (if (j2 == 2)
        then (sum {k2 in K2}
            ((1 - FYGX[2,1,k1,k2])*PX2GX1[k2,k1])
        )
        else (sum {k2 in K2}
            ((FYGX[2,1,k1,k2])*PX2GX1[k2,k1])
        )
    )
    = .5;

#*******************************************************************************
# U1 independent of (Y2, X1)---not using X2 here
# base group is Y2 = 0, X1 = min(X1)
#*******************************************************************************
subject to U1IndY2X1 {u1 in Ug1, j2 in J2, k1 in K1}:
    (sum {k2 in K2} (
        (F[u1,g2[j2,k1,k2],k1,k2] - F[u1,g2[j2-1,k1,k2],k1,k2])
        *PX2GX1[k2,k1]
    ))
    /
    (if (j2 == 2)
        then (sum {k2 in K2}
            ((1 - FYGX[2,1,k1,k2])*PX2GX1[k2,k1])
        )
        else (sum {k2 in K2}
            ((FYGX[2,1,k1,k2])*PX2GX1[k2,k1])
        )
    )
    =
    (sum {k2 in K2} (
        F[u1,g2[1,member(1,K1),k2],member(1,K1),k2]
        *PX2GX1[k2,member(1,K1)]
    ))
    /
    (sum {k2 in K2} (
        FYGX[2,1,member(1,K1),k2]*PX2GX1[k2,member(1,K1)]
    ));

#*******************************************************************************
# Imposes Symmetry around 0 for U1 given Y2, X1
#
# P[U1 <= u1 | Y2, X1] = 1 - P[U1 <= -u1 | Y2, X1]
#*******************************************************************************
subject to U1SymmetricGivenY2X1 {u1 in Ug1, j2 in J2, k1 in K1}:
    (sum {k2 in K2} (
        (F[u1,g2[j2,k1,k2],k1,k2] - F[u1,g2[j2-1,k1,k2],k1,k2])
        *PX2GX1[k2,k1]
    ))
    /
    (if (j2 == 2)
        then (sum {k2 in K2}
            ((1 - FYGX[2,1,k1,k2])*PX2GX1[k2,k1])
        )
        else (sum {k2 in K2}
            ((FYGX[2,1,k1,k2])*PX2GX1[k2,k1])
        )
    )
    =
    1 -
    (sum {k2 in K2} (
        (F[-u1,g2[j2,k1,k2],k1,k2] - F[-u1,g2[j2-1,k1,k2],k1,k2])
        *PX2GX1[k2,k1]
    ))
    /
    (if (j2 == 2)
        then (sum {k2 in K2}
            ((1 - FYGX[2,1,k1,k2])*PX2GX1[k2,k1])
        )
        else (sum {k2 in K2}
            (FYGX[2,1,k1,k2]*PX2GX1[k2,k1])
        )
    );

#*******************************************************************************
# This imposes U1 | Y2, X1, X2 has median 0
#
# This is
# P[U1 <= 0 | Y2 = j2, X1 = k1, X2 = k2]
# =
# (P[U1<=0, U2<=g(j2,k1,k2) | k1,k2] - P[U1<=0, U2<=g(j2-1,k1,k2)|k1,k2])
# /
# (P[Y2 <= j2 | X1 = k1, X2 = k2] - P[Y2 <= j2 - 1 | X1 = k1, X2 = k2])
# =
# 1/2
#*******************************************************************************
subject to U1MedZeroGivenY2X1X2 {j2 in J2, k1 in K1, k2 in K2}:
    (F[0,g2[j2,k1,k2],k1,k2] - F[0,g2[j2-1,k1,k2],k1,k2])
    /
    (if (j2 == 2) then (1 - FYGX[2,1,k1,k2])
        else (FYGX[2,1,k1,k2]))
    = .5;

#*******************************************************************************
# This imposes U1 is independent of Y2, X1, X2
#
# The base group here is Y2 = 0, X1 = min(X1), X2 = min(X2);
#*******************************************************************************
subject to U1IndY2X1X2 {u1 in Ug1, j2 in J2, k1 in K1, k2 in K2}:
    (F[u1,g2[j2,k1,k2],k1,k2] - F[u1,g2[j2-1,k1,k2],k1,k2])
    /
    (if (j2 == 2) then (1 - FYGX[2,1,k1,k2])
        else (FYGX[2,1,k1,k2]))
    =
    F[u1,g2[1,member(1,K1),member(1,K2)],member(1,K1),member(1,K2)]
    /
    FYGX[2,1,member(1,K1),member(1,K2)];

#*******************************************************************************
# This imposes U1 is independent of Y2 given X1,X2
#
# Base group here is Y2 = 0
#*******************************************************************************
subject to U1IndY2GivenX1X2 {u1 in Ug1, j2 in J2, k1 in K1, k2 in K2}:
    (F[u1,g2[j2,k1,k2],k1,k2] - F[u1,g2[j2-1,k1,k2],k1,k2])
    /
    (if (j2 == 2) then (1 - FYGX[2,1,k1,k2])
        else (FYGX[2,1,k1,k2]))
    =
    F[u1,g2[1,k1,k2],k1,k2]/FYGX[2,1,k1,k2];

#*******************************************************************************
# Imposes Symmetry around 0 for U1 given Y2, X1, X2
#
# P[U1 <= u1 | Y2, X1, X2] = 1 - P[U1 <= -u1 | Y2, X1, X2]
#*******************************************************************************
subject to U1SymmetricGivenY2X1X2 {u1 in Ug1, j2 in J2, k1 in K1, k2 in K2}:
    (F[u1,g2[j2,k1,k2],k1,k2] - F[u1,g2[j2-1,k1,k2],k1,k2])
    /
    (if (j2 == 2) then (1 - FYGX[2,1,k1,k2])
        else (FYGX[2,1,k1,k2]))
    =
    1 -
    (F[-u1,g2[j2,k1,k2],k1,k2] - F[-u1,g2[j2-1,k1,k2],k1,k2])
    /
    (if (j2 == 2) then (1 - FYGX[2,1,k1,k2])
        else (FYGX[2,1,k1,k2]));

#*******************************************************************************
#*******************************************************************************
#*******************************************************************************
#*******************************************************************************
# SINGLE EQUATION INSTRUMENT RESTRICTIONS
#*******************************************************************************
#*******************************************************************************
#*******************************************************************************
#*******************************************************************************

#*******************************************************************************
# This is just P[U1 <= 0 | X1, X2] = .5
# But not conditioning on Y2 as above
#*******************************************************************************
subject to U1MedZeroGivenX1X2 {k1 in K1, k2 in K2}:
    F[0,+Infinity,k1,k2] = .5;

#*******************************************************************************
# U1 independent of (X1,X2)
#*******************************************************************************
subject to U1IndX1X2 {u1 in Ug1, k1 in K1, k2 in K2}:
    F[u1,+Infinity,k1,k2] = F[u1,+Infinity,member(1,K1),member(1,K2)];

#*******************************************************************************
# U1 given (X1,X2) is symmetric around 0
#*******************************************************************************
subject to U1SymmetricGivenX1X2 {u1 in Ug1, k1 in K1, k2 in K2}:
    F[u1,+Infinity,k1,k2] = 1 - F[-u1,+Infinity,k1,k2];

#*******************************************************************************
#*******************************************************************************
#*******************************************************************************
#*******************************************************************************
# TRIANGULAR MODEL RESTRICTIONS
#*******************************************************************************
#*******************************************************************************
#*******************************************************************************
#*******************************************************************************

#*******************************************************************************
# (U1,U2) independent of (X1,X2)
#*******************************************************************************
subject to U1U2IndX1X2 {u1 in Ug1, u2 in Ug2, k1 in K1, k2 in K2}:
    F[u1,u2,k1,k2] = F[u1,u2,member(1,K1),member(1,K2)];

#*******************************************************************************
# U2 median 0 conditional on (X1,X2)
#*******************************************************************************
subject to U2MedZeroGivenX1X2 {k1 in K1, k2 in K2}:
    F[+Infinity,0,k1,k2] = .5;

#*******************************************************************************
# U2 symmetric around 0 conditional on (X1,X2)
#*******************************************************************************
subject to U2SymmetricGivenX1X2 {u2 in Ug2, k1 in K1, k2 in K2}:
    F[+Infinity, u2, k1, k2] = 1 - F[+Infinity, -u2, k1, k2];
