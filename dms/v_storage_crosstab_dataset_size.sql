--
-- Name: v_storage_crosstab_dataset_size; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_storage_crosstab_dataset_size AS
 SELECT vol_client,
    COALESCE("21T", (0)::double precision) AS "21T",
    COALESCE(agilent_gc_ms, (0)::double precision) AS agilent_gcms,
    COALESCE(agilent_qqq, (0)::double precision) AS agilent_qqq,
    COALESCE(agilent_tof_v2, (0)::double precision) AS agilent_tof_v2,
    COALESCE(bruker_ftms, (0)::double precision) AS bruker_ftms,
    COALESCE(eclipse, (0)::double precision) AS eclipse,
    COALESCE(exactive, (0)::double precision) AS exactive,
    COALESCE(gc_qexactive, (0)::double precision) AS gc_qexactive,
    COALESCE(ims, (0)::double precision) AS ims,
    COALESCE(lcq, (0)::double precision) AS lcq,
    COALESCE(ltq, (0)::double precision) AS ltq,
    COALESCE(ltq_etd, (0)::double precision) AS ltq_etd,
    COALESCE(lumos, (0)::double precision) AS lumos,
    COALESCE(maldi_imaging, (0)::double precision) AS maldi_imaging,
    COALESCE(orbitrap, (0)::double precision) AS orbitrap,
    COALESCE(qehfx, (0)::double precision) AS qehfx,
    COALESCE(qexactive, (0)::double precision) AS qexactive,
    COALESCE(qexactive_imaging, (0)::double precision) AS qexactive_imaging,
    COALESCE(slim, (0)::double precision) AS slim,
    COALESCE(tsq, (0)::double precision) AS tsq,
    COALESCE(velosorbi, (0)::double precision) AS velosorbi,
    COALESCE(waters_ims, (0)::double precision) AS waters_ims,
    COALESCE(waters_tof, (0)::double precision) AS waters_tof
   FROM public.crosstab('SELECT Lower(Vol_Client) AS Vol_Client, Inst_Group, SUM(File_Size_GB) AS File_Size_GB
    FROM V_Storage_Summary
    GROUP BY Lower(Vol_Client), Inst_Group
    ORDER BY 1, 2'::text, 'SELECT unnest(''{21T, Agilent_GC_MS, Agilent_QQQ, Agilent_TOF_V2, Bruker_FTMS,
                     Eclipse, Exactive, FT_ZippedSFolders, GC_QExactive, IMS, LCQ, LTQ, LTQ_ETD, Lumos,
                     MALDI_Imaging, Orbitrap, QEHFX, QExactive, QExactive_Imaging,
                     SLIM, TSQ, VelosOrbi, Waters_IMS, Waters_TOF}''::text[])'::text) pivotdata(vol_client public.citext, "21T" double precision, agilent_gc_ms double precision, agilent_qqq double precision, agilent_tof_v2 double precision, bruker_ftms double precision, eclipse double precision, exactive double precision, ft_zippedsfolders double precision, gc_qexactive double precision, ims double precision, lcq double precision, ltq double precision, ltq_etd double precision, lumos double precision, maldi_imaging double precision, orbitrap double precision, qehfx double precision, qexactive double precision, qexactive_imaging double precision, slim double precision, tsq double precision, velosorbi double precision, waters_ims double precision, waters_tof double precision);


ALTER VIEW public.v_storage_crosstab_dataset_size OWNER TO d3l243;

--
-- Name: TABLE v_storage_crosstab_dataset_size; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_storage_crosstab_dataset_size TO readaccess;
GRANT SELECT ON TABLE public.v_storage_crosstab_dataset_size TO writeaccess;

