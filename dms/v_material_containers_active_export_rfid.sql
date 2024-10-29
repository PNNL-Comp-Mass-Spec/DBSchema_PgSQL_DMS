--
-- Name: v_material_containers_active_export_rfid; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_material_containers_active_export_rfid AS
 SELECT mc.container,
    mc.comment,
        CASE
            WHEN ((c.campaign IS NULL) OR (c.campaign OPERATOR(public.=) 'Not_Set'::public.citext)) THEN ''::public.citext
            ELSE c.campaign
        END AS campaign,
    mc.created,
    mc.researcher,
    mc.container_id AS id,
    mc.rfid_hex_id AS hex_id
   FROM (public.t_material_containers mc
     LEFT JOIN public.t_campaign c ON ((mc.campaign_id = c.campaign_id)))
  WHERE (mc.status OPERATOR(public.=) 'Active'::public.citext);


ALTER VIEW public.v_material_containers_active_export_rfid OWNER TO d3l243;

--
-- Name: TABLE v_material_containers_active_export_rfid; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_material_containers_active_export_rfid TO readaccess;
GRANT SELECT ON TABLE public.v_material_containers_active_export_rfid TO writeaccess;

