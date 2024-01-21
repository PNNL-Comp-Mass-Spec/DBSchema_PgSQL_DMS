--
-- Name: v_instrument_group_picklist; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_instrument_group_picklist AS
 SELECT lookupq.instrument_group,
    lookupq.usage,
    lookupq.instruments,
    lookupq.comment,
    lookupq.allowed_dataset_types,
    lookupq.sample_prep_visible,
    lookupq.requested_run_visible,
        CASE
            WHEN (lookupq.instruments OPERATOR(public.=) ''::public.citext) THEN (((lookupq.instrument_group)::text || (' (no active instruments)'::public.citext)::text))::public.citext
            ELSE (((((((lookupq.instrument_group)::text || (' ('::public.citext)::text))::public.citext)::text || (lookupq.instruments)::text) || (')'::public.citext)::text))::public.citext
        END AS instrument_group_and_instruments
   FROM ( SELECT g.instrument_group,
            g.usage,
            (public.get_instrument_group_membership_list((g.instrument_group)::text, 1, 64))::public.citext AS instruments,
            g.comment,
            (public.get_instrument_group_dataset_type_list((g.instrument_group)::text, ', '::text))::public.citext AS allowed_dataset_types,
            g.sample_prep_visible,
            g.requested_run_visible
           FROM (public.t_instrument_group g
             LEFT JOIN public.t_dataset_type_name dt ON ((g.default_dataset_type = dt.dataset_type_id)))
          WHERE (g.active > 0)) lookupq;


ALTER VIEW public.v_instrument_group_picklist OWNER TO d3l243;

--
-- Name: TABLE v_instrument_group_picklist; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_instrument_group_picklist TO readaccess;
GRANT SELECT ON TABLE public.v_instrument_group_picklist TO writeaccess;

