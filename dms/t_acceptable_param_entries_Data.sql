--
-- PostgreSQL database dump
--

-- Dumped from database version 16.2
-- Dumped by pg_dump version 16.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: t_acceptable_param_entries; Type: TABLE DATA; Schema: public; Owner: d3l243
--

COPY public.t_acceptable_param_entries (entry_id, parameter_name, description, parameter_category, default_value, display_name, canonical_name, analysis_tool_id, first_applicable_version, last_applicable_version, param_entry_type_id, picker_items_list, output_order) FROM stdin;
1	SelectedEnzymeIndex	\N	SearchSettings	0	Selected Enzyme Index	enzyme_number	1	2.0	3.1	1	\N	120
2	SelectedEnzymeCleavagePosition	\N	SearchSettings	1	Enzyme Cleavage Position	cleavage_position	1	2.0	\N	1	\N	980
3	MaximumNumberMissedCleavages	\N	SearchSettings	4	Maximum Number of Missed Cleavage Sites	max_num_internal_cleavage_sites	1	2.0	\N	1	\N	220
4	ParentMassType	\N	SearchSettings	1	Parent Mass Type	mass_type_parent	1	2.0	\N	4	[{"value": 0,"display":"Average Masses"},{"value":1,"display":"Monoisotopic Masses"}]	170
5	FragmentMassType	\N	SearchSettings	1	Fragment Mass Type	mass_type_fragment	1	2.0	\N	4	[{"value": 0,"display":"Average Masses"},{"value":1,"display":"Monoisotopic Masses"}]	180
6	PartialSequenceToMatch	\N	SearchSettings	\N	Partial Sequence to Match	partial_sequence	1	2.0	\N	3	\N	270
7	CreateOutputFiles	\N	SearchOptions	True	Create Output Files	create_output_files	1	2.0	\N	8	\N	265
8	NumberOfResultsToProcess	\N	MiscellaneousOptions	500	Number of Results to Process	num_results	1	3.0	\N	1	\N	80
10	MaximumNumAAPerDynMod	\N	MiscellaneousOptions	4	Maximum Number of Residues Per Dynamic Mod	max_num_differential_AA_per_mod	1	2.0	\N	1	\N	135
12	PeptideMassTolerance	\N	SearchTolerances	3.0000	Parent Mass Tolerance	peptide_mass_tolerance	1	2.0	\N	7	\N	30
13	FragmentIonTolerance	\N	SearchTolerances	0.0000	Fragment Mass Tolerance	fragment_ion_tolerance	1	2.0	\N	7	\N	55
14	NumberOfOutputLines	\N	MiscellaneousOptions	10	Number of Output Lines	num_output_lines	1	2.0	\N	1	\N	70
15	NumberOfDescriptionLines	\N	MiscellaneousOptions	3	Number of Description Lines to Show	num_description_lines	1	2.0	\N	1	\N	90
16	ShowFragmentIons	\N	SearchOptions	False	Show Fragment Ions	show_fragment_ions	1	2.0	\N	8	\N	100
17	PrintDuplicateReferences	\N	SearchOptions	True	Print Duplicate References	print_duplicate_references	1	2.0	\N	8	\N	110
18	SelectedNucReadingFrameIndex	\N	MiscellaneousOptions	0	Selected Nucleotide Reading Frame	nucleotide_reading_frame	1	2.0	\N	4	[{"value":0,"display":"None (Protein Database)"},{"value":1,"display":"Frame 1 - Forward"},{"value":2,"display":"Frame 2 - Forward"},{"value":3,"display":"Frame 3 - Forward"},{"value":4,"display":"Frame 1 - Reverse"},{"value":5,"display":"Frame 2 - Reverse"},{"value":6,"display":"Frame 3 - Reverse"},{"value":7,"display":"Three Forward Frames"},{"value":8,"display":"Three Reverse Frames"},{"value":9,"display":"All Six Frames"}]	160
19	RemovePrecursorPeak	\N	SearchOptions	False	Remove Precursor Peak	remove_precursor_peak	1	2.0	\N	8	\N	200
20	IonCutoffPercentage	\N	SearchTolerances	0.000	Preliminary Score Cutoff Percentage (as decimal)	ion_cutoff_percentage	1	2.0	\N	7	\N	210
21	MinimumProteinMassToSearch	\N	SearchTolerances	0	Minimum Protein Mass to Search	protein_mass_filter	1	2.0	\N	2	\N	230
22	MaximumProteinMassToSearch	\N	SearchTolerances	0	Maximum Protein Mass to Search	protein_mass_filter	1	2.0	\N	2	\N	235
23	NumberOfDetectedPeaksToMatch	\N	MiscellaneousOptions	0	Number of Detected Peaks to Match	match_peak_count	1	2.0	\N	1	\N	240
25	NumberOfAllowedDetectedPeakErrors	\N	MiscellaneousOptions	1	Number of Allowed Errors in Matching Auto-detected Peaks	match_peak_allowed_error	1	2.0	\N	1	\N	250
26	MatchedPeakMassTolerance	\N	SearchTolerances	1.0000	Mass Tolerance for Matching Auto-detected Peaks	match_peak_tolerance	1	2.0	\N	7	\N	260
27	AminoAcidsAllUpperCase	\N	SearchOptions	True	FASTA File has Residues in Upper Case	residues_in_upper_case	1	2.0	3.1	8	\N	265
28	SequenceHeaderInfoToFilter	\N	MiscellaneousOptions	\N	Sequence Header Information to Filter	sequence_header_filter	1	2.0	\N	3	\N	280
31	NormalizeXCorr	\N	SearchOptions	False	Normalize XCorr	normalize_xcorr	1	3.2	\N	8	\N	190
32	PeptideMassUnits	\N	SearchTolerances	0	Peptide Mass Units	peptide_mass_units	1	3.2	\N	4	[{"value": 0,"display":"amu"},{"value": 1,"display":"mmu"},{"value": 2,"display":"ppm"}]	40
34	IonSeries	\N	IonSeries	0 1 1 0.0 1.0 0.0 0.0 0.0 0.0 0.0 1.0 0.0	Ion Series	ion_series	1	2.0	\N	5	\N	50
37	DatabaseName	\N	RunTime	\N	Database Name	database_name	1	2.0	2.0	3	\N	10
38	DatabaseName	\N	RunTime	\N	First Database Name	first_database_name	1	3.0	\N	3	\N	10
39	DatabaseName2	\N	RunTime	\N	Second Database Name	second_database_name	1	3.0	\N	3	\N	15
40	DynamicMods	\N	DynamicMods	\N	Dynamic Modifications	diff_search_options	1	2.0	\N	6	\N	140
41	TerminalDynamicMods	\N	DynamicMods	\N	Terminal Dynamic Modifications	term_diff_search_options	1	3.2	\N	9	\N	150
42	EnzymeInfo	\N	SearchSettings	No_Enzyme(-) 1 0 - -	Enzyme Info	enzyme_info	1	3.2	\N	3	\N	120
43	SelectedEnzymeIndex	\N	SearchSettings	0	Selected Enzyme ID	enzyme_id	1	3.2	\N	1	\N	990
44	MaximumNumDifferentialPerPeptide	\N	MiscellaneousOptions	3	Maximum Number of Differential Mods Per Peptide	max_num_differential_per_peptide	1	3.2	\N	1	\N	130
45	StaticModifications	\N	StaticMods	\N	Static Modifications	static_mods	1	2.0	\N	6	\N	350
46	FragmentMassUnits	\N	SearchTolerances	0	Fragment Ion Mass Units	fragment_ion_units	1	3.2	\N	4	[{"value": 0,"display":"amu"},{"value": 1,"display":"mmu"},{"value": 2,"display":"ppm"}]	45
47	UsePhosphoFragmentation	\N	SearchSettings	false	Use Phospho Fragmentation Rules	use_phospho_fragmentation	1	3.2	\N	8	\N	155
49	TerminalStaticMods	\N	StaticMods	\N	Terminal Static Modifications	term_static_mods	1	3.2	\N	6	\N	290
\.


--
-- Name: t_acceptable_param_entries_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: d3l243
--

SELECT pg_catalog.setval('public.t_acceptable_param_entries_entry_id_seq', 49, true);


--
-- PostgreSQL database dump complete
--

