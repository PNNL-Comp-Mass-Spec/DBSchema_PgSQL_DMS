--
-- Name: v_sample_labelling_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_sample_labelling_picklist AS
 SELECT label_id AS id,
    label
   FROM public.t_sample_labelling;


ALTER VIEW public.v_sample_labelling_picklist OWNER TO d3l243;

--
-- Name: TABLE v_sample_labelling_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_sample_labelling_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_sample_labelling_picklist TO writeaccess;

