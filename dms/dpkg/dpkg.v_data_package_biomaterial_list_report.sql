--
-- Name: v_data_package_biomaterial_list_report; Type: VIEW; Schema: dpkg; Owner: d3l243
--

CREATE VIEW dpkg.v_data_package_biomaterial_list_report AS
 SELECT dpb.data_pkg_id AS id,
    dpb.biomaterial,
    dpb.campaign,
    dpb.type,
    dpb.package_comment,
    b.source_name AS source,
    COALESCE(u_contact.name, b.contact_prn) AS contact,
    b.reason,
    b.created,
    COALESCE(u_pi.name, b.pi_prn) AS pi,
    b.comment,
    mc.container,
    ml.tag AS location,
    b.material_active AS material_status,
    b.biomaterial_id,
    dpb.item_added
   FROM ((((((dpkg.t_data_package_biomaterial dpb
     JOIN public.t_biomaterial b ON ((dpb.biomaterial_id = b.biomaterial_id)))
     JOIN public.t_biomaterial_type_name btn ON ((b.biomaterial_type = btn.biomaterial_type_id)))
     JOIN public.t_material_containers mc ON ((b.container_id = mc.container_id)))
     JOIN public.t_material_locations ml ON ((mc.location_id = ml.location_id)))
     LEFT JOIN public.t_users u_contact ON ((b.contact_prn OPERATOR(public.=) u_contact.username)))
     LEFT JOIN public.t_users u_pi ON ((b.pi_prn OPERATOR(public.=) u_pi.username)));


ALTER TABLE dpkg.v_data_package_biomaterial_list_report OWNER TO d3l243;

--
-- Name: TABLE v_data_package_biomaterial_list_report; Type: ACL; Schema: dpkg; Owner: d3l243
--

GRANT SELECT ON TABLE dpkg.v_data_package_biomaterial_list_report TO readaccess;

