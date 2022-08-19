--
-- Name: v_experiment_file_attachment_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_experiment_file_attachment_list_report AS
 SELECT e.exp_id,
    fa.id,
    fa.file_name,
    COALESCE(fa.description, ''::public.citext) AS description,
    fa.entity_type,
    fa.entity_id,
    fa.owner,
    fa.size_kb,
    fa.created,
    fa.last_affected,
    e.experiment
   FROM (public.v_file_attachment_list_report fa
     JOIN public.t_experiments e ON ((fa.entity_id OPERATOR(public.=) e.experiment)))
  WHERE (fa.entity_type OPERATOR(public.=) 'experiment'::public.citext)
UNION
 SELECT egm.exp_id,
    lookupq.attachment_id AS id,
    lookupq.file_name,
    lookupq.description,
    lookupq.entity_type,
    lookupq.entity_id,
    lookupq.owner,
    lookupq.size_kb,
    lookupq.created,
    lookupq.last_affected,
    e.experiment
   FROM ((( SELECT v_file_attachment_list_report.id AS attachment_id,
            v_file_attachment_list_report.file_name,
            v_file_attachment_list_report.description,
            v_file_attachment_list_report.entity_type,
            v_file_attachment_list_report.entity_id,
            v_file_attachment_list_report.owner,
            v_file_attachment_list_report.size_kb,
            v_file_attachment_list_report.created,
            v_file_attachment_list_report.last_affected
           FROM public.v_file_attachment_list_report
          WHERE (v_file_attachment_list_report.entity_type OPERATOR(public.=) 'experiment_group'::public.citext)) lookupq
     JOIN public.t_experiment_group_members egm ON (((lookupq.entity_id)::integer = egm.group_id)))
     JOIN public.t_experiments e ON ((egm.exp_id = e.exp_id)));


ALTER TABLE public.v_experiment_file_attachment_list_report OWNER TO d3l243;

--
-- Name: TABLE v_experiment_file_attachment_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_experiment_file_attachment_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_experiment_file_attachment_list_report TO writeaccess;

