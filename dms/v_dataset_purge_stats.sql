--
-- Name: v_dataset_purge_stats; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_purge_stats AS
 SELECT lookupq.year,
    lookupq.month,
    lookupq.storage_path,
    lookupq.instrument,
    lookupq.dataset_count,
    lookupq.purged_datasets,
    round((((lookupq.purged_datasets)::numeric / (lookupq.dataset_count)::numeric) * (100)::numeric), 2) AS percent_purged
   FROM ( SELECT EXTRACT(year FROM ds.created) AS year,
            EXTRACT(month FROM ds.created) AS month,
            ((('\\'::text || (spath.machine_name)::text) || '\'::text) || (spath.storage_path)::text) AS storage_path,
            instname.instrument,
            count(*) AS dataset_count,
            sum(da.instrument_data_purged) AS purged_datasets
           FROM (((public.t_dataset ds
             JOIN public.t_storage_path spath ON ((ds.storage_path_id = spath.storage_path_id)))
             JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
             JOIN public.t_dataset_archive da ON ((ds.dataset_id = da.dataset_id)))
          GROUP BY instname.instrument, ((('\\'::text || (spath.machine_name)::text) || '\'::text) || (spath.storage_path)::text), (EXTRACT(year FROM ds.created)), (EXTRACT(month FROM ds.created))) lookupq;


ALTER TABLE public.v_dataset_purge_stats OWNER TO d3l243;

--
-- Name: TABLE v_dataset_purge_stats; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_purge_stats TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_purge_stats TO writeaccess;

