--
-- Name: v_bto_id_to_name; Type: VIEW; Schema: ont; Owner: d3l243
--

CREATE VIEW ont.v_bto_id_to_name AS
 SELECT identifier,
    term_name AS tissue
   FROM ont.t_cv_bto_cached_names;


ALTER VIEW ont.v_bto_id_to_name OWNER TO d3l243;

--
-- Name: TABLE v_bto_id_to_name; Type: ACL; Schema: ont; Owner: d3l243
--

GRANT SELECT ON TABLE ont.v_bto_id_to_name TO readaccess;
GRANT SELECT ON TABLE ont.v_bto_id_to_name TO writeaccess;

