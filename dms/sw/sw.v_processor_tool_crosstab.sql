--
-- Name: v_processor_tool_crosstab; Type: VIEW; Schema: sw; Owner: d3l243
--

CREATE VIEW sw.v_processor_tool_crosstab AS
 SELECT processor_name,
    group_name,
    group_id,
    "Ape",
    "AScore",
    "Cyclops",
    "DataExtractor",
    "DataExtractorSplitFasta",
    "Decon2LS_V2",
    "DTA_Gen",
    "DTA_Refinery",
    "Formularity",
    "FragPipe",
    "IDM",
    "IDPicker",
    "LCMSFeatureFinder",
    "Mage",
    "MASIC_Finnigan",
    "MaxqPeak",
    "MaxqS1",
    "MaxqS2",
    "MaxqS3",
    "MODa",
    "MODPlus",
    "MSAlign",
    "MSAlign_Quant",
    "MSDeconv",
    "MSFragger",
    "MSGF",
    "MSGFPlus",
    "MSMSSpectraPreprocessor",
    "MSPathFinder",
    "MSXML_Bruker",
    "MSXML_Gen",
    "Mz_Refinery",
    "PBF_Gen",
    "PepProtProphet",
    "Phospho_FDR_Aggregator",
    "PRIDE_Converter",
    "ProMex",
    "Results_Cleanup",
    "Results_Transfer",
    "Sequest",
    "SMAQC",
    "ThermoPeakDataExporter",
    "TopFD",
    "TopPIC",
    "XTandem"
   FROM public.crosstab('SELECT LP.Processor_Name,
           PTG.Group_Name,
           PTG.Group_ID,
           PTGD.Tool_Name,
           MIN(PTGD.Priority) AS Priority
    FROM sw.t_machines M
             INNER JOIN sw.t_local_processors LP
               ON M.Machine = LP.Machine
             INNER JOIN sw.t_processor_tool_groups PTG
               ON M.proc_tool_group_id = PTG.Group_ID
             INNER JOIN sw.t_processor_tool_group_details PTGD
               ON PTG.Group_ID = PTGD.Group_ID AND
                  LP.proc_tool_mgr_id = PTGD.Mgr_ID
        WHERE PTGD.enabled > 0
        Group By LP.Processor_Name, PTG.Group_Name, PTG.Group_ID, PTGD.Tool_Name
    ORDER BY LP.Processor_Name, PTG.Group_Name, PTG.Group_ID, PTGD.Tool_Name'::text, 'SELECT unnest(''{Ape, AScore, Cyclops, DataExtractor, DataExtractorSplitFasta, Decon2LS_V2, DTA_Gen, DTA_Refinery,
                     Formularity, FragPipe, IDM, IDPicker, LCMSFeatureFinder, Mage, MASIC_Finnigan, MaxqPeak, MaxqS1, MaxqS2, MaxqS3,
                     MODa, MODPlus, MSAlign, MSAlign_Quant, MSDeconv, MSFragger, MSGF, MSGFPlus, MSMSSpectraPreprocessor,
                     MSPathFinder, MSXML_Bruker, MSXML_Gen, Mz_Refinery, PBF_Gen, PepProtProphet, Phospho_FDR_Aggregator,
                     PRIDE_Converter, ProMex, Results_Cleanup, Results_Transfer, Sequest, SMAQC,
                     ThermoPeakDataExporter, TopFD, TopPIC, XTandem}''::citext[])'::text) ct(processor_name public.citext, group_name public.citext, group_id public.citext, "Ape" integer, "AScore" integer, "Cyclops" integer, "DataExtractor" integer, "DataExtractorSplitFasta" integer, "Decon2LS_V2" integer, "DTA_Gen" integer, "DTA_Refinery" integer, "Formularity" integer, "FragPipe" integer, "IDM" integer, "IDPicker" integer, "LCMSFeatureFinder" integer, "Mage" integer, "MASIC_Finnigan" integer, "MaxqPeak" integer, "MaxqS1" integer, "MaxqS2" integer, "MaxqS3" integer, "MODa" integer, "MODPlus" integer, "MSAlign" integer, "MSAlign_Quant" integer, "MSDeconv" integer, "MSFragger" integer, "MSGF" integer, "MSGFPlus" integer, "MSMSSpectraPreprocessor" integer, "MSPathFinder" integer, "MSXML_Bruker" integer, "MSXML_Gen" integer, "Mz_Refinery" integer, "PBF_Gen" integer, "PepProtProphet" integer, "Phospho_FDR_Aggregator" integer, "PRIDE_Converter" integer, "ProMex" integer, "Results_Cleanup" integer, "Results_Transfer" integer, "Sequest" integer, "SMAQC" integer, "ThermoPeakDataExporter" integer, "TopFD" integer, "TopPIC" integer, "XTandem" integer);


ALTER VIEW sw.v_processor_tool_crosstab OWNER TO d3l243;

--
-- Name: TABLE v_processor_tool_crosstab; Type: ACL; Schema: sw; Owner: d3l243
--

GRANT SELECT ON TABLE sw.v_processor_tool_crosstab TO readaccess;
GRANT SELECT ON TABLE sw.v_processor_tool_crosstab TO writeaccess;

