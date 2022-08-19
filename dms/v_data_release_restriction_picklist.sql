--
-- Name: v_data_release_restriction_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_data_release_restriction_picklist AS
 SELECT t_data_release_restrictions.release_restriction_id AS id,
    t_data_release_restrictions.release_restriction
   FROM public.t_data_release_restrictions;


ALTER TABLE public.v_data_release_restriction_picklist OWNER TO d3l243;

--
-- Name: TABLE v_data_release_restriction_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_data_release_restriction_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_data_release_restriction_picklist TO writeaccess;

