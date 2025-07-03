--
-- Name: v_separation_group_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_separation_group_list_report AS
SELECT
    NULL::public.citext AS separation_group,
    NULL::public.citext AS comment,
    NULL::smallint AS active,
    NULL::smallint AS sample_prep_visible,
    NULL::smallint AS fraction_count,
    NULL::bigint AS separation_types,
    NULL::integer AS acq_length_minutes;


ALTER VIEW public.v_separation_group_list_report OWNER TO d3l243;

--
-- Name: v_separation_group_list_report _RETURN; Type: RULE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE VIEW public.v_separation_group_list_report AS
 SELECT sg.separation_group,
    sg.comment,
    sg.active,
    sg.sample_prep_visible,
    sg.fraction_count,
    count(ss.separation_type_id) AS separation_types,
    sg.acq_length_minutes
   FROM (public.t_separation_group sg
     LEFT JOIN public.t_secondary_sep ss ON ((sg.separation_group OPERATOR(public.=) ss.separation_group)))
  GROUP BY sg.separation_group, sg.comment, sg.active, sg.sample_prep_visible, sg.fraction_count;

--
-- Name: TABLE v_separation_group_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_separation_group_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_separation_group_list_report TO writeaccess;

