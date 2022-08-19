--
-- Name: v_sample_prep_request_experiments_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_sample_prep_request_experiments_list_report AS
 SELECT e.experiment,
    e.researcher_prn AS researcher,
    o.organism,
    e.reason,
    e.comment,
    e.created,
    c.campaign,
    e.sample_prep_request_id AS "#ID"
   FROM ((public.t_experiments e
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     JOIN public.t_organisms o ON ((e.organism_id = o.organism_id)));


ALTER TABLE public.v_sample_prep_request_experiments_list_report OWNER TO d3l243;

--
-- Name: TABLE v_sample_prep_request_experiments_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_sample_prep_request_experiments_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_sample_prep_request_experiments_list_report TO writeaccess;

