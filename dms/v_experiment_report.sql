--
-- Name: v_experiment_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_experiment_report AS
 SELECT t_experiments.experiment,
    t_experiments.researcher_username AS researcher,
    t_organisms.organism,
    t_experiments.comment,
    t_experiments.created,
    t_campaign.campaign,
    t_experiments.exp_id AS id
   FROM ((public.t_experiments
     JOIN public.t_campaign ON ((t_experiments.campaign_id = t_campaign.campaign_id)))
     JOIN public.t_organisms ON ((t_experiments.organism_id = t_organisms.organism_id)));


ALTER VIEW public.v_experiment_report OWNER TO d3l243;

--
-- Name: VIEW v_experiment_report; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_experiment_report IS 'This view is used by the spreadsheet loader (see column existence_check_sql in table loadable_entities in spreadsheet_loader.db';

--
-- Name: TABLE v_experiment_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_experiment_report TO readaccess;
GRANT SELECT ON TABLE public.v_experiment_report TO writeaccess;

