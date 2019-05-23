
//------------------------------------------------------------------------------
// AIRMODUS A11 inversion code for scanning raw (.dat) data 
// v.1.0.1

// by Joonas Vanhanen (joonas.vanhanen@airmodus.com)

// Inverts PSM scan data into size distributions
// Corrects data for diffusion losses
// Plots and saves inverted data

// Functions / .sci-files used:
// diameters_interpolation.sci
// deteff_dia_interpolat.sci
// NORM_EXP_FIT2.sci
// EXP_FIT2.sci
// NORM_CUTOFF.sci
// CUTOFF.sci
// losses.sci
// visc.sci
// reynolds.sci
// diffuus.sci
// ltubefl.sci
// cunn.sci
// rlambda.sci
// kaasuv.sci
// averagedata.sci
// SOFT_VER_CHECK.sci
// polyfit.sci
// PSM_ERROR.sci
// PSM_NOTE.sci
// CPC_ERROR.sci

// Note: requires A11 calibration file!

// Output file format (M(row,column)) (comma separated):
// First row: Diameters for bin limits in nm (first value M(1,1) is always zero)
// Column n. 1: date (Matlab datenum format)
// Column n. 2: Total number concentration above the upper limit of size distribution (M(1,2))
// Column n. 3->: Particle number concentration in size bins in dN/dDp or in dN/dlogDp depending on the selection of the user

// Notation for the Dilution Factor = (Q_sample + Q_dilution) / Q_sample
// Q_sample is the volumetric sample flow rate going to the PSM (2.5 lpm)
// Q_dilution is the volumetric flow rate of the filtered dilution air

// Note that the time stamp in with all the data is always start of a scan
// Also the running average is over the upcoming n scans

// Copyright 2019 Airmodus Ltd.

// Licensed under the EUPL, Version 1.1 or – as soon they 
// will be approved by the European Commission - subsequent
// versions of the EUPL (the "Licence");
// You may not use this work except in compliance with the
// Licence.
// You may obtain a copy of the Licence at:

// https://joinup.ec.europa.eu/software/page/eupl5

// Unless required by applicable law or agreed to in 
// writing, software distributed under the Licence is
// distributed on an "AS IS" basis,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied.
// See the Licence for the specific language governing
// permissions and limitations under the Licence.

//------------------------------------------------------------------------------
