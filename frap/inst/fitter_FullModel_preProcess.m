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

function preProcess = fitter_FullModel_preProcess(nr, distance, rCon, sigma, theta, Df)




  #- Uniform bleaching profile (no numeric integration)
  if (sigma == 0)
	  NNN = 500;

  #- Gaussian bleaching profile with numeric intergration
  else
	  NNN		= 500;
	  nInt	= 2000;
	  rInt	= linspace(rCon,nr,nInt);
	  deltaR	= mean(diff(rInt));
  endif


  ## Zeros of Bessel-Function from data file
  zb1_500 = ZerosBessel1_500 (); # Read zeros in from file 
  alf		= zb1_500(1:NNN-1);       # Zeros of Bessel function without 0
  al		= [0;alf];                # Zeros of Bessel function with 0

  alf1	= al/nr;                 # See definition of Alpha in Supplementary material 1
  alf2	= alf1.^2;


  ## Calculate the coefficients Zk of the Bessel expansion
  #  Note that the coefficients are not multiplied by Feq. This multiplication
  #  is done in the function to calculate the actual FRAP curve 
  #  (circleFRAP_FM_Fun). This is necessary since Feq depends on 
  #  the binding rates and the pre-processing is only done for calculations
  #  which are independent of the binding rates.

  #- Uniform bleaching (Eq. (S.15) in Mueller et al.)
  if (sigma == 0)
	  J1rCon	= besselj(1,alf*rCon/nr);
	  J0		= besselj(0,alf);
	  J02		= J0.^2;

	  Z0		= 1+(theta-1)*(rCon/nr)^2;
	  Z		= (theta-1)*(2*rCon/nr)*(J1rCon./alf)./J02;
	  Z		= [Z0;Z];

  #- Gaussian bleaching (Eq. (S.11),(S.12) and (S.14)  in Mueller et al.)
  #  Numeric integration is implemented with Simpson Trapezoid rule.
  else
	  JJ0		=besselj(0,al);
	  JJ02	=JJ0.^2;
	  JJ1w	= besselj(1,alf*rCon/nr);

	  T1		= [0.5*rCon^2;nr*rCon*JJ1w./alf];
	  T2		= (rCon*besselj(0,al*rCon/nr) + nr*besselj(0,al)*exp(-0.5*((nr-rCon)/sigma)^2))/2;
	  T3		= rInt.*exp(-0.5*((rInt-rCon)/sigma).^2);
	  T4		= besselj(0,(al/nr)*rInt);
	  T5		= T1+(T2+T4*T3')*deltaR;

	  Z		= (theta-1)*2*T5./(JJ02*(nr^2));
	  Z(1)	= Z(1)+1;
  endif

  ## Spatial averaging of the Bessel-function for the FRAP curve (Eq. (S.17))
  J1w			= besselj(1,alf*(distance/nr));
  J1wxi		= [1;2*(nr/distance)*J1w./alf];


  ## Assign parameters to output-structure
  #parPreProcess{1} = [];      # Flag to determine which parameters are fitted
  #parPreProcess{2} = [];      # Used to store time list vector
  preProcess{1} = Df;
  preProcess{2} = J1wxi;
  preProcess{3} = alf2;
  preProcess{4} = Z;

endfunction
