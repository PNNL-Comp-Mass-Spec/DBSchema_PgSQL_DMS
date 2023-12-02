--
-- Name: v_lcmsnet_experiment_export; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_lcmsnet_experiment_export AS
 SELECT e.exp_id AS id,
    e.experiment,
    u.name_with_username AS researcher,
    org.organism,
    e.reason,
    e.comment,
    e.created,
    e.sample_prep_request_id AS request,
    e.last_used
   FROM ((public.t_experiments e
     JOIN public.t_users u ON ((e.researcher_username OPERATOR(public.=) u.username)))
     JOIN public.t_organisms org ON ((e.organism_id = org.organism_id)));


ALTER VIEW public.v_lcmsnet_experiment_export OWNER TO d3l243;

--
-- Name: TABLE v_lcmsnet_experiment_export; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_lcmsnet_experiment_export TO readaccess;
GRANT SELECT ON TABLE public.v_lcmsnet_experiment_export TO writeaccess;

