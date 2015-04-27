## Copyright (C) 2010, 2015 Carnë Draug <carandraug+dev@gmail.com>
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

## usage: [timestamps, time_interval] = lsm_read(file)
##
## Argument 'file' must be path for a lsm file. Output is a an array with the
## real timestamps of each image and a scalar value with the set imaging time
## interval.
## 
## Based on the documentation at
##  * http://en.wikipedia.org/wiki/Tagged_Image_File_Format
##  * http://partners.adobe.com/public/developer/en/tiff/TIFF6.pdf
##  * http://ibb.gsf.de/homepage/karsten.rodenacker/IDL/Lsmfile.doc
##  * http://www.awaresystems.be/imaging/tiff/faq.html
##
## * On the TIFF image file header:
##     bytes 00-01 --> byte order used within the file: "II" for little endian
##                     and "MM" for big endian byte ordering.
##     bytes 02-03 --> number 42 that identifies the file as TIFF
##     bytes 04-07 --> file offset (in bytes) of the first IFD (Image File Directory)
##
##   Note: offset is always from the start of the file ("bof" in fread) and first
##   byte has an offset of zero.
##
## * On a TIFF's IFD structure:
##     bytes 00-01 --> number of entries (or tags or fields or directories)
##     bytes 02-13 --> the entry (the tag is repeated the number of times
##                     specified at the start of the IFD, but always takes
##                     12 bytes of size)
##     bytes XX-XX --> file offset for next IFD (last 4 bytes of the IFD)
##
##   Note: there must be always one IFD and each IFD must have at least one entry
##
## * On an IFD entry (or TIFF's field) structure:
##     bytes 00-01 --> tag that identifies the entry
##     bytes 02-03 --> entry type
##                      1  --> BYTE (uint8)
##                      2  --> ASCII
##                      3  --> SHORT (uint16)
##                      4  --> LONG (uint32)
##                      5  --> RATIONAL (two LONGS)
##                      6  --> SBYTE (int8)
##                      7  --> UNDEFINED (8 bit)
##                      8  --> SSHORT (int16)
##                      9  --> SLONG (int32)
##                      10 --> FLOAT (single IEEE precision)
##                      11 --> DOUBLE (double IEEE precision)
##     bytes 04-07 --> number of values
##     bytes 08-11 --> file offset to the value or value (only if it fits in 4 bytes)
##
##   Note: file offset of the value may point anywhere in the file, even after the image.
##
## * On the LSM 5 structure:
##     (tag == 34412) --> CZ-private tag
##                        file offset for a structure with LSM-specific data and
##                        only exists on the first IFD
##
##   Other interesting entries in the LSM IFD:
##     (tag == 254) --> TIF_NEWSUBFILETYPE
##                      value 0 --> image
##                      value 1 --> thumbnail
##     (tag == 257) --> TIF_IMAGELENGTH
##                       --> Plane
##                       --> Stack
##                       --> Timeseries Plane
##                       --> z-Scan
##                       --> Timeseries z-Scan
##                       --> Timeseries Line
##                       --> Timeseries Mean-of-ROIs
##                       --> Line
##     (tag == 277) --> TIF_SAMPLESPERPIXEL
##                       Numer of channels
##
## * On the CZ-private tag structure:
##     bytes 000-003 --> uint32 MagicNumber (defines LSM file version)
##                        0x00300494C --> version 1.3
##                        0x00400494C --> version 1.5, 1.6 and 2.0
##     bytes 004-007 --> sint32 StructureSize
##     bytes 008-011 --> sint32 DimensionX
##     bytes 012-015 --> sint32 DimensionY
##     bytes 016-019 --> sint32 DimensionZ
##     bytes 020-023 --> sint32 DimensionChannels
##     bytes 024-027 --> sint32 DimensionTime
##     bytes 028-031 --> sint32 IntensityDataType
##                        1 --> 8-bit unsigned intenger
##                        2 --> 12-bit unsigned intenger
##                        5 --> 32-bit float
##                        0 --> different data types for each channel
##     bytes 032-035 --> sint32 ThumbnailX
##     bytes 036-039 --> sint32 ThumbnailY
##     bytes 040-047 --> float64 VoxelSizeX
##     bytes 048-055 --> float64 VoxelSizeY
##     bytes 056-063 --> float64 VoxelSizeZ
##     bytes 064-071 --> float64 OriginX
##     bytes 072-079 --> float64 originY
##     bytes 080-087 --> float64 OriginZ
##     bytes 088-089 --> uint16 ScanType
##                        0 --> normal x-y-z scan
##                        1 --> Z-scan
##                        2 --> Line scan
##                        3 --> Time series x-y
##                        4 --> Time series x-z (release 2.0)
##                        5 --> Time series - mean of ROIs (release 2.0)
##     bytes 090-091 --> uint16 SpectralScan
##     bytes 092-095 --> uint32 DataType
##     bytes 096-099 --> uint32 OffsetVectorOverlay
##     bytes 100-103 --> uint32 OffsetInputLut
##     bytes 104-107 --> uint32 OffsetOutputLut
##     bytes 108-111 --> uint32 OffsetChannelColors
##     bytes 112-119 --> float64 TimeInterval
##                        Time interval for time series in seconds. Can
##                        be 0 (zero) it no timeseries or there is more
##                        detailed information in OffsetTimeStamps.
##     bytes 120-123 --> uint32 OffsetChannelDataTypes
##     bytes 124-127 --> uint32 OffsetScanInformation
##                        File offset to a structure with informations of
##                        the device settings used to scan the image.
##     bytes 128-131 --> uint32 OffsetKsData
##     bytes 132-135 --> uint32 OffsetTimeStamps
##                        File offset to a structure containing the real
##                        scan time for each time index.
##     bytes 136-139 --> uint32 OffsetEvenList
##     bytes 140-143 --> uint32 OffsetRoi
##     bytes 144-147 --> uint32 OffsetBleachRoi
##     bytes 148-151 --> uint32 OffsetNextRecording
##     bytes 152-156 --> uint32 Reserved
##                        Must be 0 (zero)
##
## * On the u32OffsetTimeStamps field:
##     bytes 00-04 --> sint32 Size
##                      Size, in bytes, of the whole block used for timestamps.
##     bytes 04-07 --> sint32 NumberTimeStamps
##                      Number of timestamps in the list
##     bytes 08-15 --> float64 TimeStamp1
##                      Timestamp in seconds
##     bytes 16-23 --> float64 TimeStamp2
##                      Timestamp in seconds
##     bytes XX-XX --> float64 TimeStampN
##
##   Note: Timestamps are in seconds relative to the start time of the LSM 510
##   electronic module controller program.

