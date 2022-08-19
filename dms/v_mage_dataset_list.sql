--
-- Name: v_mage_dataset_list; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_mage_dataset_list AS
 SELECT ds.dataset_id,
    ds.dataset,
    e.experiment,
    c.campaign,
    dsn.dataset_state AS state,
    instname.instrument,
    ds.created,
    dtn.dataset_type AS type,
        CASE
            WHEN (COALESCE((da.instrument_data_purged)::integer, 0) = 0) THEN dfp.dataset_folder_path
            ELSE
            CASE
                WHEN (da.myemsl_state >= 1) THEN dfp.myemsl_path_flag
                ELSE dfp.archive_folder_path
            END
        END AS folder,
    ds.comment,
    org.organism
   FROM ((((((((public.t_dataset ds
     JOIN public.t_dataset_state_name dsn ON ((dsn.dataset_state_id = ds.dataset_state_id)))
     JOIN public.t_dataset_type_name dtn ON ((ds.dataset_type_id = dtn.dataset_type_id)))
     JOIN public.t_instrument_name instname ON ((ds.instrument_id = instname.instrument_id)))
     JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     JOIN public.t_organisms org ON ((e.organism_id = org.organism_id)))
     JOIN public.v_dataset_folder_paths dfp ON ((ds.dataset_id = dfp.dataset_id)))
     LEFT JOIN public.t_dataset_archive da ON ((ds.dataset_id = da.dataset_id)));


ALTER TABLE public.v_mage_dataset_list OWNER TO d3l243;

--
-- Name: TABLE v_mage_dataset_list; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_mage_dataset_list TO readaccess;
GRANT SELECT ON TABLE public.v_mage_dataset_list TO writeaccess;

