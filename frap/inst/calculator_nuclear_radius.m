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

## usage: [nr] = calculator_nuclear_radius (dis, Int, skip, res)
##
## Calculates the radius of the nucleus assuming cell is spherical (nr). It takes
## as input the total fluorescence of the cell after bleaching (fRec). This
## value should be normalized with 1 being the cell fluorescence before bleaching.
## It also takes as input 3 parameters (rCon, sigma, theta) for a piecewise function
## that define the radial profile (see func_radial_profile for documentation on the
## function).
##
## Input ==>
##		tInt	= total intensity of the cell after bleaching (scalar)
##		rCon	= parameter for the function (rCon > 0) (scalar)
##		sigma	= parameter for the function (sigma > 0) (scalar)
##		theta	= parameter for the function (0< theta <1) (scalar)
##		sLim	= radius of bleach spot, used as start value when solving nuclear radius (scalar)
##		fLim	= width of image, used as final value when solving nuclear radius (scalar)
##
## Output ==>
##		nr		= nuclear radius found with fsolve (scalar)
##
## Important notes:
##		'tInt' must be normalized value
##		'rCon' should be >0
##		'sigma' should be > 0
##		'theta' should be > 0 and < 1

function nr = calculator_nuclear_radius(tInt, rCon, sigma, theta, sLim, fLim)



  if (rCon < 0)
    error ("The paremeter 'rCon' needs to be larger than '0' (zero) but is currently '%g'", rCon);
  elseif (sigma < 0)
    error ("The paremeter 'sigma' needs to be larger than '0' (zero) but is currently '%g'", sigma);
  elseif (theta < 0 || theta > 1)
    error ("The paremeter 'theta' needs to be larger than '0' (zero) and smaller than '1' but is currently '%g'", theta);
  endif


  # Unless rCon is zero, the function can be splitted in two parts, the first being just one value
  # dependent on theta only in the interval [0 rCon]. This is only to make the code run faster.
  if (rCon != 0)
    F1		= @(r) (2*pi*r*theta);
    F2		= @(r) 2*pi*r.*(1-(1-theta)*exp(-(r-rCon).^2/(2*sigma^2)));
    fTemp	= @(nr) (quadl(F1,0,rCon) + quadl(F2,rCon,nr))/(pi*nr^2)-tInt;
  else
    F1		= @(r) 2*pi*r.*(1-(1-theta)*exp(-(r).^2/(2*sigma^2)));
    fTemp	= @(nr) quadl(F1,0,nr)/(pi*nr^2)-tInt;
  end

  ## Use fzero calculate to calculate nuclear radius (nr)
  nr = fzero(fTemp,[sLim fLim]);

endfunction
