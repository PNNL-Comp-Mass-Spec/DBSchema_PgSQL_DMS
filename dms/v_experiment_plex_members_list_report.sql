--
-- Name: v_experiment_plex_members_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_experiment_plex_members_list_report AS
 SELECT plexmembers.plex_exp_id,
    e.experiment AS plex_experiment,
    org.organism,
    plexmembers.channel,
    reporterions.tag_name AS tag,
    plexmembers.exp_id,
    channelexperiment.experiment AS channel_experiment,
    channeltypename.channel_type_name AS channel_type,
    plexmembers.comment,
    e.created,
    c.campaign,
    bto.term_name AS tissue,
    e.labelling,
    reporterions.masic_name
   FROM (((((((public.t_experiment_plex_members plexmembers
     JOIN public.t_experiment_plex_channel_type_name channeltypename ON ((plexmembers.channel_type_id = channeltypename.channel_type_id)))
     JOIN public.t_experiments e ON ((plexmembers.plex_exp_id = e.exp_id)))
     JOIN public.t_experiments channelexperiment ON ((plexmembers.exp_id = channelexperiment.exp_id)))
     JOIN public.t_organisms org ON ((e.organism_id = org.organism_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     LEFT JOIN ont.t_cv_bto_cached_names bto ON ((e.tissue_id OPERATOR(public.=) bto.identifier)))
     LEFT JOIN public.t_sample_labelling_reporter_ions reporterions ON (((plexmembers.channel = reporterions.channel) AND (e.labelling OPERATOR(public.=) reporterions.label))));


ALTER VIEW public.v_experiment_plex_members_list_report OWNER TO d3l243;

--
-- Name: TABLE v_experiment_plex_members_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_experiment_plex_members_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_experiment_plex_members_list_report TO writeaccess;

