--
-- Name: v_biomaterial_count_by_month; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_biomaterial_count_by_month AS
 SELECT v_biomaterial_date.year,
    v_biomaterial_date.month,
    count(v_biomaterial_date.biomaterial_name) AS number_of_items_created,
    (((v_biomaterial_date.month)::text || '/'::text) || (v_biomaterial_date.year)::text) AS date
   FROM public.v_biomaterial_date
  GROUP BY v_biomaterial_date.year, v_biomaterial_date.month;


ALTER VIEW public.v_biomaterial_count_by_month OWNER TO d3l243;

--
-- Name: TABLE v_biomaterial_count_by_month; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_biomaterial_count_by_month TO readaccess;
GRANT SELECT ON TABLE public.v_biomaterial_count_by_month TO writeaccess;

