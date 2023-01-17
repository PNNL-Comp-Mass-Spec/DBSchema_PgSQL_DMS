--
-- Name: v_dataset_comments_recent_datasets; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_comments_recent_datasets AS
 SELECT ds.dataset_id,
    ds.dataset,
    ds.comment,
    ds.dataset_state_id AS state_id,
    dsn.dataset_state AS state,
    ds.created,
    round((EXTRACT(day FROM (CURRENT_TIMESTAMP - (ds.created)::timestamp with time zone)) / 7.0), 0) AS age_weeks
   FROM (public.t_dataset ds
     JOIN public.t_dataset_state_name dsn ON ((ds.dataset_state_id = dsn.dataset_state_id)))
  WHERE (ds.created >= (CURRENT_TIMESTAMP - '1 year'::interval));


ALTER TABLE public.v_dataset_comments_recent_datasets OWNER TO d3l243;

--
-- Name: TABLE v_dataset_comments_recent_datasets; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_comments_recent_datasets TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_comments_recent_datasets TO writeaccess;

