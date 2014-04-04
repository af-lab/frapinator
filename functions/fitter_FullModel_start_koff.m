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

function koffT = fitter_FullModel_start_koff(valRec,tEnd,kon,preProcess)



  fTemp = @(koff)(frapTemp(koff,tEnd,kon,preProcess)-valRec);

  if (fTemp(10e+8) < 0)
    koffT = 10^4;
    disp("No good starting point determined. Maybe Df is too small?")
  else
    koffT = fzero(fTemp,[10e-8,10e+8]);
  endif

endfunction

## Subfunction to calculate recovery value
function recLevel = frapTemp(koff,tEnd,kon,preProcess)
  eps1	= 10^(-11);  #  Parameter for avoiding zero division and assuring right limiting process

  Df		= preProcess{1};
  J1wxi	= preProcess{2};
  alf2	= preProcess{3};
  E		= preProcess{4};

  Feq		= (koff+eps1)/(kon+koff+eps1);

  #- Modify E
  E		= Feq*E;          # Normalize with Feq

  ww		= 0.5*(Df*alf2+kon+koff);
  vv		= sqrt(ww.^2-koff*Df*alf2);

  bet		= ww+vv;
  gam		= ww-vv;

  AA		= -(0.5/koff)*(-ww-vv+koff).*(ww-vv)./vv;
  BB		= (0.5/koff)*(-ww+vv+koff).*(ww+vv)./vv;

  A		= AA.*E;
  B		= BB.*E;

  a		= kon*A./(-bet+koff);
  b		= kon*B./(-gam+koff+eps1);

  #- FRAP at t=0
  t			= 0;
  ea			= exp((-bet)*t);
  eb			= exp((-gam)*t);
  frapStart	= (((A+a).*J1wxi)'*ea+((B+b).*J1wxi)'*eb);

  #- FRAP at t=inf
  t			= 10^15;
  ea			= exp((-bet)*t);
  eb			= exp((-gam)*t);
  frapEnd		= (((A+a).*J1wxi)'*ea+((B+b).*J1wxi)'*eb);

  #- FRAP at tEnd
  t			= tEnd;
  ea			= exp((-bet)*t);
  eb			= exp((-gam)*t);
  frap		= (((A+a).*J1wxi)'*ea+((B+b).*J1wxi)'*eb);

  recLevel	= (frap-frapStart)/(frapEnd-frapStart);

endfunction
