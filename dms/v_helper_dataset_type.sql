--
-- Name: v_helper_dataset_type; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_helper_dataset_type AS
 SELECT d.dataset_type,
    d.description,
    t_yes_no.description AS active
   FROM (public.t_dataset_type_name d
     JOIN public.t_yes_no ON ((d.active = t_yes_no.flag)));


ALTER VIEW public.v_helper_dataset_type OWNER TO d3l243;

--
-- Name: TABLE v_helper_dataset_type; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_helper_dataset_type TO readaccess;
GRANT SELECT ON TABLE public.v_helper_dataset_type TO writeaccess;

