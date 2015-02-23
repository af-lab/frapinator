## Copyright (C) 2008-2010 Florian Mueller
## Copyright (C) 2008-2010 Davide Mazza <shiner80@gmail.com>
## Copyright (C) 2010 Carnë Draug <carandraug+dev@gmail.com>
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, see <http://www.gnu.org/licenses/>.
##

function [f DfFit] = fitter_PureDiffusion (nr, distance, rCon, sigma, theta, bin_timestamps, bin_values, Df)





  #- Uniform bleaching profile (no numeric integration)
  if (sigma == 0)
    NNN     = 250;
  #- Gaussian bleaching profile with numeric intergration
  else
    NNN     = 500;
    nInt    = 2000;
    rInt    = linspace(rCon,nr,nInt);
    deltaR  = mean(diff(rInt));
  endif


  ## Zeros of Bessel-Function from data file
  zb1_500 = ZerosBessel1_500 (); # Read zeros in from file 
  alf     = zb1_500(1:NNN-1);		# Zeros of Bessel function without 0
  al      = [0;alf];				# Zeros of Bessel function with 0

  alf1    = al/nr;				# See definition of Alpha in Supplementary material 1
  alf2    = alf1.^2;

  ## Calculate the coefficients Uk of the Bessel expansion

  #- Uniform bleaching (Eq. (S.21) in Mueller et al., no numeric integration)
  if (sigma == 0)
    J1rCon  = besselj(1,alf*rCon/nr);
    J0      = besselj(0,alf);
    J02     = J0.^2;

    U       = (theta-1)*((2*rCon/nr)*(J1rCon./alf)./J02);
    U0      = 1+(theta-1)*(rCon/nr)^2;
    U       = [U0;U];

  #- Gaussian bleaching (Eq. (S.20)  in Mueller et al.)
  #  Numeric integration is solved with Simpson Trapezoid rule.
  else
    JJ0     = besselj(0,al);
    JJ02    = JJ0.^2;
    JJ1w    = besselj(1,alf*rCon/nr);

    T1      = [0.5*rCon^2;nr*rCon*JJ1w./alf];
    T2      = (rCon*besselj(0,al*rCon/nr) + nr*besselj(0,al)*exp(-0.5*((nr-rCon)/sigma)^2))/2;
    T3      = rInt.*exp(-0.5*((rInt-rCon)/sigma).^2);
    T4      = besselj(0,(al/nr)*rInt);
    T5      = T1+(T2+T4*T3')*deltaR;

    U       = 2*(theta-1)*T5./(JJ02*(nr^2));
    U(1)    = 1+U(1);
  endif


  ## Spatial averaging of the Bessel-function for the FRAP curve (Eq. (S.17))
  J1w       = besselj(1,alf*(distance/nr));
  J1wxi     = [1/(2*(nr/distance));J1w./alf];

  ## Assign parameters to output-structure
  preProcess{1} = nr/distance;
  preProcess{2} = J1wxi;
  preProcess{3} = alf2;
  preProcess{4} = U;

  ## Creates handle to func_PureDiffusion that takes only timestamps and Df as
  ## arguments since function feed to leasqr must have X and parameter to fit
  ## only as arguments
  func_PureDiffusion_for_fit = @(bin_timestamps,Df) func_PureDiffusion(bin_timestamps, Df, preProcess);

  [f,DfFit,kvg,iter,corp,covp,covr,stdresid,ci,r2] = leasqr (bin_timestamps, bin_values, Df, func_PureDiffusion_for_fit, 0.00000001, 200);

endfunction
