function nr = calculator_nuclear_radius(tInt, rCon, sigma, theta, sLim, fLim)
## Copyright (C) WTF?
##
## Modified for octave and cleanliness by Carnë Draug in 2010
##
## Very heavily based in the file I got from Davide Mazza
## whom I think got it from Florian Muller

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
