--
-- Name: v_data_package_experiment_plex_members_list_report; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_experiment_plex_members_list_report AS
 SELECT dpe.data_pkg_id AS id,
    dpe.experiment,
    plexmembers.plex_exp_id,
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
    reporterions.masic_name,
    dpe.item_added
   FROM ((((((((dpkg.t_data_package_experiments dpe
     JOIN public.t_experiment_plex_members plexmembers ON ((plexmembers.plex_exp_id = dpe.experiment_id)))
     JOIN public.t_experiment_plex_channel_type_name channeltypename ON ((plexmembers.channel_type_id = channeltypename.channel_type_id)))
     JOIN public.t_experiments e ON ((plexmembers.plex_exp_id = e.exp_id)))
     JOIN public.t_experiments channelexperiment ON ((plexmembers.exp_id = channelexperiment.exp_id)))
     JOIN public.t_organisms org ON ((e.organism_id = org.organism_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     LEFT JOIN ont.t_cv_bto_cached_names bto ON ((e.tissue_id OPERATOR(public.=) bto.identifier)))
     LEFT JOIN public.t_sample_labelling_reporter_ions reporterions ON (((plexmembers.channel = reporterions.channel) AND (e.labelling OPERATOR(public.=) reporterions.label))));


ALTER TABLE dpkg.v_data_package_experiment_plex_members_list_report OWNER TO d3l243;

--
-- Name: TABLE v_data_package_experiment_plex_members_list_report; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_data_package_experiment_plex_members_list_report TO readaccess;

