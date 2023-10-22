--
-- Name: v_creation_string_lookup; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_creation_string_lookup AS
 SELECT
        CASE
            WHEN (v.description IS NULL) THEN v.display
            ELSE ((((((v.display)::text || (' - '::public.citext)::text))::public.citext)::text || (v.description)::text))::public.citext
        END AS display_value,
    ((((((k.keyword)::text || ('='::public.citext)::text))::public.citext)::text || (v.value_string)::text))::public.citext AS string_element,
    k.keyword,
    v.value_string
   FROM (pc.t_creation_option_keywords k
     JOIN pc.t_creation_option_values v ON ((k.keyword_id = v.keyword_id)));


ALTER TABLE pc.v_creation_string_lookup OWNER TO d3l243;

--
-- Name: TABLE v_creation_string_lookup; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.v_creation_string_lookup TO readaccess;
GRANT SELECT ON TABLE pc.v_creation_string_lookup TO writeaccess;

