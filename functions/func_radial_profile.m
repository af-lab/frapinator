function y = func_radial_profile(pf_distances, parameters)
## Modified for octave and cleanliness by Carnë Draug in 2010
##
## Very heavily based in the file I got from Davide Mazza
## whom I think got it from Florian Muller

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
