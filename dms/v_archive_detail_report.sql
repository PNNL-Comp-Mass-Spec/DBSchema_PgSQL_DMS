--
-- Name: v_archive_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_archive_detail_report AS
 SELECT ds.dataset,
    ds.dataset_id AS id,
    tin.instrument,
    ds.created,
    dasn.archive_state AS state,
    aus.archive_update_state AS update,
    da.archive_date AS entered,
    da.last_update,
    da.last_verify,
    tap.archive_path,
    tap.archive_server_name AS archive_server,
    da.instrument_data_purged,
        CASE
            WHEN (da.myemsl_state > 0) THEN public.replace(tap.network_share_path, '\\adms.emsl.pnl.gov\dmsarch\'::public.citext, '\\MyEMSL\svc-dms\'::public.citext)
            ELSE (((tap.network_share_path)::text || '\'::text) || (COALESCE(ds.folder_name, ds.dataset))::text)
        END AS network_share_path,
        CASE
            WHEN (da.myemsl_state > 0) THEN 'https://my.emsl.pnl.gov/myemsl/search/simple/'::text
            ELSE ((tap.archive_url)::text || (COALESCE(ds.folder_name, ds.dataset))::text)
        END AS archive_url
   FROM (((((public.t_dataset_archive da
     JOIN public.t_dataset ds ON ((da.dataset_id = ds.dataset_id)))
     JOIN public.t_dataset_archive_state_name dasn ON ((da.archive_state_id = dasn.archive_state_id)))
     JOIN public.t_archive_path tap ON ((da.storage_path_id = tap.archive_path_id)))
     JOIN public.t_instrument_name tin ON ((ds.instrument_id = tin.instrument_id)))
     JOIN public.t_archive_update_state_name aus ON ((da.archive_update_state_id = aus.archive_update_state_id)));


ALTER TABLE public.v_archive_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_archive_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_archive_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_archive_detail_report TO writeaccess;

