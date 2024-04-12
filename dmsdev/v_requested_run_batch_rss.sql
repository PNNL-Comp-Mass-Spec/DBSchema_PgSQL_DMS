--
-- Name: v_requested_run_batch_rss; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_requested_run_batch_rss AS
 SELECT filterq.id AS url_title,
    (((filterq.id)::text || ' - '::text) || (filterq.batch)::text) AS post_title,
    filterq.post_date,
    (((filterq.id)::text || '_'::text) || (filterq.datasets)::text) AS guid,
    ((((((u.name)::text || '|'::text) || (filterq.description)::text) || '|'::text) || (filterq.datasets)::text) || ' datasets'::text) AS post_body,
    u.username
   FROM (( SELECT rrb.batch_id AS id,
            rrb.batch,
            max(ds.created) AS post_date,
            count(ds.dataset_id) AS datasets,
            rrb.description,
            rrb.owner_user_id AS owner
           FROM ((public.t_dataset ds
             JOIN public.t_requested_run rr ON ((ds.dataset_id = rr.dataset_id)))
             JOIN public.t_requested_run_batches rrb ON ((rr.batch_id = rrb.batch_id)))
          WHERE (rrb.batch_id <> 0)
          GROUP BY rrb.batch_id, rrb.batch, rrb.description, rrb.owner_user_id
         HAVING (max(ds.created) > (CURRENT_TIMESTAMP - '30 days'::interval))) filterq
     LEFT JOIN public.t_users u ON ((filterq.owner = u.user_id)));


ALTER VIEW public.v_requested_run_batch_rss OWNER TO d3l243;

--
-- Name: TABLE v_requested_run_batch_rss; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_requested_run_batch_rss TO readaccess;
GRANT SELECT ON TABLE public.v_requested_run_batch_rss TO writeaccess;

