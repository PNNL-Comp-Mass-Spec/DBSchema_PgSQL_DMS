--
-- Name: v_dataset_scan_type_crosstab; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_scan_type_crosstab AS
 SELECT pivotdata.dataset_id,
    pivotdata.dataset,
    pivotdata.scan_count_total,
    COALESCE(pivotdata."HMS", 0) AS "HMS",
    COALESCE(pivotdata."MS", 0) AS "MS",
    COALESCE(pivotdata."CID-HMSn", 0) AS "CID-HMSn",
    COALESCE(pivotdata."CID-MSn", 0) AS "CID-MSn",
    COALESCE(pivotdata."SA_CID-HMSn", 0) AS "SA_CID-HMSn",
    COALESCE(pivotdata."HCD-HMSn", 0) AS "HCD-HMSn",
    COALESCE(pivotdata."HCD-MSn", 0) AS "HCD-MSn",
    COALESCE(pivotdata."SA_HCD-HMSn", 0) AS "SA_HCD-HMSn",
    COALESCE(pivotdata."EThcD-HMSn", 0) AS "EThcD-HMSn",
    COALESCE(pivotdata."ETD-HMSn", 0) AS "ETD-HMSn",
    COALESCE(pivotdata."ETD-MSn", 0) AS "ETD-MSn",
    COALESCE(pivotdata."SA_ETD-HMSn", 0) AS "SA_ETD-HMSn",
    COALESCE(pivotdata."SA_ETD-MSn", 0) AS "SA_ETD-MSn",
    COALESCE(pivotdata."HMSn", 0) AS "HMSn",
    COALESCE(pivotdata."MSn", 0) AS "MSn",
    COALESCE(pivotdata."GC-MS", 0) AS "GC-MS",
    COALESCE(pivotdata."SRM", 0) AS "SRM",
    COALESCE(pivotdata."CID-SRM", 0) AS "CID-SRM",
    COALESCE(pivotdata."MALDI-HMS", 0) AS "MALDI-HMS",
    COALESCE(pivotdata."PTR-HMSn", 0) AS "PTR-HMSn",
    COALESCE(pivotdata."PTR-MSn", 0) AS "PTR-MSn",
    COALESCE(pivotdata."Q1MS", 0) AS "Q1MS",
    COALESCE(pivotdata."Q3MS", 0) AS "Q3MS",
    COALESCE(pivotdata."SIM ms", 0) AS "SIM ms",
    COALESCE(pivotdata."UVPD-HMSn", 0) AS "UVPD-HMSn",
    COALESCE(pivotdata."UVPD-MSn", 0) AS "UVPD-MSn"
   FROM public.crosstab('SELECT DS.dataset_id,
            DS.dataset,
            DS.scan_count AS scan_count_total,
            DST.scan_type,
            SUM(DST.scan_count) AS scan_count_for_type
    FROM public.t_dataset DS
         INNER JOIN public.t_dataset_scan_types DST
           ON DS.Dataset_ID = DST.Dataset_ID
    GROUP BY DS.dataset_id, DS.dataset, DS.scan_count, DST.scan_type
    ORDER BY DS.Dataset_ID, DST.scan_type'::text, 'SELECT unnest(''{HMS,MS,CID-HMSn,CID-MSn,SA_CID-HMSn,
                     HCD-HMSn,HCD-MSn,SA_HCD-HMSn,
                     EThcD-HMSn,ETD-HMSn,ETD-MSn,SA_ETD-HMSn,SA_ETD-MSn,
                     HMSn,MSn,GC-MS,SRM,CID-SRM,MALDI-HMS,PTR-HMSn,PTR-MSn,
                     Q1MS,Q3MS,SIM ms,UVPD-HMSn,UVPD-MSn}''::text[])'::text) pivotdata(dataset_id integer, dataset public.citext, scan_count_total integer, "HMS" integer, "MS" integer, "CID-HMSn" integer, "CID-MSn" integer, "SA_CID-HMSn" integer, "HCD-HMSn" integer, "HCD-MSn" integer, "SA_HCD-HMSn" integer, "EThcD-HMSn" integer, "ETD-HMSn" integer, "ETD-MSn" integer, "SA_ETD-HMSn" integer, "SA_ETD-MSn" integer, "HMSn" integer, "MSn" integer, "GC-MS" integer, "SRM" integer, "CID-SRM" integer, "MALDI-HMS" integer, "PTR-HMSn" integer, "PTR-MSn" integer, "Q1MS" integer, "Q3MS" integer, "SIM ms" integer, "UVPD-HMSn" integer, "UVPD-MSn" integer);


ALTER TABLE public.v_dataset_scan_type_crosstab OWNER TO d3l243;

--
-- Name: TABLE v_dataset_scan_type_crosstab; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_scan_type_crosstab TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_scan_type_crosstab TO writeaccess;

