--
-- Name: v_experiment_groups_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_experiment_groups_list_report AS
 SELECT eg.group_id AS id,
    eg.group_type,
    eg.tab,
    eg.description,
    eg.member_count AS members,
    ta.attachments AS files,
    e.experiment AS parent_experiment,
    eg.created,
        CASE
            WHEN (eg.researcher IS NULL) THEN ''::public.citext
            ELSE t_users.name_with_username
        END AS researcher
   FROM (((public.t_experiment_groups eg
     JOIN public.t_experiments e ON ((eg.parent_exp_id = e.exp_id)))
     LEFT JOIN ( SELECT (t_file_attachment.entity_id)::integer AS entity_id,
            count(*) AS attachments
           FROM public.t_file_attachment
          WHERE ((t_file_attachment.entity_type OPERATOR(public.=) 'experiment_group'::public.citext) AND (t_file_attachment.active > 0))
          GROUP BY t_file_attachment.entity_id) ta ON ((eg.group_id = ta.entity_id)))
     LEFT JOIN public.t_users ON ((eg.researcher OPERATOR(public.=) t_users.username)));


ALTER TABLE public.v_experiment_groups_list_report OWNER TO d3l243;

--
-- Name: TABLE v_experiment_groups_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_experiment_groups_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_experiment_groups_list_report TO writeaccess;

