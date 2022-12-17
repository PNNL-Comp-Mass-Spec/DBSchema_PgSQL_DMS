--
-- Name: v_job_step_backlog_crosstab; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_job_step_backlog_crosstab AS
 SELECT ct.posting_time,
    COALESCE(ct."Bruker_DA_Export", 0) AS bruker_da_export,
    COALESCE(ct."Cyclops", 0) AS cyclops,
    COALESCE(ct."DataExtractor", 0) AS data_extractor,
    COALESCE(ct."DataExtractorSplitFasta", 0) AS data_extractor_split_fasta,
    COALESCE(ct."Decon2LS", 0) AS decon2ls,
    COALESCE(ct."Decon2LS_V2", 0) AS decon2ls_v2,
    COALESCE(ct."DTA_Gen", 0) AS dta_gen,
    COALESCE(ct."DTA_Refinery", 0) AS dta_refinery,
    COALESCE(ct."Formularity", 0) AS formularity,
    COALESCE(ct."ICR2LS", 0) AS icr2ls,
    COALESCE(ct."IDM", 0) AS idm,
    COALESCE(ct."IDPicker", 0) AS idpicker,
    COALESCE(ct."Inspect", 0) AS inspect,
    COALESCE(ct."LCMSFeatureFinder", 0) AS lcms_feature_finder,
    COALESCE(ct."LTQ_FTPek", 0) AS ltq_ftpek,
    COALESCE(ct."MASIC_Finnigan", 0) AS masic_finnigan,
    COALESCE(ct."MaxqPeak", 0) AS maxq_peak,
    COALESCE(ct."MaxqS1", 0) AS maxq_s1,
    COALESCE(ct."MaxqS2", 0) AS maxq_s2,
    COALESCE(ct."MaxqS3", 0) AS maxq_s3,
    COALESCE(ct."MODa", 0) AS moda,
    COALESCE(ct."MSAlign", 0) AS msalign,
    COALESCE(ct."MSAlign_Quant", 0) AS msalign_quant,
    COALESCE(ct."MSFragger", 0) AS msfragger,
    COALESCE(ct."MSGF", 0) AS msgf,
    COALESCE(ct."MSGFDB", 0) AS msgfdb,
    COALESCE(ct."MSGFPlus", 0) AS msgfplus,
    COALESCE(ct."MSPathFinder", 0) AS mspathfinder,
    COALESCE(ct."MSXML_Gen", 0) AS msxml_gen,
    COALESCE(ct."Mz_Refinery", 0) AS mz_refinery,
    COALESCE(ct."NOMSI", 0) AS nomsi,
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
   FROM public.crosstab('SELECT date_trunc(''minute'', posting_time) AS posting_time,
           step_tool,
           backlog_count
    FROM sw.v_job_step_backlog_history
    ORDER BY 1,2'::text, 'SELECT unnest(''{Bruker_DA_Export, Cyclops, DataExtractor, DataExtractorSplitFasta, Decon2LS, Decon2LS_V2,
                     DTA_Gen, DTA_Refinery, Formularity, ICR2LS, IDM, IDPicker, Inspect, LCMSFeatureFinder, LTQ_FTPek,
                     MASIC_Finnigan, MaxqPeak, MaxqS1, MaxqS2, MaxqS3, MODa, MSAlign, MSAlign_Quant, MSFragger, MSGF,
                     MSGFDB, MSGFPlus, MSPathFinder, MSXML_Gen, Mz_Refinery, NOMSI, PBF_Gen, PepProtProphet,
                     Phospho_FDR_Aggregator, PRIDE_Converter, ProMex, Results_Cleanup, Results_Transfer,
                     Sequest, SMAQC, ThermoPeakDataExporter, TopFD, TopPIC, XTandem}''::text[])'::text) ct(posting_time timestamp without time zone, "Bruker_DA_Export" integer, "Cyclops" integer, "DataExtractor" integer, "DataExtractorSplitFasta" integer, "Decon2LS" integer, "Decon2LS_V2" integer, "DTA_Gen" integer, "DTA_Refinery" integer, "Formularity" integer, "ICR2LS" integer, "IDM" integer, "IDPicker" integer, "Inspect" integer, "LCMSFeatureFinder" integer, "LTQ_FTPek" integer, "MASIC_Finnigan" integer, "MaxqPeak" integer, "MaxqS1" integer, "MaxqS2" integer, "MaxqS3" integer, "MODa" integer, "MSAlign" integer, "MSAlign_Quant" integer, "MSFragger" integer, "MSGF" integer, "MSGFDB" integer, "MSGFPlus" integer, "MSPathFinder" integer, "MSXML_Gen" integer, "Mz_Refinery" integer, "NOMSI" integer, "PBF_Gen" integer, "PepProtProphet" integer, "Phospho_FDR_Aggregator" integer, "PRIDE_Converter" integer, "ProMex" integer, "Results_Cleanup" integer, "Results_Transfer" integer, "Sequest" integer, "SMAQC" integer, "ThermoPeakDataExporter" integer, "TopFD" integer, "TopPIC" integer, "XTandem" integer);


ALTER TABLE sw.v_job_step_backlog_crosstab OWNER TO d3l243;

--
-- Name: TABLE v_job_step_backlog_crosstab; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_job_step_backlog_crosstab TO readaccess;
GRANT SELECT ON TABLE sw.v_job_step_backlog_crosstab TO writeaccess;

