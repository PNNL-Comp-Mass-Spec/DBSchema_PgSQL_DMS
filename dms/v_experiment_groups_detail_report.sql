--
-- Name: v_experiment_groups_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_experiment_groups_detail_report AS
 SELECT eg.group_id AS id,
    eg.group_type,
    eg.group_name,
    e.experiment AS parent_experiment,
    count(egm.exp_id) AS members,
    eg.description,
    eg.created,
    eg.prep_lc_run_id AS prep_lc_run,
        CASE
            WHEN (eg.researcher_username IS NULL) THEN ''::public.citext
            ELSE u.name_with_username
        END AS researcher,
    count(DISTINCT ds.dataset_id) AS datasets,
    COALESCE(fa.filecount, (0)::bigint) AS experiment_group_files
   FROM (((((public.t_experiment_groups eg
     LEFT JOIN public.t_experiment_group_members egm ON ((eg.group_id = egm.group_id)))
     JOIN public.t_experiments e ON ((eg.parent_exp_id = e.exp_id)))
     LEFT JOIN public.t_dataset ds ON ((egm.exp_id = ds.exp_id)))
     LEFT JOIN public.t_users u ON ((eg.researcher_username OPERATOR(public.=) u.username)))
     LEFT JOIN ( SELECT t_file_attachment.entity_id,
            count(*) AS filecount
           FROM public.t_file_attachment
          WHERE ((t_file_attachment.entity_type OPERATOR(public.=) 'experiment_group'::public.citext) AND (t_file_attachment.active > 0))
          GROUP BY t_file_attachment.entity_id) fa ON ((eg.group_id = (fa.entity_id)::integer)))
  GROUP BY eg.group_id, eg.group_type, eg.group_name, eg.description, eg.created, e.experiment, eg.prep_lc_run_id, fa.filecount,
        CASE
            WHEN (eg.researcher_username IS NULL) THEN ''::public.citext
            ELSE u.name_with_username
        END;


ALTER TABLE public.v_experiment_groups_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_experiment_groups_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_experiment_groups_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_experiment_groups_detail_report TO writeaccess;

