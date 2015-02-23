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

## usage: [y] = fitter_radial_profile (distances, parameters)
##
## This function describes the radial intensity profile of a spot in
## 3 pieces. A first part with constant intensity (center of bleach
## spot), a second part (degradee from the center of spot to its
## edge) and a third part (unbleached after the edge of the spot).
##
## It has 3 parameters that describe the radial profile. 'rCon' is the
## width of the constant part in the center of the bleach spot that
## has no recovery. The recovery part is described by a gaussian
## distribution with variance 'sigma'. 'Theta' is the depth of the
## bleaching, i.e. the ammount of intensity left at the center of the
## bleach spot after the bleaching
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

function y = func_radial_profile(pf_distances, parameters)

  ## Get parameters
  rCon  = parameters(1);
  sigma = parameters(2);
  theta = parameters(3);


  ## Calculate intensities
  # If the condition that comes next is true, it would return nothing
  # wich would confuse (read, errors will happen and the program stop) fitting
  # routines such as leasqr
  # Plus, if this is not set in advance, then the loop that will assign its values
  # will place them in one row while the values of y that they will be compared with
  # by fitting routines are in a collumn. This would also confound them.
  y = -100*zeros(size(pf_distances));


  ## Sanity checks
  # These values make no physical sense since there's no negative
  # distances and intensity values are normalized between '0' and '1'
  # It 'returns' instead of 'error' so that if fitting routine (such
  # as leasqr or linfit) attempts to fit with such values it will skip
  # them and try other values.
  if (rCon < 0 || sigma < 0 || theta < 0 || theta  > 1)
    return
  endif


  for i = 1:rows(pf_distances)
    if pf_distances(i) == 0
      y(i) = theta;
    elseif (pf_distances(i) < rCon)
      y(i) = theta;
    else
      y(i) = 1-(1-theta)*exp(-(pf_distances(i)-rCon)^2/(2*sigma^2));
    endif
  endfor

endfunction
