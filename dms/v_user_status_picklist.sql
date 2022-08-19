--
-- Name: v_user_status_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_user_status_picklist AS
 SELECT t_user_status.status,
    t_user_status.status_description AS description
   FROM public.t_user_status;


ALTER TABLE public.v_user_status_picklist OWNER TO d3l243;

--
-- Name: TABLE v_user_status_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_user_status_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_user_status_picklist TO writeaccess;

