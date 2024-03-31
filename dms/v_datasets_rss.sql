--
-- Name: v_datasets_rss; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_datasets_rss AS
 SELECT dataset AS url_title,
    (((id)::text || ' - '::text) || (dataset)::text) AS post_title,
    (id)::text AS guid,
    (((((((((' Dataset:'::text || (dataset)::text) || '| Experiment:'::text) || (experiment)::text) || '| Researcher:'::text) || (researcher)::text) || '| Experiment Group:'::text) || (exp_group)::text) || ', Experiment Group ID:'::text) || (group_id)::text) AS post_body,
    researcher AS username,
    created AS post_date
   FROM ( SELECT ds.dataset_id AS id,
            ds.dataset,
            e.experiment,
            e.researcher_username AS researcher,
            t_experiment_groups.description AS exp_group,
            t_experiment_groups.group_id,
            ds.created
           FROM (((public.t_dataset ds
             JOIN public.t_experiments e ON ((ds.exp_id = e.exp_id)))
             JOIN public.t_experiment_group_members ON ((e.exp_id = t_experiment_group_members.exp_id)))
             JOIN public.t_experiment_groups ON ((t_experiment_group_members.group_id = t_experiment_groups.group_id)))
          WHERE (ds.created > (CURRENT_TIMESTAMP - '30 days'::interval))) filterq;


ALTER VIEW public.v_datasets_rss OWNER TO d3l243;

--
-- Name: TABLE v_datasets_rss; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_datasets_rss TO readaccess;
GRANT SELECT ON TABLE public.v_datasets_rss TO writeaccess;

