--
-- Name: v_analysis_tool_dataset_type_crosstab; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_analysis_tool_dataset_type_crosstab AS
 SELECT pivotdata.tool_name,
    COALESCE(pivotdata."HMS", 0) AS "HMS",
    COALESCE(pivotdata."HMS-HMSn", 0) AS "HMS-HMSn",
    COALESCE(pivotdata."HMS-MSn", 0) AS "HMS-MSn",
    COALESCE(pivotdata."HMS-CID/ETD-HMSn", 0) AS "HMS-CID/ETD-HMSn",
    COALESCE(pivotdata."HMS-ETD-HMSn", 0) AS "HMS-ETD-HMSn",
    COALESCE(pivotdata."HMS-ETD-MSn", 0) AS "HMS-ETD-MSn",
    COALESCE(pivotdata."HMS-EThcD-HMSn", 0) AS "HMS-EThcD-HMSn",
    COALESCE(pivotdata."HMS-HCD-CID/ETD-HMSn", 0) AS "HMS-HCD-CID/ETD-HMSn",
    COALESCE(pivotdata."HMS-HCD-CID-HMSn", 0) AS "HMS-HCD-CID-HMSn",
    COALESCE(pivotdata."HMS-HCD-CID-MSn", 0) AS "HMS-HCD-CID-MSn",
    COALESCE(pivotdata."HMS-HCD-ETD-HMSn", 0) AS "HMS-HCD-ETD-HMSn",
    COALESCE(pivotdata."HMS-HCD-ETD-MSn", 0) AS "HMS-HCD-ETD-MSn",
    COALESCE(pivotdata."HMS-HCD-HMSn", 0) AS "HMS-HCD-HMSn",
    COALESCE(pivotdata."HMS-HCD-MSn", 0) AS "HMS-HCD-MSn",
    COALESCE(pivotdata."IMS-HMS", 0) AS "IMS-HMS",
    COALESCE(pivotdata."IMS-HMS-HMSn", 0) AS "IMS-HMS-HMSn",
    COALESCE(pivotdata."GC-MS", 0) AS "GC-MS",
    COALESCE(pivotdata."MALDI-HMS", 0) AS "MALDI-HMS",
    COALESCE(pivotdata."MRM", 0) AS "MRM",
    COALESCE(pivotdata."MS", 0) AS "MS",
    COALESCE(pivotdata."MS-MSn", 0) AS "MS-MSn"
   FROM public.crosstab('SELECT Tool.analysis_tool AS Tool_Name, ADT.Dataset_Type, 1 AS Valid
    FROM public.t_analysis_tool_allowed_dataset_type ADT
         INNER JOIN public.t_analysis_tool Tool
           ON ADT.Analysis_Tool_ID = Tool.analysis_tool_id
    ORDER BY 1, 2'::text, 'SELECT unnest(''{HMS,HMS-HMSn,HMS-MSn,HMS-CID/ETD-HMSn,
                     HMS-ETD-HMSn,HMS-ETD-MSn,HMS-EThcD-HMSn,
                     HMS-HCD-CID/ETD-HMSn,HMS-HCD-CID-HMSn,HMS-HCD-CID-MSn,
                     HMS-HCD-ETD-HMSn,HMS-HCD-ETD-MSn,HMS-HCD-HMSn,
                     HMS-HCD-MSn,IMS-HMS,IMS-HMS-HMSn,
                     GC-MS,MALDI-HMS,MRM,MS,MS-MSn}''::text[])'::text) pivotdata(tool_name public.citext, "HMS" integer, "HMS-HMSn" integer, "HMS-MSn" integer, "HMS-CID/ETD-HMSn" integer, "HMS-ETD-HMSn" integer, "HMS-ETD-MSn" integer, "HMS-EThcD-HMSn" integer, "HMS-HCD-CID/ETD-HMSn" integer, "HMS-HCD-CID-HMSn" integer, "HMS-HCD-CID-MSn" integer, "HMS-HCD-ETD-HMSn" integer, "HMS-HCD-ETD-MSn" integer, "HMS-HCD-HMSn" integer, "HMS-HCD-MSn" integer, "IMS-HMS" integer, "IMS-HMS-HMSn" integer, "GC-MS" integer, "MALDI-HMS" integer, "MRM" integer, "MS" integer, "MS-MSn" integer);


ALTER TABLE public.v_analysis_tool_dataset_type_crosstab OWNER TO d3l243;

--
-- Name: TABLE v_analysis_tool_dataset_type_crosstab; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_analysis_tool_dataset_type_crosstab TO readaccess;

