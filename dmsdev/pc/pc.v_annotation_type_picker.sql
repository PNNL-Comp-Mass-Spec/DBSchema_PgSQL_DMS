--
-- Name: v_annotation_type_picker; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_annotation_type_picker AS
 SELECT antypes.annotation_type_id AS id,
    ((((((auth.name)::text || (' - '::public.citext)::text))::public.citext)::text || (antypes.type_name)::text))::public.citext AS display_name,
    COALESCE((((((((((auth.description)::text || (' <'::public.citext)::text))::public.citext)::text || (auth.web_address)::text))::public.citext)::text || ('>'::public.citext)::text))::public.citext, '---'::public.citext) AS details,
    antypes.authority_id
   FROM (pc.t_naming_authorities auth
     JOIN pc.t_annotation_types antypes ON ((auth.authority_id = antypes.authority_id)));


ALTER VIEW pc.v_annotation_type_picker OWNER TO d3l243;

--
-- Name: TABLE v_annotation_type_picker; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.v_annotation_type_picker TO readaccess;
GRANT SELECT ON TABLE pc.v_annotation_type_picker TO writeaccess;

