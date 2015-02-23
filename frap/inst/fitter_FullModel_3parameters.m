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

function [f, fkon, fkoff, Df, iter] = fitter_FullModel_3parameters(bin_timestamps, bin_values, preProcess, ikon, ikoff, Df)


  flag_fit = 3;

  iParam = [ikon, ikoff, Df];
  func_FullModel_for_fit	= @(bin_timestamps, iParam) func_FullModel (bin_timestamps, iParam, preProcess, flag_fit);

  [f,fParam,kvg,iter,corp,covp,covr,stdresid,ci,r2] = leasqr (bin_timestamps, bin_values, iParam, func_FullModel_for_fit, 0.00000001, 200);

  fkon	= fParam(1);
  fkoff	= fParam(2);
  Df		= fParam(3);

endfunction
