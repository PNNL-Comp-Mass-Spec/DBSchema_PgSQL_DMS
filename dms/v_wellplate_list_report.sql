--
-- Name: v_wellplate_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_wellplate_list_report AS
 SELECT t_wellplates.wellplate_id AS id,
    t_wellplates.wellplate AS wellplate_name,
    t_wellplates.description,
    t_wellplates.created
   FROM public.t_wellplates;


ALTER VIEW public.v_wellplate_list_report OWNER TO d3l243;

--
-- Name: TABLE v_wellplate_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_wellplate_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_wellplate_list_report TO writeaccess;

