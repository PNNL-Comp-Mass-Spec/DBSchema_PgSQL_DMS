--
-- Name: v_creation_string_lookup; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_creation_string_lookup AS
 SELECT
        CASE
            WHEN ("values".description IS NULL) THEN ("values".display)::text
            ELSE ((("values".display)::text || ' - '::text) || ("values".description)::text)
        END AS display_value,
    (((keywords.keyword)::text || '='::text) || ("values".value_string)::text) AS string_element,
    keywords.keyword,
    "values".value_string
   FROM (pc.t_creation_option_keywords keywords
     JOIN pc.t_creation_option_values "values" ON ((keywords.keyword_id = "values".keyword_id)));


ALTER TABLE pc.v_creation_string_lookup OWNER TO d3l243;

