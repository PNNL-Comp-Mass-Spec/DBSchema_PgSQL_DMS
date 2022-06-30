--
-- Name: v_storage_crosstab_dataset_count; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_storage_crosstab_dataset_count AS
 SELECT pivotdata.vol_client,
    COALESCE(pivotdata."21T", 0) AS "21T",
    COALESCE(pivotdata."Agilent_GC-MS", 0) AS agilent_gcms,
    COALESCE(pivotdata.agilent_qqq, 0) AS agilent_qqq,
    COALESCE(pivotdata.agilent_tof_v2, 0) AS agilent_tof_v2,
    COALESCE(pivotdata.bruker_ftms, 0) AS bruker_ftms,
    COALESCE(pivotdata.eclipse, 0) AS eclipse,
    COALESCE(pivotdata.exactive, 0) AS exactive,
    COALESCE(pivotdata."GC-QExactive", 0) AS gc_qexactive,
    COALESCE(pivotdata.ims, 0) AS ims,
    COALESCE(pivotdata.lcq, 0) AS lcq,
    COALESCE(pivotdata.ltq, 0) AS ltq,
    COALESCE(pivotdata."LTQ-ETD", 0) AS ltq_etd,
    COALESCE(pivotdata.lumos, 0) AS lumos,
    COALESCE(pivotdata."MALDI-Imaging", 0) AS maldi_imaging,
    COALESCE(pivotdata.orbitrap, 0) AS orbitrap,
    COALESCE(pivotdata.qehfx, 0) AS qehfx,
    COALESCE(pivotdata.qexactive, 0) AS qexactive,
    COALESCE(pivotdata."QExactive-Imaging", 0) AS qexactive_imaging,
    COALESCE(pivotdata.slim, 0) AS slim,
    COALESCE(pivotdata.tsq, 0) AS tsq,
    COALESCE(pivotdata.velosorbi, 0) AS velosorbi,
    COALESCE(pivotdata.waters_ims, 0) AS waters_ims,
    COALESCE(pivotdata.waters_tof, 0) AS waters_tof
   FROM public.crosstab('SELECT Lower(Vol_Client) AS Vol_Client, Inst_Group, SUM(Datasets) AS Datasets
    FROM V_Storage_Summary
    GROUP BY Lower(Vol_Client), Inst_Group
    ORDER BY 1, 2'::text, 'SELECT unnest(''{21T, Agilent_GC-MS, Agilent_QQQ, Agilent_TOF_V2, Bruker_FTMS,
                     Eclipse, Exactive, FT_ZippedSFolders, GC-QExactive, IMS, LCQ, LTQ, LTQ-ETD, Lumos,
                     MALDI-Imaging, Orbitrap, QEHFX, QExactive, QExactive-Imaging,
                     SLIM, TSQ, VelosOrbi, Waters_IMS, Waters_TOF}''::text[])'::text) pivotdata(vol_client public.citext, "21T" integer, "Agilent_GC-MS" integer, agilent_qqq integer, agilent_tof_v2 integer, bruker_ftms integer, eclipse integer, exactive integer, ft_zippedsfolders integer, "GC-QExactive" integer, ims integer, lcq integer, ltq integer, "LTQ-ETD" integer, lumos integer, "MALDI-Imaging" integer, orbitrap integer, qehfx integer, qexactive integer, "QExactive-Imaging" integer, slim integer, tsq integer, velosorbi integer, waters_ims integer, waters_tof integer);


ALTER TABLE public.v_storage_crosstab_dataset_count OWNER TO d3l243;

--
-- Name: TABLE v_storage_crosstab_dataset_count; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_storage_crosstab_dataset_count TO readaccess;

