--
-- PostgreSQL database dump
--

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

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
-- Data for Name: t_dataset_nom_stat_names; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_dataset_nom_stat_names (metric, source, category, short_description, metric_value, units, optimal, purpose, description, ignored, sort_key) FROM stdin;
mz_ion_count	MSFileInfoScanner	Basic Stats	Peak count		Count	Higher	Gauge data richness	Number of m/z ions (aka peaks) in the mass spectrum	0	10
mz_median	MSFileInfoScanner	Basic Stats	Median m/z	Median	Th			Median m/z	0	11
mz_skew	MSFileInfoScanner	Basic Stats	m/z skewness					Skewness of the m/z values	0	12
mz_kurtosis	MSFileInfoScanner	Basic Stats	m/z kurtosis					Kurtosis of the m/z values	0	13
organic_count	MSFileInfoScanner	Organic/Inorganic Metrics	Organic count		Count			Number of m/z values where the decimal value of the m/z is between 0.0 and 0.4	0	14
organic_intensity_sum	MSFileInfoScanner	Organic/Inorganic Metrics	Organic intensity	Sum	Count			Sum of the intensities of m/z values where the decimal value of the m/z is between 0.0 and 0.4	0	15
inorganic_count	MSFileInfoScanner	Organic/Inorganic Metrics	Inorganic count		Count			Number of m/z values where the decimal value of the m/z is between 0.6 and 0.999	0	16
inorganic_intensity_sum	MSFileInfoScanner	Organic/Inorganic Metrics	Inorganic intensity	Sum	Count			Sum of the intensities of m/z values where the decimal value of the m/z is between 0.6 and 0.999	0	17
organic_to_inorganic_count_ratio	MSFileInfoScanner	Organic/Inorganic Metrics	Organic/Inorganic count ratio		Ratio			Organic to inorganic ratio (OrganicCount / InorganicCount)	0	18
organic_to_inorganic_intensity_ratio	MSFileInfoScanner	Organic/Inorganic Metrics	Organic/Inorganic intensity ratio		Ratio			Organic to inorganic ratio, intensity weighted (OrganicIntensitySum / InorganicIntensitySum)	0	19
c13_pair_count	MSFileInfoScanner	Isotopologue Metrics	Carbon-13 pair count		Count			Count of pairs of peaks separated by 1.003355 (plus/minus tolerance of 0.0005)	0	20
c13_pair_intensity_sum	MSFileInfoScanner	Isotopologue Metrics	Carbon-13 pair intensity	Sum	Count			Sum of the intensities of pairs of peaks separated by 1.003355 (plus/minus tolerance of 0.0005)	0	21
cl37_pair_count	MSFileInfoScanner	Isotopologue Metrics	Chlorine-37 pair count		Count			Count of pairs of peaks separated by 1.99705 (plus/minus tolerance of 0.0005)	0	22
cl37_pair_intensity_sum	MSFileInfoScanner	Isotopologue Metrics	Chlorine-37 pair intensity	Sum	Count			Sum of the intensities of pairs of peaks separated by 1.99705 (plus/minus tolerance of 0.0005)	0	23
c13_to_cl37_pair_ratio	MSFileInfoScanner	Isotopologue Metrics	Carbon-13 / Chlorine-37 pair ratio		Ratio			Carbon-13 to Chlorine-37 Pair Ratio (C13PairCount / Cl37PairCount)	0	24
c13_to_cl37_pair_intensity_ratio	MSFileInfoScanner	Isotopologue Metrics	Carbon-13 / Chlorine-37 intensity ratio		Ratio			C13 to Chlorine-37 Pair Intensity Ratio (C13PairIntensitySum / Cl37PairIntensitySum)	0	25
chloride_cluster_count	MSFileInfoScanner	Chloride Cluster Metrics	Chloride cluster count		Count			Number of times that more than two peaks in series are sequentially separated by 1.99705 (plus/minus tolerance of 0.0005)	0	26
chloride_cluster_max_length	MSFileInfoScanner	Chloride Cluster Metrics	Max chloride cluster length	Max				Maximum length of chloride clusters	0	27
chloride_cluster_mean_length	MSFileInfoScanner	Chloride Cluster Metrics	Mean chloride cluster length	Mean				Mean length of chloride clusters	0	28
chloride_cluster_peak_count	MSFileInfoScanner	Chloride Cluster Metrics	Chloride cluster peaks		Count			Total number of peaks that are part of chloride clusters	0	29
chloride_cluster_peak_percent	MSFileInfoScanner	Chloride Cluster Metrics	Chloride cluster peaks %		Percent			Percent of peaks that are members of a chloride cluster	0	30
chloride_cluster_intensity_sum	MSFileInfoScanner	Chloride Cluster Metrics	Chloride cluster intensity	Sum	Count			Total intensity of peaks that are members of a chloride cluster	0	31
chloride_cluster_intensity_percent	MSFileInfoScanner	Chloride Cluster Metrics	Chloride cluster intensity %		Percent			Percent of the total intensity of the peaks in the mass spectrum that is associated with chloride clusters	0	32
calibration_points	Annotation Job	Annotation: Calibration	Calibration point count		Count			Calibration point count	0	33
calibration_raw_error_median	Annotation Job	Annotation: Calibration	Calibration raw error median ppm	Median				Calibration raw error median (ppm)	0	34
calibration_raw_error_stdev	Annotation Job	Annotation: Calibration	Calibration raw error std ppm	Stdev				Calibration raw error std (ppm)	0	35
total_features	Annotation Job	Annotation: coverage	Annotation peak count		Count			Number of peaks examined during annotation	0	37
annotated_features	Annotation Job	Annotation: coverage	Annotation feature count		Count			Number of peaks assigned during annotation	0	38
percent_features_annotated	Annotation Job	Annotation: coverage	Annotation feature assigned percent		Percent			Percentage of peaks assigned during annotation	0	39
total_intensity	Annotation Job	Annotation: coverage	Annotation intensity total sum	Sum	Count			Sum of all intensities	0	40
annotated_intensity	Annotation Job	Annotation: coverage	Annotation intensity assigned sum	Sum	Count			Sum of assigned intensities	0	41
percent_intensity_annotated	Annotation Job	Annotation: coverage	Annotation intensity assigned percent		Percent			Percentage of intensity assigned	0	42
assigned_mz_error_rms_ppm	Annotation Job	Annotation: assignment error	Annotation m/z error abs rms ppm					RMS of absolute PPM errors for assignments	0	43
signed_mean_ppm_error	Annotation Job	Annotation: assignment error	Annotation m/z error signed mean ppm	Mean				Mean absolute PPM error for assignments	0	44
mean_ppm_error	Annotation Job	Annotation: assignment error	Annotation m/z error abs mean ppm	Mean				Median absolute PPM error	0	45
median_ppm_error	Annotation Job	Annotation: assignment error	Annotation m/z error abs median ppm	Median				Signed mean PPM error (bias indicator)	0	46
descriptor_feature_count	Annotation Job	Annotation: formula descriptors	Annotation non isotopologue feature count		Count			Non-isotopologue features used during annotation	0	51
calibration_rms	Annotation Job	Annotation: Calibration	Calibration fit RMS ppm					Calibration RMS (ppm)	0	36
descriptor_intensity_fraction_percent	Annotation Job	Annotation: formula descriptors	Annotation non isotopologue intensity fraction percent		Percent			Assigned intensity used (non-isotopologue) % during annotation	0	52
weighted_hc	Annotation Job	Annotation: formula descriptors	Annotation weighted HC ratio		Ratio			Intensity-weighted H/C for non-isotopologue annotations	0	48
weighted_nosc	Annotation Job	Annotation: formula descriptors	Annotation weighted NOSC					Intensity-weighted NOSC for non-isotopologue annotations	0	49
weighted_oc	Annotation Job	Annotation: formula descriptors	Annotation weighted OC ratio		Ratio			Intensity-weighted O/C for non-isotopologue annotations	0	47
weighted_aimod	Annotation Job	Annotation: formula descriptors	Annotation weighted AI mod					Intensity-weighted AI_mod for non-isotopologue annotations	0	50
\.


--
-- PostgreSQL database dump complete
--

