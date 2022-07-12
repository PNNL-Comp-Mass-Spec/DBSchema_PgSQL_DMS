--
-- Name: v_datasets_rss; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_datasets_rss AS
 SELECT filterq.dataset AS url_title,
    (((filterq.id)::text || ' - '::text) || (filterq.dataset)::text) AS post_title,
    (filterq.id)::text AS guid,
    (((((((((' Dataset:'::text || (filterq.dataset)::text) || '| Experiment:'::text) || (filterq.experiment)::text) || '| Researcher:'::text) || (filterq.researcher)::text) || '| Experiment Group:'::text) || (filterq.exp_group)::text) || ', Experiment Group ID:'::text) || (filterq.group_id)::text) AS post_body,
    filterq.researcher AS u_prn,
    filterq.created AS post_date
   FROM ( SELECT ds.dataset_id AS id,
            ds.dataset,
            e.experiment,
            e.researcher_prn AS researcher,
            t_experiment_groups.description AS exp_group,
            t_experiment_groups.group_id,
            ds.created
           FROM (((public.t_dataset ds
             JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
             JOIN public.t_experiment_group_members ON ((e.exp_id = t_experiment_group_members.exp_id)))
             JOIN public.t_experiment_groups ON ((t_experiment_group_members.group_id = t_experiment_groups.group_id)))
          WHERE (ds.created > (CURRENT_TIMESTAMP - '30 days'::interval))) filterq;


ALTER TABLE public.v_datasets_rss OWNER TO d3l243;

--
-- Name: TABLE v_datasets_rss; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_datasets_rss TO readaccess;

