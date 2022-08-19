--
-- Name: v_experiment_plex_members_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_experiment_plex_members_entry AS
 SELECT pm.plex_exp_id AS exp_id,
    e.experiment,
    public.get_experiment_plex_members_for_entry(pm.plex_exp_id) AS plex_members
   FROM (public.t_experiment_plex_members pm
     JOIN public.t_experiments e ON ((pm.plex_exp_id = e.exp_id)));


ALTER TABLE public.v_experiment_plex_members_entry OWNER TO d3l243;

--
-- Name: TABLE v_experiment_plex_members_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_experiment_plex_members_entry TO readaccess;
GRANT SELECT ON TABLE public.v_experiment_plex_members_entry TO writeaccess;

