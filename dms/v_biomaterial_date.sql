--
-- Name: v_biomaterial_date; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_biomaterial_date AS
 SELECT biomaterial_name,
    EXTRACT(year FROM created) AS year,
    EXTRACT(month FROM created) AS month,
    EXTRACT(day FROM created) AS day
   FROM public.t_biomaterial;


ALTER VIEW public.v_biomaterial_date OWNER TO d3l243;

--
-- Name: TABLE v_biomaterial_date; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_biomaterial_date TO readaccess;
GRANT SELECT ON TABLE public.v_biomaterial_date TO writeaccess;

