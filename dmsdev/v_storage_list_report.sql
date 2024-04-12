--
-- Name: v_storage_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_storage_list_report AS
 SELECT spath.storage_path_id AS id,
    spath.storage_path,
    spath.vol_name_client AS vol_client,
    spath.vol_name_server AS vol_server,
    spath.storage_path_function,
    spath.instrument,
    count(ds.dataset_id) AS datasets,
    spath.description,
    spath.created
   FROM (public.t_storage_path spath
     LEFT JOIN public.t_dataset ds ON ((spath.storage_path_id = ds.storage_path_id)))
  GROUP BY spath.storage_path_id, spath.storage_path, spath.vol_name_client, spath.vol_name_server, spath.storage_path_function, spath.instrument, spath.description, spath.created;


ALTER VIEW public.v_storage_list_report OWNER TO d3l243;

--
-- Name: TABLE v_storage_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_storage_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_storage_list_report TO writeaccess;

