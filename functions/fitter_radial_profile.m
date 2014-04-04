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
## usage: [rCon, sigma, theta, fInt, stdrsd, Z, q] = fitter_radial_profile (dis, Int, skip, res)
##
## Fits bleach spot radial intensity data (Int) along the distance (dis),
## skipping the first (skip) radial points. The resolution of the image (res)
## is taken as argument and used as initial guess value of sigma for the fitting.
##
## The function used for fitting has 3 parameters that describe the radial profile. 'rCon' is
## the width of the constant part in the center of the bleach spot that has no recovery. The
## recovery part is described by a gaussian distribution with variance 'sigma'. 'Theta' is the
## depth of the bleaching, i.e. the ammount of intensity left at the center of the bleach spot
## after the bleaching.
##
##  ^
##  |                             ×××××××××
##  |                           ××
##  |                         ××
##  |                        ×|
##  |                       ×||
##  |                      × ||
##  |                    ××  ||
##  |   rCon           ××    ||
##  |<-------->     ×××      <>
##  |          ×××××         sigma
##  |××××××××××  ^
##  |            | theta
##  |            |
##  ---------------------------------------------------->
##
## Output are the fitted three parameters (rCon, sigma, theta) to the function
## func_radial_profile, the intensity values (fInt) in that function and standardized
## residuals (stdrsd). The direct numeric integration of measured data (Z) and the
## integration of estimated profile (q) are also given to allow for comparison.
##
##
## Direct numeric integration (Z) uses the profile given (Int) to calculate
## the area under that data.
## Integration of the estimated profile (q) is to use the function with the fitted
## parameters, and calculate the area under that function given a specific interval.
## If the fitting worked well, these two values should be similar since they are 
## calculating the same thing, one using the 'raw values', and the other using the
## function with parameters fitted with those 'raw values'.
##
##
## Input ==>
##		dis		= distances of the intensities (vector)
##		Int		= normalized intensity values for intervals of 1 pixel (vector)
##		skip	= number of first points to skip when fitting (scalar)
##		res		= resolution of the image (scalar)
##
## Output ==>
##		rCon	= fitted parameter (scalar)
##		sigma	= fitted parameter (scalar)
##		theta	= fitted parameter (scalar)
##		fInt	= intensity values with the fitted parameters for intervals of 1 pixel (vector)
##		stdrsd	= standardized residuals (check help leasqr)
##		Z		= direct numeric integration of intensity values Int (scalar)
##		q		= integration of estimated profile (scalar)
##
## Important notes:
##		'Int' must be normalized from '0' (total bleach), to '1' (unbleached).
##

function [rCon sigma theta yFit stdresid Z q] = fitter_radial_profile(pf_distances, pf_values, nSkip, res)

  ## Create the vectors with the x (distance) and y (intensity) values
  # If it skips 1 point, then, the indice is 2, hence nSkip +1
  pf_distances  = pf_distances(nSkip+1:end);
  pf_values     = pf_values(nSkip+1:end);

  % Estimate starting guess for the fitting routing
  rCon    = 1;
  sigma   = res;
  theta   = mean(pf_values(1:5));
  iParam  = [rCon sigma theta];



  %% Fit
  [yFit,fParam,kvg,iter,corp,covp,covr,stdresid,confidence,r2] = leasqr (pf_distances, pf_values, iParam, @func_radial_profile, 0.00000001, 200);
  rCon	= fParam(1);
  sigma	= fParam(2);
  theta	= fParam(3);


  ## Start calculating fluorescence under the curve

  radius = pf_distances(end);
  ## Direct numeric integration of intensity values
  # Result is the average intensity under a unit of the bleach spot
  # To calculate the total intensity under the bleach spot, it's the integral of the function
  # 2*pi*radius*func_profile(radius) over radius
  #
  #  /radius                         /radius
  #  |2*pi*radius*f(radius) <=> 2*pi*|radius*f(radius) <=> 2*pi*Z
  #  /0                              /0
  #
  # To get the value by unit, this is then divided by the area of the circle
  #
  # (2*pi*Z)/(pi*radius^2) <=> (2*Z)/(radius*2)

  yr  = pf_distances .* pf_values;
  Z   = trapz(pf_distances,yr);
  Z   = 2*Z/(radius^2);

  ## Integration of estimated profile
  # Result is the average intensity under a unit of the bleach spot
  # The reason to have 2 functions here is to make the code faster. In the interval of distance
  # [0, rCon] the function is equal to the value of theta. Only after that, in the interval of
  # distance [rCon, radius] is the full function needed. To have the full function through the
  # whole interval [0, radius] would give the same result, it would just take longer.
  # The value is then mutiplied by 2*pi, and the integral divided by pi*radius^2 to give the
  # average area under a unit [pixel] of the bleach spot.
  F1  = @(distance) (2*pi*distance*theta);
  F2  = @(distance) 2*pi*distance.*(1-(1-theta)*exp(-(distance-rCon).^2/(2*sigma^2)));
  q   = (quadl(F1,0,rCon) + quadl(F2,rCon,radius))/(pi*radius^2);

endfunction
