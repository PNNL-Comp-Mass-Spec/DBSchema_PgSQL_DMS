--
-- Name: v_instrument_tracked; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_tracked AS
 SELECT filterq.name,
    filterq.reporting,
    filterq.description,
    filterq.ops_role,
    filterq.emsl_primary,
    filterq."group",
    filterq.class,
    filterq.eus_instrument_name,
    filterq.eus_instrument_id,
    filterq.eus_available_hours,
    filterq.eus_active_sw,
    filterq.eus_primary_instrument,
    filterq.percent_emsl_owned,
    filterq.tracked,
    ((((filterq.name)::text || ' ('::text) || filterq.reporting) || ')'::text) AS name_with_reporting
   FROM ( SELECT td.instrument AS name,
            ((
                CASE
                    WHEN (upper((ti.eus_primary_instrument)::text) = ANY (ARRAY['Y'::text, '1'::text])) THEN 'E'::text
                    ELSE ''::text
                END ||
                CASE
                    WHEN (td.operations_role OPERATOR(public.=) 'Production'::public.citext) THEN 'P'::text
                    ELSE ''::text
                END) ||
                CASE
                    WHEN (td.tracking = 1) THEN 'T'::text
                    ELSE ''::text
                END) AS reporting,
            td.description,
            td.operations_role AS ops_role,
            ti.eus_primary_instrument AS emsl_primary,
            td.instrument_group AS "group",
            td.instrument_class AS class,
            ti.eus_instrument_name,
            ti.eus_instrument_id,
            ti.eus_available_hours,
            ti.eus_active_sw,
            ti.eus_primary_instrument,
            td.percent_emsl_owned,
            td.tracking AS tracked
           FROM ((public.t_emsl_instruments ti
             JOIN public.t_emsl_dms_instrument_mapping tm ON ((ti.eus_instrument_id = tm.eus_instrument_id)))
             RIGHT JOIN public.t_instrument_name td ON ((tm.dms_instrument_id = td.instrument_id)))
          WHERE (((td.status OPERATOR(public.=) 'active'::public.citext) AND (td.operations_role OPERATOR(public.=) 'Production'::public.citext)) OR (td.tracking = 1) OR ((upper((ti.eus_primary_instrument)::text) = ANY (ARRAY['Y'::text, '1'::text])) AND (ti.eus_active_sw OPERATOR(public.=) 'Y'::public.citext)))) filterq;


ALTER TABLE public.v_instrument_tracked OWNER TO d3l243;

--
-- Name: TABLE v_instrument_tracked; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_tracked TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_tracked TO writeaccess;

