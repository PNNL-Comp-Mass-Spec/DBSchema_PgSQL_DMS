--
-- Name: v_job_step_state_summary_recent_crosstab; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_job_step_state_summary_recent_crosstab AS
 SELECT ct.state,
    ct.state_name,
    ct."Ape",
    ct."AScore",
    ct."Cyclops",
    ct."DataExtractor",
    ct."DataExtractorSplitFasta",
    ct."Decon2LS_V2",
    ct."DTA_Gen",
    ct."DTA_Refinery",
    ct."Formularity",
    ct."IDM",
    ct."IDPicker",
    ct."LCMSFeatureFinder",
    ct."Mage",
    ct."MASIC_Finnigan",
    ct."MaxqPeak",
    ct."MaxqS1",
    ct."MaxqS2",
    ct."MaxqS3",
    ct."MODa",
    ct."MODPlus",
    ct."MSAlign",
    ct."MSAlign_Quant",
    ct."MSDeconv",
    ct."MSFragger",
    ct."MSGF",
    ct."MSGFPlus",
    ct."MSMSSpectraPreprocessor",
    ct."MSPathFinder",
    ct."MSXML_Bruker",
    ct."MSXML_Gen",
    ct."Mz_Refinery",
    ct."PBF_Gen",
    ct."PepProtProphet",
    ct."Phospho_FDR_Aggregator",
    ct."PRIDE_Converter",
    ct."ProMex",
    ct."Results_Cleanup",
    ct."Results_Transfer",
    ct."Sequest",
    ct."SMAQC",
    ct."ThermoPeakDataExporter",
    ct."TopFD",
    ct."TopPIC",
    ct."XTandem"
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

