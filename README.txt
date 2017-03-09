
//------------------------------------------------------------------------------
// AIRMODUS A11 inversion codes for scanning raw (.dat) data 
// by JV (joonas.vanhanen@airmodus.com)

// NOTE: These codes are used to invert A11 scanning data only!

// Inverts PSM scan data (.dat-file) into size distributions based on calibration file data
// Corrects data for diffusion losses if needed based on Gormley & Kennedy 1949
// Plots and saves inverted data

// Download Scilab from: http://www.scilab.org/download/latest

// Run A11_INVERSION_GUI.sci to invert .dat - file

// sub-functions / .sci-files used:
// diameters2.sci
// deteff_af_dia.sci
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

// NOTE: requires A11 calibration file!

// Output file format (M(row,column)) (comma separated):
// First row: Diameters for bin limits in nm (first value M(1,1) is always zero)
// Column n. 1: date (Matlab datenum format)
// Column n. 2: Total number concentration above the upper limit of size distribution (M(1,2))
// Column n. 3->: Particle number concentration in size bins in #/cc (NOTE:
// not in dN/dlogDp)

// Notation for the Dilution Factor = (Q_sample + Q_dilution) / Q_sample
// Q_sample is the volumetric sample flow rate going to the PSM (2.5 lpm)
// Q_dilution is the volumetric flow rate of the filtered dilution air

// Copyright 2016 Airmodus Ltd.

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
