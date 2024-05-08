--
-- Name: v_experiment_plex_members_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_experiment_plex_members_detail_report AS
 SELECT plexmembers.plex_exp_id AS exp_id,
    e.experiment,
    u.name_with_username AS researcher,
    org.organism,
    e.reason AS reason_for_experiment,
    e.comment,
    c.campaign,
    bto.tissue AS plant_or_animal_tissue,
    e.labelling,
    min(plexmembers.entered) AS created,
    e.alkylation AS alkylated,
    e.sample_prep_request_id AS request,
    e.created AS plex_exp_created,
    bto.identifier AS tissue_id,
    public.get_experiment_plex_members(plexmembers.plex_exp_id) AS plex_members,
    COALESCE((ces.dataset_count)::bigint, (0)::bigint) AS datasets,
    ces.most_recent_dataset,
    COALESCE((ces.factor_count)::bigint, (0)::bigint) AS factors,
    e.exp_id AS id,
    mc.container,
    ml.location,
    e.material_active AS material_status,
    e.last_used,
    e.barcode
   FROM (((((((((public.t_experiment_plex_members plexmembers
     JOIN public.t_experiments e ON ((plexmembers.plex_exp_id = e.exp_id)))
     JOIN public.t_experiments channelexperiment ON ((plexmembers.exp_id = channelexperiment.exp_id)))
     JOIN public.t_organisms org ON ((e.organism_id = org.organism_id)))
     JOIN public.t_campaign c ON ((e.campaign_id = c.campaign_id)))
     JOIN public.t_users u ON ((e.researcher_username OPERATOR(public.=) u.username)))
     LEFT JOIN ont.v_bto_id_to_name bto ON ((e.tissue_id OPERATOR(public.=) bto.identifier)))
     JOIN public.t_material_containers mc ON ((e.container_id = mc.container_id)))
     JOIN public.t_material_locations ml ON ((mc.location_id = ml.location_id)))
     LEFT JOIN public.t_cached_experiment_stats ces ON ((ces.exp_id = e.exp_id)))
  GROUP BY plexmembers.plex_exp_id, e.experiment, u.name_with_username, org.organism, e.reason, e.comment, e.created, c.campaign, bto.tissue, e.labelling, e.alkylation, e.sample_prep_request_id, bto.identifier, ces.dataset_count, ces.most_recent_dataset, ces.factor_count, e.exp_id, mc.container, ml.location, e.material_active, e.last_used, e.barcode;


ALTER VIEW public.v_experiment_plex_members_detail_report OWNER TO d3l243;

--
-- Name: TABLE v_experiment_plex_members_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_experiment_plex_members_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_experiment_plex_members_detail_report TO writeaccess;

