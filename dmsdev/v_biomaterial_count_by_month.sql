--
-- Name: v_biomaterial_count_by_month; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_biomaterial_count_by_month AS
 SELECT year,
    month,
    count(biomaterial_name) AS number_of_items_created,
    (((month)::text || '/'::text) || (year)::text) AS date
   FROM public.v_biomaterial_date
  GROUP BY year, month;


ALTER VIEW public.v_biomaterial_count_by_month OWNER TO d3l243;

--
-- Name: TABLE v_biomaterial_count_by_month; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_biomaterial_count_by_month TO readaccess;
GRANT SELECT ON TABLE public.v_biomaterial_count_by_month TO writeaccess;

