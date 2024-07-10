--
-- Name: v_material_containers_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_material_containers_detail_report AS
 SELECT mc.container,
    mc.type,
    ml.location,
    public.get_material_container_item_count(mc.container_id) AS items,
    mc.comment,
    ml.freezer_tag AS freezer,
    c.campaign,
    mc.created,
    mc.container_id AS id,
    mc.status,
    mc.researcher,
    tfa.files
   FROM (((public.t_material_containers mc
     JOIN public.t_material_locations ml ON ((mc.location_id = ml.location_id)))
     LEFT JOIN public.t_campaign c ON ((mc.campaign_id = c.campaign_id)))
     LEFT JOIN ( SELECT fa.entity_id,
            count(fa.attachment_id) AS files
           FROM public.t_file_attachment fa
          WHERE ((fa.entity_type OPERATOR(public.=) 'material_container'::public.citext) AND (fa.active > 0) AND (NOT (fa.entity_id OPERATOR(public.=) ANY (ARRAY['na'::public.citext, 'Staging'::public.citext, 'Met_Staging'::public.citext, '-80_Staging'::public.citext]))))
          GROUP BY fa.entity_id) tfa ON ((tfa.entity_id OPERATOR(public.=) mc.container)));


ALTER VIEW public.v_material_containers_detail_report OWNER TO d3l243;

--
-- Name: VIEW v_material_containers_detail_report; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_material_containers_detail_report IS 'Exclude the staging containers because they have thousands of items, leading to slow query times on the Material Container Detail Report when this query looks for a file attachment associated with every container in the staging location';

--
-- Name: TABLE v_material_containers_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_material_containers_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_material_containers_detail_report TO writeaccess;

