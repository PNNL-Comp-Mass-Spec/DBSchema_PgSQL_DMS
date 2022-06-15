--
-- Name: v_dataset_folder_paths_ex; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_folder_paths_ex AS
 SELECT dfp.dataset,
    dfp.dataset_id,
    dfp.dataset_folder_path,
    dfp.archive_folder_path,
    dfp.dataset_url,
    dfp.instrument_data_purged,
    instname.instrument,
    ds.created AS dataset_created,
    (((EXTRACT(year FROM ds.created))::text || '_'::text) || (EXTRACT(quarter FROM ds.created))::text) AS dataset_year_quarter
   FROM ((public.t_dataset ds
     JOIN public.v_dataset_folder_paths dfp ON ((ds.dataset_id = dfp.dataset_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)));


ALTER TABLE public.v_dataset_folder_paths_ex OWNER TO d3l243;

--
-- Name: TABLE v_dataset_folder_paths_ex; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_folder_paths_ex TO readaccess;

