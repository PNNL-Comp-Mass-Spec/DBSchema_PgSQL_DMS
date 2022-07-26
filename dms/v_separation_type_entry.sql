--
-- Name: v_separation_type_entry; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_separation_type_entry AS
 SELECT ss.separation_type_id AS id,
    ss.separation_type AS separation_name,
    ss.separation_group,
    ss.comment,
    st.name AS sample_type,
        CASE
            WHEN (ss.active = 1) THEN 'Active'::text
            ELSE 'Inactive'::text
        END AS state
   FROM (public.t_secondary_sep ss
     LEFT JOIN public.t_secondary_sep_sample_type st ON ((ss.sample_type_id = st.sample_type_id)));


ALTER TABLE public.v_separation_type_entry OWNER TO d3l243;

--
-- Name: TABLE v_separation_type_entry; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_separation_type_entry TO readaccess;

