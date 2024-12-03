--
-- PostgreSQL database dump
--

-- Dumped from database version 17.2
-- Dumped by pg_dump version 17.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: t_dataset_qc_metric_names; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_dataset_qc_metric_names (metric, source, category, short_description, metric_group, metric_value, units, optimal, purpose, description, ignored, sort_key) FROM stdin;
amts_10pct_fdr	VIPER	MS1 Signal	VIPER	Peptide counts	peptides	Count	Higher	Total number of identified LC-MS features	Number of LC-MS features	0	-10
amts_25pct_fdr	VIPER	MS1 Signal	VIPER	Peptide counts	peptides	Count	Higher	Total number of identified LC-MS features	Number of LC-MS features	0	-9
c_1a	SMAQC	Chromatography	Peptides from fronted peaks	Fraction of repeat peptide IDs with divergent RT	-4 min	Fraction	Lower	Estimates very early peak broadening	Fraction of peptides identified more than 4 minutes earlier than the chromatographic peak apex (MSGFSpecProb < 1E-12)	0	45
c_1b	SMAQC	Chromatography	Peptides from tailed peaks	Fraction of repeat peptide IDs with divergent RT	+4 min	Fraction	Lower	Estimates very late peak broadening	Fraction of peptides identified more than 4 minutes later than the chromatographic peak apex (MSGFSpecProb < 1E-12)	0	46
c_2a	SMAQC	Chromatography	Richest ID RT range	Interquartile retention time period	Period (min)	Minutes	Higher	Longer times indicate better chromatographic separation	Time period over which 50% of peptides are identified (MSGFSpecProb < 1E-12)	0	47
c_2b	SMAQC	Chromatography	ID rate in C_2A	Interquartile retention time period	Pep ID rate	Peps/min	Higher	Higher rates indicate efficient sampling and identification	Rate of peptide identification during C_2A (MSGFSpecProb < 1E-12)	0	48
c_3a	SMAQC	Chromatography	Peak width	Peak width at half-height for IDs	Median value	Seconds	Lower	Sharper peak widths indicate better chromatographic separation	Median peak width for all peptides	0	49
c_3b	SMAQC	Chromatography	Peak width, middle 50%	Peak width at half-height for IDs	Interquartile distance	Seconds	Lower	Tighter distributions indicate more peak width uniformity	Median peak width during middle 50% of separation	0	50
c_4a	SMAQC	Chromatography	Peak width, first 10%	Peak widths at half-max over RT deciles for IDs	First decile	Seconds	Lower	Estimates peak widths at the beginning of the gradient	Median peak width during first 10% of separation	0	51
c_4b	SMAQC	Chromatography	Peak width, last 10%	Peak widths at half-max over RT deciles for IDs	Last decile	Seconds	Lower	Estimates peak widths at the end of the gradient	Median peak width during last 10% of separation	0	52
c_4c	SMAQC	Chromatography	Peak width, middle 10%	Peak widths at half-max over RT deciles for IDs	Median value	Seconds	Lower	Estimates peak widths in the middle of the gradient	Median peak width during middle 10% of separation	0	53
c_5a	SMAQC	Chromatography	Ignore	Average elution order differences	Between	Percent	Lower	Estimates peptide elution similarity run to run	Ignore: Average difference in elution order	1	54
c_5b	SMAQC	Chromatography	Ignore	Average elution order differences	Betw/in	Ratio	Lower	Estimates peptide elution similarity between series	Ignore: Ratio of average difference in elution order	1	55
c_6a	SMAQC	Chromatography	Ignore	Fraction of extra early eluting peptides in row series	Between	Fraction	Lower	Used to detect differences in the numbers of early peptides	Ignore: Fraction of extra early eluting peptides in row series	1	56
c_6b	SMAQC	Chromatography	Ignore	Fraction of extra late eluting peptides in row series	Between	Fraction	Lower	Used to detect differences in the numbers of late peptides	Ignore: Fraction of extra late eluting peptides in row series	1	57
ds_1a	SMAQC	Dynamic Sampling	Ratio 1 spec / 2 spec	Ratio of peptide ions IDed by different numbers of spectra	Once/twice	Ratio	Higher	Estimates oversampling	Count of peptides with one spectrum / count of peptides with two spectra (MSGFSpecProb < 1E-12)	0	58
ds_1b	SMAQC	Dynamic Sampling	Ratio 2 spec / 3 spec	Ratio of peptide ions IDed by different numbers of spectra	Twice/thrice	Ratio	Higher	Estimates oversampling	Count of peptides with two spectra / count of peptides with three spectra (MSGFSpecProb < 1E-12)	0	59
ds_2a	SMAQC	Dynamic Sampling	MS1 scan count in C_2A	Spectrum counts	MS1 scans/full	Count	Lower	Fewer MS1 scans indicates more sampling	Number of MS1 scans taken over middle 50% of separation	0	60
ds_2b	SMAQC	Dynamic Sampling	MS2 scan count in C_2A	Spectrum counts	MS2 scans	Count	Higher	More MS2 scans indicates more sampling	Number of MS2 scans taken over middle 50% of separation	0	61
ds_3a	SMAQC	Dynamic Sampling	MS1 max / observed	MS1 max / MS1 sampled abundance ratio IDs	Median all IDs	Ratio	Lower	Estimates position on peak where sampled for peptides of all abundances	Median of MS1 max / MS1 sampled abundance (use PSMs with MSGFSpecProb < 1E-12)	0	62
ds_3b	SMAQC	Dynamic Sampling	MS1 max / observed, low abu	MS1 max/ MS1 sampled abundance ratio IDs	Med bottom 1/2	Ratio	Lower	Estimates position on peak where sampled for  least  abundant 50% of peptides	Median of MS1 max / MS1 sampled abundance; limit to bottom 50% of peptides by abundance (use PSMs with MSGFSpecProb < 1E-12)	0	63
is_1a	SMAQC	Ion Source	MS1 jump 10x	MS1 during middle (and early) peptide retention period	MS1 jumps >10x	Count	Lower	Flags ESI instability	Occurrences of MS1 jumping >10x	0	64
is_1b	SMAQC	Ion Source	MS1 fall 10x	MS1 during middle (and early) peptide retention period	MS1 falls >10x	Count	Lower	Flags ESI instability	Occurrences of MS1 falling >10x	0	65
is_2	SMAQC	Ion Source	Median precursor m/z	Precursor m/z for IDs	Median	Th	Lower	Higher median m/z can correlate with inefficient or partial ionization	Median precursor m/z for all peptides (MSGFSpecProb < 1E-12)	0	66
is_3a	SMAQC	Ion Source	Count 1+ / 2+	IDs by charge state (relative to 2+)	Charge 1+	Ratio	Lower	High ratio of 1+ / 2+  peptides may indicate inefficient ionization	Count of 1+ peptides / count of 2+ peptides (MSGFSpecProb < 1E-12)	0	67
is_3b	SMAQC	Ion Source	Count 3+ / 2+	IDs by charge state (relative to 2+)	Charge 3+	Ratio	Lower	High ratio of 3+ / 2+  peptides may indicate inefficient ionization	Count of 3+ peptides / count of 2+ peptides (MSGFSpecProb < 1E-12)	0	68
is_3c	SMAQC	Ion Source	Count 4+ / 2+	IDs by charge state (relative to 2+)	Charge 4+	Ratio	Lower	High ratio of 4+ / 2+  peptides may indicate inefficient ionization	Count of 4+ peptides / count of 2+ peptides (MSGFSpecProb < 1E-12)	0	69
keratin_2a	SMAQC	Peptide Identification	Total keratin PSMs	Peptide counts	Identifications	Count	Lower	Higher values mean higher contamination during sample prep	Number of keratin peptides (full or partial trypsin); total spectra count (MSGFSpecProb < 1E-12)	0	95
keratin_2c	SMAQC	Peptide Identification	Unique keratin peptides	Peptide counts	Peptides	Count	Lower	Higher values mean higher contamination during sample prep	Number of keratin peptides (full or partial trypsin); unique peptide count (MSGFSpecProb < 1E-12)	0	96
mass_error_ppm	DtaRefinery	MS1 Signal	PSM based	Parent Ion Mass Error (ppm)	ppm mean	ppm	Lower	Measures the accuracy of the identifications (and the instrument calibration)	Either a duplicate of MS1_5C, or the value reported by DTA_Refinery before refinement	0	-8
mass_error_ppm_refined	DtaRefinery	MS1 Signal	After DTA_Refinery	Parent Ion Mass Error (ppm)	ppm mean	ppm	Lower	Measures the accuracy of the identifications, after refinement by DTA Refinery	Computed by DTA_Refinery after refinement	0	97
mass_error_ppm_viper	VIPER	MS1 Signal		Parent Ion Mass Error (ppm)	ppm median	ppm	Lower	Measures the accuracy of the identifications	Median of the precursor mass error (ppm)	0	-7
ms1_1	SMAQC	MS1 Signal	Ion injection time	Ion injection times for IDs	MS1 median	Milliseconds	Lower	Lower times indicate an abundance of ions	Median MS1 ion injection time (MSGFSpecProb < 1E-12)	0	70
ms1_2a	SMAQC	MS1 Signal	S/N	MS1 during middle (and early) peptide retention period	S/N median	None	Higher	Higher MS1 S/N may correlate with higher signal discrimination	Median S/N value for MS1 spectra from run start through middle 50% of separation	0	71
ms1_2b	SMAQC	MS1 Signal	TIC	MS1 during middle (and early) peptide retention period	TIC median	Counts/1000	Higher	Estimates the total absolute signal for peptides (may vary significantly between instruments)	Median TIC value for identified peptides from run start through middle 50% of separation	0	72
ms1_3a	SMAQC	MS1 Signal	Dynamic range estimate	MS1 ID max	95/5 pctile	Ratio	Higher	Estimates the dynamic range of the peptide signals	Dynamic range estimate using 95th percentile peptide peak apex intensity / 5th percentile (MSGFSpecProb < 1E-12)	0	73
ms1_3b	SMAQC	MS1 Signal	Peak apex intensity	MS1 ID max	Median	Count	Higher	Estimates the median MS1 signal for peptides	Median peak apex intensity for all peptides (MSGFSpecProb < 1E-12)	0	74
ms1_4a	SMAQC	MS1 Signal	Ignore	MS1 intensity variation for peptides	Within series	Percent	Lower	Used to monitor relative intensity difference with a series	Ignore: Average of between series intensity variations for identified peptides	1	75
ms1_4b	SMAQC	MS1 Signal	Ignore	MS1 intensity variation for peptides	Betw/in	Ratio	Lower	Used to monitor relative intensity differences with a series compared with between series	Ignore: Ratio of average intensity variation between series to average intensity variation within a series	1	76
ms1_5a	SMAQC	MS1 Signal	Mass error, Th	Precursor m/z – Peptide ion m/z	Median	Th	Lower	Measures the accuracy of the identifications	Median of precursor mass error (Th, MSGFSpecProb < 1E-12)	0	77
ms1_5b	SMAQC	MS1 Signal	Abs[Mass error], Th	Precursor m/z – Peptide ion m/z	Mean absolute	Th	Lower	Measures the accuracy of the identifications	Median of absolute value of precursor mass error (Th, MSGFSpecProb < 1E-12)	0	78
ms1_5c	SMAQC	MS1 Signal	Mass error, ppm	Precursor m/z – Peptide ion m/z	ppm median	ppm	Lower	Measures the accuracy of the identifications	Median of precursor mass error (ppm, MSGFSpecProb < 1E-12)	0	79
ms1_5d	SMAQC	MS1 Signal	Mass error, interquartile	Precursor m/z – Peptide ion m/z	ppm interQ	ppm	Lower	Measures the distribution of the real accuracy measurements	Interquartile distance in ppm-based precursor mass error (MSGFSpecProb < 1E-12)	0	80
ms1_count	Quameter_IDFree	Acquisition Stats		Spectrum counts		Count			Number of MS spectra collected	0	27
ms1_density_q1	Quameter_IDFree	Acquisition Stats		Spectrum counts		Count			25%ile of MS scan peak counts	0	29
ms1_density_q2	Quameter_IDFree	Acquisition Stats		Spectrum counts		Count			50%ile of MS scan peak counts	0	30
ms1_density_q3	Quameter_IDFree	Acquisition Stats		Spectrum counts		Count			75%ile of MS scan peak counts	0	31
ms1_freq_max	Quameter_IDFree	Acquisition Stats		Acquisition Rate		Hz			Fastest frequency for MS collection in any minute	0	28
ms1_tic_change_q2	Quameter_IDFree	MS1 Signal		ESI Stability		Ratio	Lower		The log ratio for 50%ile of TIC changes over 25%ile of TIC changes	0	21
ms1_tic_change_q3	Quameter_IDFree	MS1 Signal		ESI Stability		Ratio	Lower		The log ratio for 75%ile of TIC changes over 50%ile of TIC changes	0	22
ms1_tic_change_q4	Quameter_IDFree	MS1 Signal		ESI Stability		Ratio	Lower		The log ratio for largest TIC change over 75%ile of TIC changes	0	23
ms1_tic_q2	Quameter_IDFree	MS1 Signal		Dynamic Range		Ratio			The log ratio for 50%ile of TIC over 25%ile of TIC	0	24
ms1_tic_q3	Quameter_IDFree	MS1 Signal		Dynamic Range		Ratio			The log ratio for 75%ile of TIC over 50%ile of TIC	0	25
ms1_tic_q4	Quameter_IDFree	MS1 Signal		Dynamic Range		Ratio			The log ratio for largest TIC over 75%ile TIC	0	26
ms2_1	SMAQC	MS2 Signal	Ion injection time	Ion injection times for IDs	MS2 median	Milliseconds	Lower	Reflects sample concentration.  Lower concentrations lead to higher ion injection times.	Median MS2 ion injection time for identified peptides (MSGFSpecProb < 1E-12)	0	81
ms2_2	SMAQC	MS2 Signal	S/N	MS2 ID S/N	Median	Ratio	Higher	Higher S/N correlates with increased frequency of peptide identification	Median S/N value for identified MS2 spectra (MSGFSpecProb < 1E-12)	0	82
ms2_3	SMAQC	MS2 Signal	Ion count	MS2 ID peaks	Median	Count	Higher	Higher peak counts can correlate with more signal	Median number of peaks in all MS2 spectra (MSGFSpecProb < 1E-12)	0	83
ms2_4a	SMAQC	MS2 Signal	% spec identified, low abu	Fraction of MS2 identified at different MS1 max quartiles	ID fract Q1	Fraction	Higher	Higher fractions of identified MS2 spectra indicate efficiency of detection and sampling	Fraction of all MS2 spectra identified; low abundance quartile (determined using MS1 intensity of identified peptides, MSGFSpecProb < 1E-12)	0	84
ms2_4b	SMAQC	MS2 Signal	% spec identified, med abu	Fraction of MS2 identified at different MS1 max quartiles	ID fract Q2	Fraction	Higher	Higher fractions of identified MS2 spectra indicate efficiency of detection and sampling	Fraction of all MS2 spectra identified; second quartile (determined using MS1 intensity of identified peptides, MSGFSpecProb < 1E-12)	0	85
ms2_4c	SMAQC	MS2 Signal	% spec identified, med abu	Fraction of MS2 identified at different MS1 max quartiles	ID fract Q3	Fraction	Higher	Higher fractions of identified MS2 spectra indicate efficiency of detection and sampling	Fraction of all MS2 spectra identified; third quartile (determined using MS1 intensity of identified peptides, MSGFSpecProb < 1E-12)	0	86
ms2_4d	SMAQC	MS2 Signal	% spec identified, high abu	Fraction of MS2 identified at different MS1 max quartiles	ID fract Q4	Fraction	Higher	Higher fractions of identified MS2 spectra indicate efficiency of detection and sampling	Fraction of all MS2 spectra identified; high abundance quartile (determined using MS1 intensity of identified peptides, MSGFSpecProb < 1E-12)	0	87
ms2_count	Quameter_IDFree	Acquisition Stats		Spectrum counts		Count			Number of MS/MS spectra collected	0	32
ms2_density_q1	Quameter_IDFree	Acquisition Stats		Spectrum counts		Count			25%ile of MS/MS scan peak counts	0	34
ms2_density_q2	Quameter_IDFree	Acquisition Stats		Spectrum counts		Count			50%ile of MS/MS scan peak counts	0	35
ms2_density_q3	Quameter_IDFree	Acquisition Stats		Spectrum counts		Count			75%ile of MS/MS scan peak counts	0	36
ms2_freq_max	Quameter_IDFree	Acquisition Stats		Acquisition Rate		Hz			Fastest frequency for MS/MS collection in any minute	0	33
ms2_prec_z_1	Quameter_IDFree	Mass Precision		Charge distribution		Fraction	Lower		Fraction of MS/MS precursors that are singly charged	0	37
ms2_prec_z_2	Quameter_IDFree	Mass Precision		Charge distribution		Fraction	n/a		Fraction of MS/MS precursors that are doubly charged	0	38
ms2_prec_z_3	Quameter_IDFree	Mass Precision		Charge distribution		Fraction	n/a		Fraction of MS/MS precursors that are triply charged	0	39
ms2_prec_z_4	Quameter_IDFree	Mass Precision		Charge distribution		Fraction	n/a		Fraction of MS/MS precursors that are quadruply charged	0	40
ms2_prec_z_5	Quameter_IDFree	Mass Precision		Charge distribution		Fraction	n/a		Fraction of MS/MS precursors that are quintuply charged	0	41
ms2_prec_z_likely_1	Quameter_IDFree	Mass Precision		Charge distribution		Fraction	Lower		Fraction of MS/MS precursors lack known charge but look like 1+	0	43
ms2_prec_z_likely_multi	Quameter_IDFree	Mass Precision		Charge distribution		Fraction	n/a		Fraction of MS/MS precursors lack known charge but look like 2+ or higher	0	44
ms2_prec_z_more	Quameter_IDFree	Mass Precision		Charge distribution		Fraction	n/a		Fraction of MS/MS precursors that are charged higher than +5	0	42
ms2_rep_ion_1missing	SMAQC	MS2 Signal	PSMs, all but 1 reporter ion	Reporter ion stats	Identifications	Count	Higher	Evaluate isobaric labelling peaks	Number of peptides (PSMs) where all but 1 of the reporter ions were seen (MSGFSpecProb < 1E-12)	0	102
ms2_rep_ion_2missing	SMAQC	MS2 Signal	PSMs, all but 2 reporter ions	Reporter ion stats	Identifications	Count	Higher	Evaluate isobaric labelling peaks	Number of peptides (PSMs) where all but 2 of the reporter ions were seen (MSGFSpecProb < 1E-12)	0	103
ms2_rep_ion_3missing	SMAQC	MS2 Signal	PSMs, all but 3 reporter ions	Reporter ion stats	Identifications	Count	Higher	Evaluate isobaric labelling peaks	Number of peptides (PSMs) where all but 3 of the reporter ions were seen (MSGFSpecProb < 1E-12)	0	104
ms2_rep_ion_all	SMAQC	MS2 Signal	PSMs, all reporter ions	Reporter ion stats	Identifications	Count	Higher	Evaluate isobaric labelling peaks	Number of peptides (PSMs) where all reporter ions were seen (MSGFSpecProb < 1E-12)	0	101
p_1a	SMAQC	Peptide Identification	PSM Score	MS2 ID score	Median	fval	Higher	Higher scores correlate with higher S/N and frequency of identification	Median peptide ID score (-Log10(MSGF_SpecProb) or X!Tandem hyperscore)	0	88
p_1b	SMAQC	Peptide Identification	PSM Score	MS2 ID Score	Median	None	Lower	Lower scores correlate with higher S/N and frequency of identification	Median peptide ID score ( Log10(MSGF_SpecProb) or X!Tandem Peptide_Expectation_Value_Log(e))	0	89
p_2a	SMAQC	Peptide Identification	Total PSMs	Peptide counts	Identifications	Count	Higher	Total identifications correlate with high levels of peptide signals, performance	Number of fully tryptic peptides; total spectra count (MSGFSpecProb < 1E-12)	0	90
p_2b	SMAQC	Peptide Identification	Unique peptide and charge	Peptide counts	Ions	Count	Higher	A good overall performance measure	Number of tryptic peptides; unique peptide & charge count (MSGFSpecProb < 1E-12)	0	91
p_2c	SMAQC	Peptide Identification	Unique peptides	Peptide counts	Peptides	Count	Higher	A good overall performance measure	Number of tryptic peptides; unique peptide count (MSGFSpecProb < 1E-12)	0	-11
p_3	SMAQC	Peptide Identification	Semi/fully-tryptic	Peptide counts	Semi/tryptic peptides	Ratio	N/A	Indicates prevalence of semitryptic peptides in sample; increasing ratios may indicate changes in sample or in source	Ratio of unique semi-tryptic / unique fully tryptic peptides (MSGFSpecProb < 1E-12)	0	93
p_4a	SMAQC	Peptide Identification	Fraction fully-Tryptic	Peptide counts	Fully-tryptic/UniquePeptides	Ratio	Higher	Measure of tryptic digestion efficiency	Ratio of unique fully tryptic peptides / total unique peptides (MSGFSpecProb < 1E-12)	0	97
p_4b	SMAQC	Peptide Identification	Missed cleavage rate	Peptide Counts	MissedCleavages/UniquePeptides	Ratio	Lower	Measure of tryptic digestion efficiency	Ratio of total missed cleavages (among unique peptides) / total unique peptides (MSGFSpecProb < 1E-12)	0	98
phos_2a	SMAQC	Peptide Identification	Total phosphopeptides PSMs	Peptide counts	Identifications	Count	Higher	Total identifications correlate with high levels of peptide signals, performance	Number of tryptic phosphopeptides; total spectra count (MSGFSpecProb < 1E-12)	0	94
phos_2c	SMAQC	Peptide Identification	Unique phosphopeptides	Peptide counts	Peptides	Count	Higher	A good overall performance measure for phospho samples	Number of tryptic phosphopeptides; unique peptide count (MSGFSpecProb < 1E-12)	0	-3
qcart	Aggregate	Quality Control	QC-ART aggregate score	Overall Quality Control metric	Likelihood good dataset	None	Lower		Overall confidence using model developed by Allison Thompson and Ryan Butner	0	-4
qcdm	Aggregate	Quality Control	Aggregate score	Overall Quality Control metric	Likelihood good dataset	Fraction	Lower		Overall confidence using model developed by Brett Amidan	0	105
rt_duration	Quameter_IDFree	Chromatography		Interquartile retention time period		seconds			Highest scan time observed minus the lowest scan time observed	0	8
rt_ms_q1	Quameter_IDFree	Chromatography		MS events vs. time		Fraction			The interval for the first 25% of all MS events divided by RT-Duration	0	13
rt_ms_q2	Quameter_IDFree	Chromatography		MS events vs. time		Fraction			The interval for the second 25% of all MS events divided by RT-Duration	0	14
rt_ms_q3	Quameter_IDFree	Chromatography		MS events vs. time		Fraction			The interval for the third 25% of all MS events divided by RT-Duration	0	15
rt_ms_q4	Quameter_IDFree	Chromatography		MS events vs. time		Fraction			The interval for the fourth 25% of all MS events divided by RT-Duration	0	16
rt_msms_q1	Quameter_IDFree	Chromatography		MS/MS events vs. time		Fraction			The interval for the first 25% of all MS/MS events divided by RT-Duration	0	17
rt_msms_q2	Quameter_IDFree	Chromatography		MS/MS events vs. time		Fraction			The interval for the second 25% of all MS/MS events divided by RT-Duration	0	18
rt_msms_q3	Quameter_IDFree	Chromatography		MS/MS events vs. time		Fraction			The interval for the third 25% of all MS/MS events divided by RT-Duration	0	19
rt_msms_q4	Quameter_IDFree	Chromatography		MS/MS events vs. time		Fraction			The interval for the fourth 25% of all MS/MS events divided by RT-Duration	0	20
rt_tic_q1	Quameter_IDFree	Chromatography		Intensity distribution vs. time		Fraction			The interval when the first 25% of TIC accumulates divided by RT-Duration	0	9
rt_tic_q2	Quameter_IDFree	Chromatography		Intensity distribution vs. time		Fraction			The interval when the second 25% of TIC accumulates divided by RT-Duration	0	10
rt_tic_q3	Quameter_IDFree	Chromatography		Intensity distribution vs. time		Fraction			The interval when the third 25% of TIC accumulates divided by RT-Duration	0	11
rt_tic_q4	Quameter_IDFree	Chromatography		Intensity distribution vs. time		Fraction			The interval when the fourth 25% of TIC accumulates divided by RT-Duration	0	12
trypsin_2a	SMAQC	Peptide Identification	Total PSMs from trypsin	Peptide counts	Identifications	Count	Lower	Higher values mean incomplete digestion	Number of peptides from trypsin; total spectra count (MSGFSpecProb < 1E-12)	0	99
trypsin_2c	SMAQC	Peptide Identification	Unique peptides from trypsin	Peptide counts	Peptides	Count	Lower	Higher values mean incomplete digestion	Number of peptides from trypsin; unique peptide count (MSGFSpecProb < 1E-12)	0	100
xic_fwhm_q1	Quameter_IDFree	Chromatography		Peak width variability		seconds			25%ile of peak widths for the wide XICs	0	2
xic_fwhm_q2	Quameter_IDFree	Chromatography		Peak width variability		seconds			50%ile of peak widths for the wide XICs	0	3
xic_fwhm_q3	Quameter_IDFree	Chromatography		Peak width variability		seconds			75%ile of peak widths for the wide XICs	0	-6
xic_height_q2	Quameter_IDFree	Chromatography		Peak height variability					The log ratio for 50%ile of wide XIC heights over 25%ile of heights.	0	5
xic_height_q3	Quameter_IDFree	Chromatography		Peak height variability					The log ratio for 75%ile of wide XIC heights over 50%ile of heights.	0	6
xic_height_q4	Quameter_IDFree	Chromatography		Peak height variability					The log ratio for maximum of wide XIC heights over 75%ile of heights.	0	7
xic_wide_frac	Quameter_IDFree	Chromatography		Peak width variability		Ratio			Fraction of precursor ions accounting for the top half of all peak width	0	-5
\.


--
-- PostgreSQL database dump complete
--

