--
-- Name: v_emsl_allocated_usage_by_category; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_emsl_allocated_usage_by_category AS
 SELECT instcategory.category,
    installocation.fy,
    installocation.proposal_id,
    sum(installocation.allocated_hours) AS total_allocated_hours
   FROM (public.t_emsl_instrument_allocation installocation
     JOIN ( SELECT emslinst.eus_instrument_id,
                CASE
                    WHEN (emslinst.local_category_name IS NULL) THEN emslinst.eus_display_name
                    ELSE emslinst.local_category_name
                END AS category
           FROM public.t_emsl_instruments emslinst) instcategory ON ((instcategory.eus_instrument_id = installocation.eus_instrument_id)))
  GROUP BY instcategory.category, installocation.proposal_id, installocation.fy;


ALTER TABLE public.v_emsl_allocated_usage_by_category OWNER TO d3l243;

--
-- Name: TABLE v_emsl_allocated_usage_by_category; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_emsl_allocated_usage_by_category TO readaccess;
GRANT SELECT ON TABLE public.v_emsl_allocated_usage_by_category TO writeaccess;

