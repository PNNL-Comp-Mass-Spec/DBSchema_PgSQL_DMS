--
-- Name: v_storage_crosstab_dataset_count; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_storage_crosstab_dataset_count AS
 SELECT vol_client,
    COALESCE("EMSL_21T", 0) AS "EMSL_21T",
    COALESCE(agilent_gc_ms, 0) AS agilent_gcms,
    COALESCE(agilent_qqq, 0) AS agilent_qqq,
    COALESCE(agilent_tof_v2, 0) AS agilent_tof_v2,
    COALESCE(emsl_bruker_ftms, 0) AS emsl_bruker_ftms,
    COALESCE(eclipse, 0) AS eclipse,
    COALESCE(exactive, 0) AS exactive,
    COALESCE(emsl_gc_qexactive, 0) AS emsl_gc_qexactive,
    COALESCE(ims, 0) AS ims,
    COALESCE(lcq, 0) AS lcq,
    COALESCE(ltq, 0) AS ltq,
    COALESCE(ltq_etd, 0) AS ltq_etd,
    COALESCE(lumos, 0) AS lumos,
    COALESCE(emsl_maldi_imaging, 0) AS emsl_maldi_imaging,
    COALESCE(orbitrap, 0) AS orbitrap,
    COALESCE(qehfx, 0) AS qehfx,
    COALESCE(qexactive, 0) AS qexactive,
    COALESCE(emsl_qexactive_imaging, 0) AS emsl_qexactive_imaging,
    COALESCE(slim, 0) AS slim,
    COALESCE(tsq, 0) AS tsq,
    COALESCE(velosorbi, 0) AS velosorbi,
    COALESCE(emsl_waters_ims, 0) AS emsl_waters_ims,
    COALESCE(waters_tof, 0) AS waters_tof
   FROM public.crosstab('SELECT Lower(Vol_Client) AS Vol_Client, Inst_Group, SUM(Datasets) AS Datasets
    FROM V_Storage_Summary
    GROUP BY Lower(Vol_Client), Inst_Group
    ORDER BY 1, 2'::text, 'SELECT unnest(''{EMSL_21T, Agilent_GC_MS, Agilent_QQQ, Agilent_TOF_V2, EMSL_Bruker_FTMS,
                     Eclipse, Exactive, FT_ZippedSFolders, EMSL_GC_QExactive, IMS, LCQ, LTQ, LTQ_ETD, Lumos,
                     EMSL_MALDI_Imaging, Orbitrap, QEHFX, QExactive, EMSL_QExactive_Imaging,
                     SLIM, TSQ, VelosOrbi, EMSL_Waters_IMS, Waters_TOF}''::text[])'::text) pivotdata(vol_client public.citext, "EMSL_21T" integer, agilent_gc_ms integer, agilent_qqq integer, agilent_tof_v2 integer, emsl_bruker_ftms integer, eclipse integer, exactive integer, ft_zippedsfolders integer, emsl_gc_qexactive integer, ims integer, lcq integer, ltq integer, ltq_etd integer, lumos integer, emsl_maldi_imaging integer, orbitrap integer, qehfx integer, qexactive integer, emsl_qexactive_imaging integer, slim integer, tsq integer, velosorbi integer, emsl_waters_ims integer, waters_tof integer);


ALTER VIEW public.v_storage_crosstab_dataset_count OWNER TO d3l243;

--
-- Name: TABLE v_storage_crosstab_dataset_count; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_storage_crosstab_dataset_count TO readaccess;
GRANT SELECT ON TABLE public.v_storage_crosstab_dataset_count TO writeaccess;

