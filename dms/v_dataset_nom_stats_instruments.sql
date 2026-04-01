--
-- Name: v_dataset_nom_stats_instruments; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_dataset_nom_stats_instruments AS
 SELECT instrument,
    instrument_id
   FROM public.t_dataset_nom_stats_instruments;


ALTER VIEW public.v_dataset_nom_stats_instruments OWNER TO d3l243;

--
-- Name: TABLE v_dataset_nom_stats_instruments; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_dataset_nom_stats_instruments TO readaccess;
GRANT SELECT ON TABLE public.v_dataset_nom_stats_instruments TO writeaccess;

