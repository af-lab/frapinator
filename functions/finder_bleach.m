function [ind, coord, radius, boundaries] = finder_bleach (diff_bl, diameter, bl_factor)

  % Sanity checks
  %should make sure that images have the same size
  nRow = rows(diff_bl);
  nCol = columns(diff_bl);

  # Make convolution matrix
  # Diameter of spatial filter is (2*radius)+1
  # If diameter is an even number, rounding has no effect, and spatial filter will
  # have an extra pixel. If it is an odd number, rouding would always be up, and
  # spatial filter would have 2 extra pixels. By using 'floor', it will round down
  # and have no extra pixels.
  radius = floor(diameter/2);
  bl_mask = fspecial('disk', radius);
  conv_matrix = conv2(diff_bl, bl_mask, 'same');

  % Find maximum of the convolution matrix
  % If there's more than one vale in the convuluted matrix with the minimum value,
  % it gives only the first one
  # Because conv_matrix has shape 'same', the coordinates will be of the center
  conv_max = max(conv_matrix(:));
  [coord(1), coord(2)] = find(conv_matrix == conv_max, 1, 'first');


  % Make mask of bleach spot
  final_mask = zeros(nRow, nCol);
  radius = floor(radius * bl_factor);
  bl_mask = fspecial('disk', radius);
  final_mask (coord(1)-radius : coord(1)+radius, coord(2)-radius : coord(2)+radius) = bl_mask;
  ind = find (final_mask > 0);

  boundaries = bwconncomp (final_mask);
  boundaries = boundaries.PixelIdxList{1};
endfunction
