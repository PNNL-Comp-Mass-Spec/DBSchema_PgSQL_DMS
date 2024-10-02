--
-- Name: v_job_step_backlog_crosstab; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_job_step_backlog_crosstab AS
 SELECT posting_time,
    COALESCE("Bruker_DA_Export", 0) AS bruker_da_export,
    COALESCE("Cyclops", 0) AS cyclops,
    COALESCE("DataExtractor", 0) AS data_extractor,
    COALESCE("DataExtractorSplitFasta", 0) AS data_extractor_split_fasta,
    COALESCE("Decon2LS", 0) AS decon2ls,
    COALESCE("Decon2LS_V2", 0) AS decon2ls_v2,
    COALESCE("DTA_Gen", 0) AS dta_gen,
    COALESCE("DTA_Refinery", 0) AS dta_refinery,
    COALESCE("Formularity", 0) AS formularity,
    COALESCE("FragPipe", 0) AS fragpipe,
    COALESCE("ICR2LS", 0) AS icr2ls,
    COALESCE("IDM", 0) AS idm,
    COALESCE("IDPicker", 0) AS idpicker,
    COALESCE("Inspect", 0) AS inspect,
    COALESCE("LCMSFeatureFinder", 0) AS lcms_feature_finder,
    COALESCE("LTQ_FTPek", 0) AS ltq_ftpek,
    COALESCE("MASIC_Finnigan", 0) AS masic_finnigan,
    COALESCE("MaxqPeak", 0) AS maxq_peak,
    COALESCE("MaxqS1", 0) AS maxq_s1,
    COALESCE("MaxqS2", 0) AS maxq_s2,
    COALESCE("MaxqS3", 0) AS maxq_s3,
    COALESCE("MODa", 0) AS moda,
    COALESCE("MSAlign", 0) AS msalign,
    COALESCE("MSAlign_Quant", 0) AS msalign_quant,
    COALESCE("MSFragger", 0) AS msfragger,
    COALESCE("MSGF", 0) AS msgf,
    COALESCE("MSGFDB", 0) AS msgfdb,
    COALESCE("MSGFPlus", 0) AS msgfplus,
    COALESCE("MSPathFinder", 0) AS mspathfinder,
    COALESCE("MSXML_Gen", 0) AS msxml_gen,
    COALESCE("Mz_Refinery", 0) AS mz_refinery,
    COALESCE("NOMSI", 0) AS nomsi,
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
   FROM public.crosstab('SELECT date_trunc(''minute'', posting_time) AS posting_time,
           step_tool,
           backlog_count
    FROM sw.v_job_step_backlog_history
    ORDER BY 1,2'::text, 'SELECT unnest(''{Bruker_DA_Export, Cyclops, DataExtractor, DataExtractorSplitFasta, Decon2LS, Decon2LS_V2,
                     DTA_Gen, DTA_Refinery, Formularity, FragPipe, ICR2LS, IDM, IDPicker, Inspect, LCMSFeatureFinder, LTQ_FTPek,
                     MASIC_Finnigan, MaxqPeak, MaxqS1, MaxqS2, MaxqS3, MODa, MSAlign, MSAlign_Quant, MSFragger, MSGF,
                     MSGFDB, MSGFPlus, MSPathFinder, MSXML_Gen, Mz_Refinery, NOMSI, PBF_Gen, PepProtProphet,
                     Phospho_FDR_Aggregator, PRIDE_Converter, ProMex, Results_Cleanup, Results_Transfer,
                     Sequest, SMAQC, ThermoPeakDataExporter, TopFD, TopPIC, XTandem}''::text[])'::text) ct(posting_time timestamp without time zone, "Bruker_DA_Export" integer, "Cyclops" integer, "DataExtractor" integer, "DataExtractorSplitFasta" integer, "Decon2LS" integer, "Decon2LS_V2" integer, "DTA_Gen" integer, "DTA_Refinery" integer, "Formularity" integer, "FragPipe" integer, "ICR2LS" integer, "IDM" integer, "IDPicker" integer, "Inspect" integer, "LCMSFeatureFinder" integer, "LTQ_FTPek" integer, "MASIC_Finnigan" integer, "MaxqPeak" integer, "MaxqS1" integer, "MaxqS2" integer, "MaxqS3" integer, "MODa" integer, "MSAlign" integer, "MSAlign_Quant" integer, "MSFragger" integer, "MSGF" integer, "MSGFDB" integer, "MSGFPlus" integer, "MSPathFinder" integer, "MSXML_Gen" integer, "Mz_Refinery" integer, "NOMSI" integer, "PBF_Gen" integer, "PepProtProphet" integer, "Phospho_FDR_Aggregator" integer, "PRIDE_Converter" integer, "ProMex" integer, "Results_Cleanup" integer, "Results_Transfer" integer, "Sequest" integer, "SMAQC" integer, "ThermoPeakDataExporter" integer, "TopFD" integer, "TopPIC" integer, "XTandem" integer);


ALTER VIEW sw.v_job_step_backlog_crosstab OWNER TO d3l243;

--
-- Name: TABLE v_job_step_backlog_crosstab; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_job_step_backlog_crosstab TO readaccess;
GRANT SELECT ON TABLE sw.v_job_step_backlog_crosstab TO writeaccess;

