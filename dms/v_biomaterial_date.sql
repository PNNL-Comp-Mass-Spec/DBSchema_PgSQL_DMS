--
-- Name: v_biomaterial_date; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_biomaterial_date AS
 SELECT t_biomaterial.biomaterial_name,
    EXTRACT(year FROM t_biomaterial.created) AS year,
    EXTRACT(month FROM t_biomaterial.created) AS month,
    EXTRACT(day FROM t_biomaterial.created) AS day
   FROM public.t_biomaterial;


ALTER TABLE public.v_biomaterial_date OWNER TO d3l243;

--
-- Name: TABLE v_biomaterial_date; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_biomaterial_date TO readaccess;

