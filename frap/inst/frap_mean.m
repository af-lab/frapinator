## Copyright (C) 2010, 2015 Carnë Draug <carandraug+dev@gmail.com>
##
## This program is free software; you can redistribute it and/or
## modify it under the terms of the GNU General Public License as
## published by the Free Software Foundation; either version 3 of the
## License, or (at your option) any later version.
##
## This program is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
## General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, see
## <http:##www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} {} frap_mean (@var{img}, @var{ind})
## Compute average for the last dimension.
##
## This is function is used to compute the mean intensity of a region over
## time, based on the indices for the first timepoint.  It broadcasts the
## indices over the other dimensions.
##
## @var{img} can have any number of dimensions.  The last dimension is
## assumed to be time.
##
## @var{ind} are linear indices for region of interest 
##
## The output is a vector with length equal to the @var{img} last dimension.
## Its first element is equal @code{mean (@var{img}(@var{ind}))}
##
## @end deftypefn

function [xy_mean] = frap_mean (img, ind)
  if (nargin != 2)
    print_usage ();
  elseif (! isnumeric (img))
    error ("frap_mean: IMG must be numeric")
  elseif (! isnumeric (ind) || ! isvector (ind) )
    error ("frap_mean: DIM must be a numeric vector")
  endif

  nd = ndims (img);
  stride = prod (size (img)(1:(nd -1)));
  dim_length = size (img, nd);
  inds = ind(:) .+ (0:stride:(numel(img)-1));
  xy_mean = mean (img (inds));
endfunction

%!test
%! a = rand (3, 3, 10);
%! t = a(1:9:90);
%! assert (frap_mean (a, 1))

%!test
%! a = rand (3, 3, 10);
%! ind = [1 3 5 6];
%! b = 0:9:89;
%! t = mean (a(ind' .+ b));
%! assert (frap_mean (a, ind), t)

%!test
%! a = rand (7, 7, 5, 10);
%! ind = [1 10 50 100 200];
%! b = 0:245:2449;
%! t = mean (a(ind' .+ b));
%! assert (frap_mean (a, ind), t)
