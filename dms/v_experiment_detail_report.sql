--
-- Name: v_experiment_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_experiment_detail_report AS
 SELECT e.experiment,
    e.researcher_username AS researcher,
    org.organism,
    e.reason,
    e.comment,
    e.created,
    e.sample_concentration,
    e.lab_notebook_ref AS lab_notebook,
    c.campaign,
    e.labelling
   FROM ((public.t_experiments e
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     JOIN public.t_organisms org ON ((e.organism_id = org.organism_id)));


ALTER TABLE public.v_experiment_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_experiment_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_experiment_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_experiment_detail_report TO writeaccess;

