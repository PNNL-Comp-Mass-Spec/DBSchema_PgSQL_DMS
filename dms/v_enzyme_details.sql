--
-- Name: v_enzyme_details; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_enzyme_details AS
 SELECT t_enzymes.enzyme_name,
    NULLIF(t_enzymes.p1, 'na'::public.citext) AS left_cleave_point,
    NULLIF(t_enzymes.p1_exception, 'na'::public.citext) AS left_no_cleave_point,
    NULLIF(t_enzymes.p2, 'na'::public.citext) AS right_cleave_point,
    NULLIF(t_enzymes.p2_exception, 'na'::public.citext) AS right_no_cleave_point,
    NULLIF(t_enzymes.cleavage_method, 'na'::public.citext) AS cleavage_method,
    t_enzymes.cleavage_offset AS "offset",
    t_enzymes.sequest_enzyme_index AS selected_enzyme_index
   FROM public.t_enzymes;


ALTER TABLE public.v_enzyme_details OWNER TO d3l243;

--
-- Name: TABLE v_enzyme_details; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_enzyme_details TO readaccess;
GRANT SELECT ON TABLE public.v_enzyme_details TO writeaccess;

