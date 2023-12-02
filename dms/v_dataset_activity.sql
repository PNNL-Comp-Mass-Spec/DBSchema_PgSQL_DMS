--
-- Name: v_dataset_activity; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_activity AS
 SELECT ds.dataset,
    ds.created AS dataset_created,
    instrument.instrument,
    dsn.dataset_state AS state,
    ds.last_affected AS state_date
   FROM ((public.t_dataset ds
     JOIN public.t_dataset_state_name dsn ON ((ds.dataset_state_id = dsn.dataset_state_id)))
     JOIN public.t_instrument_name instrument ON ((ds.instrument_id = instrument.instrument_id)))
  WHERE ((ds.last_affected >= (CURRENT_TIMESTAMP - '14 days'::interval)) AND (ds.dataset_state_id = ANY (ARRAY[2, 5, 7, 8, 12])))
UNION
 SELECT ds.dataset,
    ds.created AS dataset_created,
    t_instrument_name.instrument,
    (((dasn.archive_state)::text || (' (archive)'::public.citext)::text))::public.citext AS state,
    da.archive_state_last_affected AS state_date
   FROM ((((public.t_dataset_archive da
     JOIN public.t_dataset_archive_state_name dasn ON ((da.archive_state_id = dasn.archive_state_id)))
     JOIN public.t_dataset_archive_update_state_name ausn ON ((da.archive_update_state_id = ausn.archive_update_state_id)))
     JOIN public.t_dataset ds ON ((da.dataset_id = ds.dataset_id)))
     JOIN public.t_instrument_name ON ((ds.instrument_id = t_instrument_name.instrument_id)))
  WHERE ((da.archive_state_last_affected >= (CURRENT_TIMESTAMP - '14 days'::interval)) AND (da.archive_state_id = ANY (ARRAY[2, 6, 8, 13])))
UNION
 SELECT ds.dataset,
    ds.created AS dataset_created,
    t_instrument_name.instrument,
    (((ausn.archive_update_state)::text || (' (archive update)'::public.citext)::text))::public.citext AS state,
    da.archive_update_state_last_affected AS state_date
   FROM ((((public.t_dataset_archive da
     JOIN public.t_dataset_archive_state_name dasn ON ((da.archive_state_id = dasn.archive_state_id)))
     JOIN public.t_dataset_archive_update_state_name ausn ON ((da.archive_update_state_id = ausn.archive_update_state_id)))
     JOIN public.t_dataset ds ON ((da.dataset_id = ds.dataset_id)))
     JOIN public.t_instrument_name ON ((ds.instrument_id = t_instrument_name.instrument_id)))
  WHERE ((da.archive_update_state_last_affected >= (CURRENT_TIMESTAMP - '14 days'::interval)) AND (da.archive_update_state_id = ANY (ARRAY[3, 5])));


ALTER VIEW public.v_dataset_activity OWNER TO d3l243;

--
-- Name: TABLE v_dataset_activity; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_activity TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_activity TO writeaccess;

