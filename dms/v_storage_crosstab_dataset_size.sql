--
-- Name: v_storage_crosstab_dataset_size; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_storage_crosstab_dataset_size AS
 SELECT vol_client,
    COALESCE("21T", (0)::double precision) AS "21T",
    COALESCE("Agilent_GC-MS", (0)::double precision) AS agilent_gcms,
    COALESCE(agilent_qqq, (0)::double precision) AS agilent_qqq,
    COALESCE(agilent_tof_v2, (0)::double precision) AS agilent_tof_v2,
    COALESCE(bruker_ftms, (0)::double precision) AS bruker_ftms,
    COALESCE(eclipse, (0)::double precision) AS eclipse,
    COALESCE(exactive, (0)::double precision) AS exactive,
    COALESCE("GC-QExactive", (0)::double precision) AS gc_qexactive,
    COALESCE(ims, (0)::double precision) AS ims,
    COALESCE(lcq, (0)::double precision) AS lcq,
    COALESCE(ltq, (0)::double precision) AS ltq,
    COALESCE("LTQ-ETD", (0)::double precision) AS ltq_etd,
    COALESCE(lumos, (0)::double precision) AS lumos,
    COALESCE("MALDI-Imaging", (0)::double precision) AS maldi_imaging,
    COALESCE(orbitrap, (0)::double precision) AS orbitrap,
    COALESCE(qehfx, (0)::double precision) AS qehfx,
    COALESCE(qexactive, (0)::double precision) AS qexactive,
    COALESCE("QExactive-Imaging", (0)::double precision) AS qexactive_imaging,
    COALESCE(slim, (0)::double precision) AS slim,
    COALESCE(tsq, (0)::double precision) AS tsq,
    COALESCE(velosorbi, (0)::double precision) AS velosorbi,
    COALESCE(waters_ims, (0)::double precision) AS waters_ims,
    COALESCE(waters_tof, (0)::double precision) AS waters_tof
   FROM public.crosstab('SELECT Lower(Vol_Client) AS Vol_Client, Inst_Group, SUM(File_Size_GB) AS File_Size_GB
    FROM V_Storage_Summary
    GROUP BY Lower(Vol_Client), Inst_Group
    ORDER BY 1, 2'::text, 'SELECT unnest(''{21T, Agilent_GC-MS, Agilent_QQQ, Agilent_TOF_V2, Bruker_FTMS,
                     Eclipse, Exactive, FT_ZippedSFolders, GC-QExactive, IMS, LCQ, LTQ, LTQ-ETD, Lumos,
                     MALDI-Imaging, Orbitrap, QEHFX, QExactive, QExactive-Imaging,
                     SLIM, TSQ, VelosOrbi, Waters_IMS, Waters_TOF}''::text[])'::text) pivotdata(vol_client public.citext, "21T" double precision, "Agilent_GC-MS" double precision, agilent_qqq double precision, agilent_tof_v2 double precision, bruker_ftms double precision, eclipse double precision, exactive double precision, ft_zippedsfolders double precision, "GC-QExactive" double precision, ims double precision, lcq double precision, ltq double precision, "LTQ-ETD" double precision, lumos double precision, "MALDI-Imaging" double precision, orbitrap double precision, qehfx double precision, qexactive double precision, "QExactive-Imaging" double precision, slim double precision, tsq double precision, velosorbi double precision, waters_ims double precision, waters_tof double precision);


ALTER VIEW public.v_storage_crosstab_dataset_size OWNER TO d3l243;

--
-- Name: TABLE v_storage_crosstab_dataset_size; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_storage_crosstab_dataset_size TO readaccess;
GRANT SELECT ON TABLE public.v_storage_crosstab_dataset_size TO writeaccess;

