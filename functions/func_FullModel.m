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

function frap = func_FullModel (tList, parameters, preProcess, flag_fit)


  ## Assign parameters
  J1wxi	= preProcess{2};
  alf2	= preProcess{3};
  Z		= preProcess{4};


  ## Estimate set of parameters that will be fitted
  if (flag_fit == 2)		# Fit for kon, koff
	  kon		= parameters(1);
	  koff	= parameters(2);

	  Df		= preProcess{1};
  elseif (flag_fit == 3)	# Fit for kon, koff, Df
	  kon		= parameters(1);
	  koff	= parameters(2);
	  Df		= parameters(3);
  else
	  error("Wrong flag when fitting for full model. Value must be '2' or '3' but has a value of '%g'", flag_fit);
  end


  ## Time points have to be stored in a a row vector
  if (rows(tList)!=1)
	  tList = tList';
  endif


  ## Avoid assignment of physical irrelevant parameters by fitting routine
  if (kon < 10e-5 || kon > 10e+5 || koff < 10e-5 || koff > 10e+5  || Df < 0 || Df > 20000)
	  frap = -100*ones(size(tList'));
	  return
  endif


  ## Calculation of FRAP curve
  eps1	= 10^(-11);    #  To avoid division by zero and assuring right limiting process
  Feq		= (koff+eps1)/(kon+koff+eps1);

  #- Multiply Z with Feq (Compare Eqs. (S.12) and (S.15) in Mueller et al.) 
  #  This step is performed here since Feq depends on the binding rates and
  #  thus can not be calcuated in the pre-processing step.
  Z		= Feq*Z;

  #- Calculate exponential decay rates (Eq. (S.4))
  ww		= 0.5*(Df*alf2+kon+koff);
  vv		= sqrt(ww.^2-koff*Df*alf2);

  bet		= ww+vv;
  gam		= ww-vv;

  ea		= exp((-bet)*tList);
  eb		= exp((-gam)*tList);

  #- Calculate coeffiecients of series expansion 
  UU		= -(0.5/koff)*(-ww-vv+koff).*(ww-vv)./vv;     # Eq. (S.11)
  VV		= (0.5/koff)*(-ww+vv+koff).*(ww+vv)./vv;      # Eq. (S.11)

  U		= UU.*Z;                                      # Eq. (S.11)
  V		= VV.*Z;                                      # Eq. (S.11)

  W		= kon*U./(-bet+koff);                         # Eq. (S.10)
  X		= kon*V./(-gam+koff+eps1);                    # Eq. (S.10)

  #- Calculate FRAP curve
  frap	= (((U+W).*J1wxi)'*ea+((V+X).*J1wxi)'*eb);    # Eq. (S.16)
  frap	= vec (frap);                                      # Transform to a column vector

endfunction
