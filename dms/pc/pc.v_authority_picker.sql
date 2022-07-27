--
-- Name: v_authority_picker; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_authority_picker AS
 SELECT auth.authority_id AS id,
    auth.name AS display_name,
    ((((auth.description)::text || ' <'::text) || (auth.web_address)::text) || '>'::text) AS details
   FROM pc.t_naming_authorities auth;


ALTER TABLE pc.v_authority_picker OWNER TO d3l243;

