--
-- Name: v_creation_string_lookup; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_creation_string_lookup AS
 SELECT
        CASE
            WHEN (v.description IS NULL) THEN (v.display)::text
            ELSE (((v.display)::text || ' - '::text) || (v.description)::text)
        END AS display_value,
    (((k.keyword)::text || '='::text) || (v.value_string)::text) AS string_element,
    k.keyword,
    v.value_string
   FROM (pc.t_creation_option_keywords k
     JOIN pc.t_creation_option_values v ON ((k.keyword_id = v.keyword_id)));


ALTER TABLE pc.v_creation_string_lookup OWNER TO d3l243;

