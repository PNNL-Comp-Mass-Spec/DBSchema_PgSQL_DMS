--
-- Name: v_experiment_plex_summary_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_experiment_plex_summary_list_report AS
 SELECT plexmembers.plex_exp_id,
    e.experiment AS plex_experiment,
    c.campaign,
    org.organism,
    count(*) AS channels,
    sum(
        CASE
            WHEN (channeltypename.channel_type_name OPERATOR(public.=) 'Reference'::public.citext) THEN 1
            ELSE 0
        END) AS ref_channels,
    e.labelling,
    min(plexmembers.entered) AS created,
    bto.tissue,
    e.sample_prep_request_id AS request,
    e.created AS plex_exp_created
   FROM ((((((public.t_experiment_plex_members plexmembers
     JOIN public.t_experiment_plex_channel_type_name channeltypename ON ((plexmembers.channel_type_id = channeltypename.channel_type_id)))
     JOIN public.t_experiments e ON ((plexmembers.plex_exp_id = e.exp_id)))
     JOIN public.t_organisms org ON ((e.organism_id = org.organism_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     LEFT JOIN ont.v_bto_id_to_name bto ON ((e.tissue_id OPERATOR(public.=) bto.identifier)))
     LEFT JOIN public.t_sample_labelling_reporter_ions reporterions ON (((plexmembers.channel = reporterions.channel) AND (e.labelling OPERATOR(public.=) reporterions.label))))
  GROUP BY plexmembers.plex_exp_id, e.experiment, org.organism, e.labelling, e.created, c.campaign, bto.tissue, e.sample_prep_request_id;


ALTER TABLE public.v_experiment_plex_summary_list_report OWNER TO d3l243;

--
-- Name: TABLE v_experiment_plex_summary_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_experiment_plex_summary_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_experiment_plex_summary_list_report TO writeaccess;

