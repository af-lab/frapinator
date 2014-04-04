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

function frap = func_PureDiffusion (tList, Df, preProcess)


  ##  Assign parameters
  RNrel = preProcess{1};
  J1wxi = preProcess{2};
  alf2  = preProcess{3};
  U     = preProcess{4};


  ## Avoid assignment of physical irrelevant parameters by fitting routine
  if (Df < 0 || Df > 800)
    frap = -100*ones(size(tList));
    return
  endif


  ## Time points have to be stored in a a row vector
  if (rows(tList)!=1)
	  tList = tList';
  endif


  ## Calculate the FRAP recovery curve
  ea		= exp(-Df*alf2*tList);             # Exponential decay in Eq.(S.19)
  frap	= 2*(RNrel)*(U.*J1wxi)'*ea;        # Eq.(S.22)
  frap	= frap';                           # Transform to a column vector

endfunction
