--
-- Name: v_archive_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_archive_detail_report AS
 SELECT ds.dataset,
    ds.dataset_id AS id,
    instname.instrument,
    ds.created,
    dasn.archive_state AS state,
    ausn.archive_update_state AS update,
    da.archive_date AS entered,
    da.last_update,
    da.last_verify,
    archivepath.archive_path,
    archivepath.archive_server_name AS archive_server,
    da.instrument_data_purged,
        CASE
            WHEN (da.myemsl_state > 0) THEN public.replace(archivepath.network_share_path, '\\agate.emsl.pnl.gov\dmsarch\'::public.citext, '\\MyEMSL\svc-dms\'::public.citext)
            ELSE (((archivepath.network_share_path)::text || '\'::text) || (COALESCE(ds.folder_name, ds.dataset))::text)
        END AS network_share_path,
        CASE
            WHEN (da.myemsl_state > 0) THEN 'https://my.emsl.pnl.gov/myemsl/search/simple/'::text
            ELSE ((archivepath.archive_url)::text || (COALESCE(ds.folder_name, ds.dataset))::text)
        END AS archive_url
   FROM (((((public.t_dataset_archive da
     JOIN public.t_dataset ds ON ((da.dataset_id = ds.dataset_id)))
     JOIN public.t_dataset_archive_state_name dasn ON ((da.archive_state_id = dasn.archive_state_id)))
     JOIN public.t_archive_path archivepath ON ((da.storage_path_id = archivepath.archive_path_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_dataset_archive_update_state_name ausn ON ((da.archive_update_state_id = ausn.archive_update_state_id)));


ALTER VIEW public.v_archive_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_archive_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_archive_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_archive_detail_report TO writeaccess;

