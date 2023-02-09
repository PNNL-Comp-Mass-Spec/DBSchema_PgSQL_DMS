--
-- Name: v_experiment_group_members_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_experiment_group_members_list_report AS
 SELECT e.experiment,
    e.exp_id AS id,
        CASE
            WHEN (eg.parent_exp_id = e.exp_id) THEN 'Parent'::text
            ELSE 'Child'::text
        END AS member,
    e.researcher_username AS researcher,
    org.organism,
    e.reason,
    e.comment,
    count(DISTINCT ds.dataset_id) AS datasets,
    eg.group_id
   FROM (((((public.t_experiments e
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     JOIN public.t_experiment_group_members egm ON ((e.exp_id = egm.exp_id)))
     JOIN public.t_organisms org ON ((e.organism_id = org.organism_id)))
     LEFT JOIN public.t_experiment_groups eg ON ((egm.group_id = eg.group_id)))
     LEFT JOIN public.t_dataset ds ON ((egm.exp_id = ds.exp_id)))
  GROUP BY e.experiment, e.exp_id, eg.parent_exp_id, e.researcher_username, org.organism, e.reason, e.comment, eg.group_id;


ALTER TABLE public.v_experiment_group_members_list_report OWNER TO d3l243;

--
-- Name: TABLE v_experiment_group_members_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_experiment_group_members_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_experiment_group_members_list_report TO writeaccess;

