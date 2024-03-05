--
-- Name: v_emsl_actual_usage_by_category; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_emsl_actual_usage_by_category AS
 SELECT (public.get_fiscal_year_text_from_date(filterq.run_date))::public.citext AS fy,
    filterq.proposal_id,
    filterq.category,
    (sum(filterq.duration) / (60)::numeric) AS actual_hours_used
   FROM ( SELECT rr.eus_proposal_id AS proposal_id,
            ds.instrument_id,
            COALESCE(ds.acq_time_end, ds.created) AS run_date,
            instcategory.category,
            COALESCE((EXTRACT(epoch FROM (ds.acq_time_end - ds.acq_time_start)) / (60)::numeric), (0)::numeric) AS duration
           FROM ((public.t_requested_run rr
             JOIN public.t_dataset ds ON ((rr.dataset_id = ds.dataset_id)))
             JOIN ( SELECT instmap.dms_instrument_id,
                        CASE
                            WHEN (emslinst.local_category_name IS NULL) THEN emslinst.eus_display_name
                            ELSE emslinst.local_category_name
                        END AS category
                   FROM (public.t_emsl_dms_instrument_mapping instmap
                     JOIN public.t_emsl_instruments emslinst ON ((instmap.eus_instrument_id = emslinst.eus_instrument_id)))) instcategory ON ((instcategory.dms_instrument_id = ds.instrument_id)))
          WHERE ((rr.eus_proposal_id IS NOT NULL) AND (ds.dataset_state_id = 3))) filterq
  GROUP BY (public.get_fiscal_year_text_from_date(filterq.run_date)), filterq.proposal_id, filterq.category;


ALTER VIEW public.v_emsl_actual_usage_by_category OWNER TO d3l243;

--
-- Name: TABLE v_emsl_actual_usage_by_category; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_emsl_actual_usage_by_category TO readaccess;
GRANT SELECT ON TABLE public.v_emsl_actual_usage_by_category TO writeaccess;

