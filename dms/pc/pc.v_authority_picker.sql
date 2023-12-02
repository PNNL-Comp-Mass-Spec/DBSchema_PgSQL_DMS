--
-- Name: v_authority_picker; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_authority_picker AS
 SELECT auth.authority_id AS id,
    auth.name AS display_name,
    (((((((((auth.description)::text || (' <'::public.citext)::text))::public.citext)::text || (auth.web_address)::text))::public.citext)::text || ('>'::public.citext)::text))::public.citext AS details
   FROM pc.t_naming_authorities auth;


ALTER VIEW pc.v_authority_picker OWNER TO d3l243;

--
-- Name: TABLE v_authority_picker; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.v_authority_picker TO readaccess;
GRANT SELECT ON TABLE pc.v_authority_picker TO writeaccess;

