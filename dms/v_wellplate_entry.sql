--
-- Name: v_wellplate_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_wellplate_entry AS
 SELECT t_wellplates.wellplate_id AS id,
    t_wellplates.wellplate,
    t_wellplates.description,
    t_wellplates.created
   FROM public.t_wellplates;


ALTER VIEW public.v_wellplate_entry OWNER TO d3l243;

--
-- Name: TABLE v_wellplate_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_wellplate_entry TO readaccess;
GRANT SELECT ON TABLE public.v_wellplate_entry TO writeaccess;

