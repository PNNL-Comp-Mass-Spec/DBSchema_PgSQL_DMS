--
-- Name: v_material_locations_active_export_rfid; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_material_locations_active_export_rfid AS
 SELECT ml.location,
    t_material_freezers.freezer,
    t_material_freezers.freezer_tag,
    ml.shelf,
    ml.comment,
    ml.location_id AS id,
    ml.rfid_hex_id AS hex_id
   FROM (public.t_material_locations ml
     JOIN public.t_material_freezers ON ((ml.freezer_tag OPERATOR(public.=) t_material_freezers.freezer_tag)))
  WHERE (ml.status OPERATOR(public.=) 'active'::public.citext);


ALTER TABLE public.v_material_locations_active_export_rfid OWNER TO d3l243;

--
-- Name: TABLE v_material_locations_active_export_rfid; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_material_locations_active_export_rfid TO readaccess;
GRANT SELECT ON TABLE public.v_material_locations_active_export_rfid TO writeaccess;

