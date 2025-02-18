--
-- Name: v_instrument_tracked; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_tracked AS
 SELECT name,
    reporting,
    description,
    ops_role,
    emsl_primary,
    "group",
    class,
    eus_instrument_name,
    eus_instrument_id,
    eus_available_hours,
    eus_active_sw,
    eus_primary_instrument,
    percent_emsl_owned,
    tracked,
    (((((((((name)::text || (' ('::public.citext)::text))::public.citext)::text || (reporting)::text))::public.citext)::text || (')'::public.citext)::text))::public.citext AS name_with_reporting
   FROM ( SELECT instname.instrument AS name,
            (((
                CASE
                    WHEN (upper((ti.eus_primary_instrument)::text) = ANY (ARRAY['Y'::text, '1'::text])) THEN 'E'::text
                    ELSE ''::text
                END ||
                CASE
                    WHEN (instname.operations_role OPERATOR(public.=) 'Production'::public.citext) THEN 'P'::text
                    ELSE ''::text
                END) ||
                CASE
                    WHEN (instname.tracking = 1) THEN 'T'::text
                    ELSE ''::text
                END))::public.citext AS reporting,
            instname.description,
            instname.operations_role AS ops_role,
            ti.eus_primary_instrument AS emsl_primary,
            instname.instrument_group AS "group",
            instname.instrument_class AS class,
            ti.eus_instrument_name,
            ti.eus_instrument_id,
            ti.eus_available_hours,
            ti.eus_active_sw,
            ti.eus_primary_instrument,
            instname.percent_emsl_owned,
            instname.tracking AS tracked
           FROM ((public.t_emsl_instruments ti
             JOIN public.t_emsl_dms_instrument_mapping instmap ON ((ti.eus_instrument_id = instmap.eus_instrument_id)))
             RIGHT JOIN public.t_instrument_name instname ON ((instmap.dms_instrument_id = instname.instrument_id)))
          WHERE (((instname.status OPERATOR(public.=) 'active'::public.citext) AND (instname.operations_role OPERATOR(public.=) 'Production'::public.citext)) OR (instname.tracking = 1) OR ((upper((ti.eus_primary_instrument)::text) = ANY (ARRAY['Y'::text, '1'::text])) AND (ti.eus_active_sw OPERATOR(public.=) 'Y'::public.citext)))) filterq;


ALTER VIEW public.v_instrument_tracked OWNER TO d3l243;

--
-- Name: TABLE v_instrument_tracked; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_tracked TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_tracked TO writeaccess;