function [timestamps, time_interval] = frap_read_lsm_timepoints (file)
  offset_CZ = tiff_tag_read (file, 34412);

  [FID, msg] = fopen (file, "r", "native");
  if (msg != 0)
    error ("Unable to fopen '%s': %s.", file, msg);
  endif

  # Read byte order
  byte_order = fread(FID, 2, "char=>char");
  if ( strcmp(byte_order', "II") )
    arch = "ieee-le";                             # IEEE little endian format
  elseif ( strcmp(byte_order',"MM") )
    arch = "ieee-be";                             # IEEE big endian format
  else
    error("First 2 bytes of header returned '%s'. TIFF file expects either 'II' or 'MM'.", byte_order');
  endif

  byte.TimeInterval     = offset_CZ + 112;
  byte.OffsetTimeStamps = offset_CZ + 132;
  byte.Reserved         = offset_CZ + 152;

  # Confirm we are the right place
  status = fseek(FID, byte.Reserved, "bof");
  if (status != 0)
    error("Error on fseek when moving to byte %g (Reserved).", byte.Reserved);
  endif
  CZ_check = fread (FID, 1, "uint32", arch);
  if (CZ_check != 0)
    error("Unable to find reserved in CZ-private tag at file offset %g.", offset_CZ)
  endif

  # Read TimeInterval (bytes 88-95)
  status = fseek(FID, byte.TimeInterval, "bof");
  if (status != 0)
    error("Error on fseek when moving to byte %g (TimeInterval).", byte.TimeInterval);
  endif
  time_interval = fread (FID, 1, "float64", arch);

  # Read OffsetTimeStamps (bytes 108-111)
  status = fseek(FID, byte.OffsetTimeStamps, "bof");
  if (status != 0)
    error("Error on fseek when moving to byte %g (OffsetTimeStamps).", byte.OffsetTimeStamps);
  endif
  offset_timestamps = fread (FID, 1, "uint32", arch);

  # Read and calculate timestamps
  if (offset_timestamps == 0)
    error("No file offset for the timestamps found. Is image a time-series?");
  endif
  status = fseek(FID, offset_timestamps, "bof");
  if (status != 0)
    error("Error on fseek when moving to %g as pointed by OffsetTimeStamps.", offset_timestamps);
  endif
  bytesize    = fread (FID, 1, "int32", arch);
  number      = fread (FID, 1, "int32", arch);
  timestamps  = fread (FID, number, "float64", arch);
  timestamps -= timestamps(1);

  fclose (FID);
endfunction
