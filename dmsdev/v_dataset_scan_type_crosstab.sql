--
-- Name: v_dataset_scan_type_crosstab; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_scan_type_crosstab AS
 SELECT dataset_id,
    dataset,
    scan_count_total,
    COALESCE("HMS", 0) AS "HMS",
    COALESCE("MS", 0) AS "MS",
    COALESCE("CID-HMSn", 0) AS "CID-HMSn",
    COALESCE("CID-MSn", 0) AS "CID-MSn",
    COALESCE("SA_CID-HMSn", 0) AS "SA_CID-HMSn",
    COALESCE("HCD-HMSn", 0) AS "HCD-HMSn",
    COALESCE("HCD-MSn", 0) AS "HCD-MSn",
    COALESCE("SA_HCD-HMSn", 0) AS "SA_HCD-HMSn",
    COALESCE("EThcD-HMSn", 0) AS "EThcD-HMSn",
    COALESCE("ETD-HMSn", 0) AS "ETD-HMSn",
    COALESCE("SA_ETD-HMSn", 0) AS "SA_ETD-HMSn",
    COALESCE("ETD-MSn", 0) AS "ETD-MSn",
    COALESCE("SA_ETD-MSn", 0) AS "SA_ETD-MSn",
    COALESCE("HMSn", 0) AS "HMSn",
    COALESCE("MSn", 0) AS "MSn",
    COALESCE("GC-MS", 0) AS "GC-MS",
    COALESCE("SRM", 0) AS "SRM",
    COALESCE("CID-SRM", 0) AS "CID-SRM",
    COALESCE("MALDI-HMS", 0) AS "MALDI-HMS",
    COALESCE("PTR-HMSn", 0) AS "PTR-HMSn",
    COALESCE("PTR-MSn", 0) AS "PTR-MSn",
    COALESCE("PQD-HMSn", 0) AS "PQD-HMSn",
    COALESCE("PQD-MSn", 0) AS "PQD-MSn",
    COALESCE("Q1MS", 0) AS "Q1MS",
    COALESCE("Q3MS", 0) AS "Q3MS",
    COALESCE("SIM ms", 0) AS "SIM ms",
    COALESCE("UVPD-HMSn", 0) AS "UVPD-HMSn",
    COALESCE("UVPD-MSn", 0) AS "UVPD-MSn",
    COALESCE("Zoom-MS", 0) AS "Zoom-MS"
   FROM public.crosstab('SELECT DS.dataset_id,
            DS.dataset,
            DS.scan_count AS scan_count_total,
            DST.scan_type,
            SUM(DST.scan_count) AS scan_count_for_type
    FROM public.t_dataset DS
         INNER JOIN public.t_dataset_scan_types DST
           ON DS.Dataset_ID = DST.Dataset_ID
    GROUP BY DS.dataset_id, DS.dataset, DS.scan_count, DST.scan_type
    ORDER BY DS.Dataset_ID, DST.scan_type'::text, 'SELECT unnest(''{
HMS, MS, CID-HMSn, CID-MSn, SA_CID-HMSn,
HCD-HMSn, HCD-MSn, SA_HCD-HMSn,
EThcD-HMSn, ETD-HMSn, SA_ETD-HMSn, ETD-MSn, SA_ETD-MSn,
HMSn, MSn, GC-MS, SRM, CID-SRM, MALDI-HMS,
PTR-HMSn, PTR-MSn, PQD-HMSn, PQD-MSn,
Q1MS, Q3MS, SIM ms, UVPD-HMSn, UVPD-MSn, Zoom-MS}''::text[])'::text) pivotdata(dataset_id integer, dataset public.citext, scan_count_total integer, "HMS" integer, "MS" integer, "CID-HMSn" integer, "CID-MSn" integer, "SA_CID-HMSn" integer, "HCD-HMSn" integer, "HCD-MSn" integer, "SA_HCD-HMSn" integer, "EThcD-HMSn" integer, "ETD-HMSn" integer, "SA_ETD-HMSn" integer, "ETD-MSn" integer, "SA_ETD-MSn" integer, "HMSn" integer, "MSn" integer, "GC-MS" integer, "SRM" integer, "CID-SRM" integer, "MALDI-HMS" integer, "PTR-HMSn" integer, "PTR-MSn" integer, "PQD-HMSn" integer, "PQD-MSn" integer, "Q1MS" integer, "Q3MS" integer, "SIM ms" integer, "UVPD-HMSn" integer, "UVPD-MSn" integer, "Zoom-MS" integer);


ALTER VIEW public.v_dataset_scan_type_crosstab OWNER TO d3l243;

--
-- Name: TABLE v_dataset_scan_type_crosstab; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_scan_type_crosstab TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_scan_type_crosstab TO writeaccess;

