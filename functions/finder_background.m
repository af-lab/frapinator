function [ind, boundaries] = finder_background(image_here, bg_size)

  # Sanity checks
  nRow = rows(image_here);
  nCol = columns(image_here);

  if (bg_size > nRow || bg_size > nCol)
    error("Size choosen for background area is larger than image. Image has %g[px] of width and %g[px] of heigth while the background area is asked to have %g[px] of size", nCol, nRow, bg_size)
  elseif (nRow == bg_size)
    warning("Heigth of the image (%g) is the same as the heigth of the background area (%g).", nRow, bg_size)
  elseif (nCol == bg_size)
    warning("Width of the image (%g) is the same as the width of the background area (%g).", nRow, bg_size)
  endif

  # Make convolution matrix
  bg_mask = ones(bg_size);
  conv_matrix = conv2(double(image_here), bg_mask, 'valid');

  # Find minimum of the convolution matrix
  # If there's more than one vale in the convuluted matrix with the minimum value,
  # it gives only the first one
  conv_min = min(conv_matrix(:));
  [coord(1), coord(2)] = find(conv_matrix == conv_min, 1, 'first');
  fRow = coord(1)+bg_size-1;
  fCol = coord(2)+bg_size-1;


  # Create mask and get the index for background
  im_mask = zeros(nRow, nCol);
  im_mask (coord(1):fRow, coord(2):fCol) = 1;
  ind = find(im_mask > 0);

  boundaries = bwconncomp (im_mask);
  boundaries = boundaries.PixelIdxList{1};
endfunction
