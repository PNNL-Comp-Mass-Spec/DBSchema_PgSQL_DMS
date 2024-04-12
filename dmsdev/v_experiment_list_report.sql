--
-- Name: v_experiment_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_experiment_list_report AS
 SELECT e.experiment,
    u.name_with_username AS researcher,
    org.organism,
    e.reason,
    e.comment,
    e.sample_concentration AS concentration,
    e.created,
    c.campaign,
    cec.biomaterial_list,
    cec.reference_compound_list AS ref_compounds,
    e.exp_id AS id
   FROM ((((public.t_experiments e
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     JOIN public.t_organisms org ON ((e.organism_id = org.organism_id)))
     JOIN public.t_users u ON ((e.researcher_username OPERATOR(public.=) u.username)))
     LEFT JOIN public.t_cached_experiment_components cec ON ((e.exp_id = cec.exp_id)));


ALTER VIEW public.v_experiment_list_report OWNER TO d3l243;

--
-- Name: TABLE v_experiment_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_experiment_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_experiment_list_report TO writeaccess;

