--
-- Name: v_secondary_sep_sample_type_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_secondary_sep_sample_type_picklist AS
 SELECT t_secondary_sep_sample_type.sample_type_id AS id,
    t_secondary_sep_sample_type.name
   FROM public.t_secondary_sep_sample_type;


ALTER VIEW public.v_secondary_sep_sample_type_picklist OWNER TO d3l243;

--
-- Name: TABLE v_secondary_sep_sample_type_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_secondary_sep_sample_type_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_secondary_sep_sample_type_picklist TO writeaccess;

