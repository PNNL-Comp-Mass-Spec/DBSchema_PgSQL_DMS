--
-- Name: v_eus_site_status_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_eus_site_status_picklist AS
 SELECT t_eus_site_status.eus_site_status_id AS id,
    t_eus_site_status.eus_site_status AS name,
    (((t_eus_site_status.eus_site_status_id || ' - '::text) || (t_eus_site_status.eus_site_status)::text))::public.citext AS id_with_name
   FROM public.t_eus_site_status;


ALTER VIEW public.v_eus_site_status_picklist OWNER TO d3l243;

--
-- Name: TABLE v_eus_site_status_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_eus_site_status_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_eus_site_status_picklist TO writeaccess;

