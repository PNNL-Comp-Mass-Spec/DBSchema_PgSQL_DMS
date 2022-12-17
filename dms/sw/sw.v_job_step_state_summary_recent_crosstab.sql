--
-- Name: v_job_step_state_summary_recent_crosstab; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_job_step_state_summary_recent_crosstab AS
 SELECT ct.state,
    ct.state_name,
    COALESCE(ct."Ape", 0) AS ape,
    COALESCE(ct."AScore", 0) AS ascore,
    COALESCE(ct."Cyclops", 0) AS cyclops,
    COALESCE(ct."DataExtractor", 0) AS data_extractor,
    COALESCE(ct."DataExtractorSplitFasta", 0) AS data_extractor_split_fasta,
    COALESCE(ct."Decon2LS_V2", 0) AS decon2ls_v2,
    COALESCE(ct."DTA_Gen", 0) AS dta_gen,
    COALESCE(ct."DTA_Refinery", 0) AS dta_refinery,
    COALESCE(ct."Formularity", 0) AS formularity,
    COALESCE(ct."IDM", 0) AS idm,
    COALESCE(ct."IDPicker", 0) AS idpicker,
    COALESCE(ct."LCMSFeatureFinder", 0) AS lcms_feature_finder,
    COALESCE(ct."Mage", 0) AS mage,
    COALESCE(ct."MASIC_Finnigan", 0) AS masic_finnigan,
    COALESCE(ct."MaxqPeak", 0) AS maxq_peak,
    COALESCE(ct."MaxqS1", 0) AS maxq_s1,
    COALESCE(ct."MaxqS2", 0) AS maxq_s2,
    COALESCE(ct."MaxqS3", 0) AS maxq_s3,
    COALESCE(ct."MODa", 0) AS moda,
    COALESCE(ct."MODPlus", 0) AS modplus,
    COALESCE(ct."MSAlign", 0) AS msalign,
    COALESCE(ct."MSAlign_Quant", 0) AS msalign_quant,
    COALESCE(ct."MSDeconv", 0) AS msdeconv,
    COALESCE(ct."MSFragger", 0) AS msfragger,
    COALESCE(ct."MSGF", 0) AS msgf,
    COALESCE(ct."MSGFPlus", 0) AS msgfplus,
    COALESCE(ct."MSMSSpectraPreprocessor", 0) AS msms_spectra_preprocessor,
    COALESCE(ct."MSPathFinder", 0) AS mspathfinder,
    COALESCE(ct."MSXML_Bruker", 0) AS msxml_bruker,
    COALESCE(ct."MSXML_Gen", 0) AS msxml_gen,
    COALESCE(ct."Mz_Refinery", 0) AS mz_refinery,
    COALESCE(ct."PBF_Gen", 0) AS pbf_gen,
    COALESCE(ct."PepProtProphet", 0) AS pep_prot_prophet,
    COALESCE(ct."Phospho_FDR_Aggregator", 0) AS phospho_fdr_aggregator,
    COALESCE(ct."PRIDE_Converter", 0) AS pride_converter,
    COALESCE(ct."ProMex", 0) AS promex,
    COALESCE(ct."Results_Cleanup", 0) AS results_cleanup,
    COALESCE(ct."Results_Transfer", 0) AS results_transfer,
    COALESCE(ct."Sequest", 0) AS sequest,
    COALESCE(ct."SMAQC", 0) AS smaqc,
    COALESCE(ct."ThermoPeakDataExporter", 0) AS thermo_peak_data_exporter,
    COALESCE(ct."TopFD", 0) AS topfd,
    COALESCE(ct."TopPIC", 0) AS toppic,
    COALESCE(ct."XTandem", 0) AS xtandem
   FROM public.crosstab('SELECT State,
           State_Name,
           Step_Tool,
           Sum(Step_Count) As Steps
    FROM V_Job_Step_State_Summary_Recent
    GROUP BY State, State_Name, Step_Tool
    ORDER BY State, State_Name, Step_Tool'::text, 'SELECT unnest(''{Ape, AScore, Cyclops, DataExtractor, DataExtractorSplitFasta, Decon2LS_V2, DTA_Gen, DTA_Refinery,
                     Formularity, IDM, IDPicker, LCMSFeatureFinder, Mage, MASIC_Finnigan, MaxqPeak, MaxqS1, MaxqS2, MaxqS3,
                     MODa, MODPlus, MSAlign, MSAlign_Quant, MSDeconv, MSFragger, MSGF, MSGFPlus, MSMSSpectraPreprocessor,
                     MSPathFinder, MSXML_Bruker, MSXML_Gen, Mz_Refinery, PBF_Gen, PepProtProphet, Phospho_FDR_Aggregator,
                     PRIDE_Converter, ProMex, Results_Cleanup, Results_Transfer, Sequest, SMAQC,
                     ThermoPeakDataExporter, TopFD, TopPIC, XTandem}''::citext[])'::text) ct(state integer, state_name public.citext, "Ape" integer, "AScore" integer, "Cyclops" integer, "DataExtractor" integer, "DataExtractorSplitFasta" integer, "Decon2LS_V2" integer, "DTA_Gen" integer, "DTA_Refinery" integer, "Formularity" integer, "IDM" integer, "IDPicker" integer, "LCMSFeatureFinder" integer, "Mage" integer, "MASIC_Finnigan" integer, "MaxqPeak" integer, "MaxqS1" integer, "MaxqS2" integer, "MaxqS3" integer, "MODa" integer, "MODPlus" integer, "MSAlign" integer, "MSAlign_Quant" integer, "MSDeconv" integer, "MSFragger" integer, "MSGF" integer, "MSGFPlus" integer, "MSMSSpectraPreprocessor" integer, "MSPathFinder" integer, "MSXML_Bruker" integer, "MSXML_Gen" integer, "Mz_Refinery" integer, "PBF_Gen" integer, "PepProtProphet" integer, "Phospho_FDR_Aggregator" integer, "PRIDE_Converter" integer, "ProMex" integer, "Results_Cleanup" integer, "Results_Transfer" integer, "Sequest" integer, "SMAQC" integer, "ThermoPeakDataExporter" integer, "TopFD" integer, "TopPIC" integer, "XTandem" integer);


ALTER TABLE sw.v_job_step_state_summary_recent_crosstab OWNER TO d3l243;

--
-- Name: TABLE v_job_step_state_summary_recent_crosstab; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_job_step_state_summary_recent_crosstab TO readaccess;
GRANT SELECT ON TABLE sw.v_job_step_state_summary_recent_crosstab TO writeaccess;

