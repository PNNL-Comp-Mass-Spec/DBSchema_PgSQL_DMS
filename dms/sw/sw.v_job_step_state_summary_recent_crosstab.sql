--
-- Name: v_job_step_state_summary_recent_crosstab; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_job_step_state_summary_recent_crosstab AS
 SELECT state,
    state_name,
    COALESCE("Ape", 0) AS ape,
    COALESCE("AScore", 0) AS ascore,
    COALESCE("Cyclops", 0) AS cyclops,
    COALESCE("DataExtractor", 0) AS data_extractor,
    COALESCE("DataExtractorSplitFasta", 0) AS data_extractor_split_fasta,
    COALESCE("Decon2LS_V2", 0) AS decon2ls_v2,
    COALESCE("DTA_Gen", 0) AS dta_gen,
    COALESCE("DTA_Refinery", 0) AS dta_refinery,
    COALESCE("Formularity", 0) AS formularity,
    COALESCE("IDM", 0) AS idm,
    COALESCE("IDPicker", 0) AS idpicker,
    COALESCE("LCMSFeatureFinder", 0) AS lcms_feature_finder,
    COALESCE("Mage", 0) AS mage,
    COALESCE("MASIC_Finnigan", 0) AS masic_finnigan,
    COALESCE("MaxqPeak", 0) AS maxq_peak,
    COALESCE("MaxqS1", 0) AS maxq_s1,
    COALESCE("MaxqS2", 0) AS maxq_s2,
    COALESCE("MaxqS3", 0) AS maxq_s3,
    COALESCE("MODa", 0) AS moda,
    COALESCE("MODPlus", 0) AS modplus,
    COALESCE("MSAlign", 0) AS msalign,
    COALESCE("MSAlign_Quant", 0) AS msalign_quant,
    COALESCE("MSDeconv", 0) AS msdeconv,
    COALESCE("MSFragger", 0) AS msfragger,
    COALESCE("MSGF", 0) AS msgf,
    COALESCE("MSGFPlus", 0) AS msgfplus,
    COALESCE("MSMSSpectraPreprocessor", 0) AS msms_spectra_preprocessor,
    COALESCE("MSPathFinder", 0) AS mspathfinder,
    COALESCE("MSXML_Bruker", 0) AS msxml_bruker,
    COALESCE("MSXML_Gen", 0) AS msxml_gen,
    COALESCE("Mz_Refinery", 0) AS mz_refinery,
    COALESCE("PBF_Gen", 0) AS pbf_gen,
    COALESCE("PepProtProphet", 0) AS pep_prot_prophet,
    COALESCE("Phospho_FDR_Aggregator", 0) AS phospho_fdr_aggregator,
    COALESCE("PRIDE_Converter", 0) AS pride_converter,
    COALESCE("ProMex", 0) AS promex,
    COALESCE("Results_Cleanup", 0) AS results_cleanup,
    COALESCE("Results_Transfer", 0) AS results_transfer,
    COALESCE("Sequest", 0) AS sequest,
    COALESCE("SMAQC", 0) AS smaqc,
    COALESCE("ThermoPeakDataExporter", 0) AS thermo_peak_data_exporter,
    COALESCE("TopFD", 0) AS topfd,
    COALESCE("TopPIC", 0) AS toppic,
    COALESCE("XTandem", 0) AS xtandem
   FROM public.crosstab('SELECT State,
           State_Name,
           Step_Tool,
           Sum(Step_Count) AS Steps
    FROM V_Job_Step_State_Summary_Recent
    GROUP BY State, State_Name, Step_Tool
    ORDER BY State, State_Name, Step_Tool'::text, 'SELECT unnest(''{Ape, AScore, Cyclops, DataExtractor, DataExtractorSplitFasta, Decon2LS_V2, DTA_Gen, DTA_Refinery,
                     Formularity, IDM, IDPicker, LCMSFeatureFinder, Mage, MASIC_Finnigan, MaxqPeak, MaxqS1, MaxqS2, MaxqS3,
                     MODa, MODPlus, MSAlign, MSAlign_Quant, MSDeconv, MSFragger, MSGF, MSGFPlus, MSMSSpectraPreprocessor,
                     MSPathFinder, MSXML_Bruker, MSXML_Gen, Mz_Refinery, PBF_Gen, PepProtProphet, Phospho_FDR_Aggregator,
                     PRIDE_Converter, ProMex, Results_Cleanup, Results_Transfer, Sequest, SMAQC,
                     ThermoPeakDataExporter, TopFD, TopPIC, XTandem}''::citext[])'::text) ct(state integer, state_name public.citext, "Ape" integer, "AScore" integer, "Cyclops" integer, "DataExtractor" integer, "DataExtractorSplitFasta" integer, "Decon2LS_V2" integer, "DTA_Gen" integer, "DTA_Refinery" integer, "Formularity" integer, "IDM" integer, "IDPicker" integer, "LCMSFeatureFinder" integer, "Mage" integer, "MASIC_Finnigan" integer, "MaxqPeak" integer, "MaxqS1" integer, "MaxqS2" integer, "MaxqS3" integer, "MODa" integer, "MODPlus" integer, "MSAlign" integer, "MSAlign_Quant" integer, "MSDeconv" integer, "MSFragger" integer, "MSGF" integer, "MSGFPlus" integer, "MSMSSpectraPreprocessor" integer, "MSPathFinder" integer, "MSXML_Bruker" integer, "MSXML_Gen" integer, "Mz_Refinery" integer, "PBF_Gen" integer, "PepProtProphet" integer, "Phospho_FDR_Aggregator" integer, "PRIDE_Converter" integer, "ProMex" integer, "Results_Cleanup" integer, "Results_Transfer" integer, "Sequest" integer, "SMAQC" integer, "ThermoPeakDataExporter" integer, "TopFD" integer, "TopPIC" integer, "XTandem" integer);


ALTER VIEW sw.v_job_step_state_summary_recent_crosstab OWNER TO d3l243;

--
-- Name: TABLE v_job_step_state_summary_recent_crosstab; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_job_step_state_summary_recent_crosstab TO readaccess;
GRANT SELECT ON TABLE sw.v_job_step_state_summary_recent_crosstab TO writeaccess;

