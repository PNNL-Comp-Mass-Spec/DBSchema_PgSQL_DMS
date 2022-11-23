--
-- Name: v_material_containers_detail_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_material_containers_detail_report AS
 SELECT containerq.container,
    containerq.type,
    containerq.location,
    containerq.items,
    containerq.comment,
    containerq.freezer,
    public.get_material_container_campaign_list(containerq.container_id, containerq.items) AS campaigns,
    containerq.barcode,
    containerq.created,
    containerq.status,
    containerq.researcher,
    containerq.files
   FROM ( SELECT mc.container,
            mc.type,
            ml.location,
            (count(contentsq.material_id))::integer AS items,
            mc.comment,
            ml.freezer_tag AS freezer,
            mc.barcode,
            mc.created,
            mc.status,
            mc.researcher,
            tfa.files,
            mc.container_id
           FROM (((public.t_material_containers mc
             LEFT JOIN ( SELECT t_biomaterial.container_id,
                    t_biomaterial.biomaterial_id AS material_id
                   FROM public.t_biomaterial
                  WHERE (t_biomaterial.material_active OPERATOR(public.=) 'Active'::public.citext)
                UNION
                 SELECT t_experiments.container_id,
                    t_experiments.exp_id AS material_id
                   FROM public.t_experiments
                  WHERE (t_experiments.material_active OPERATOR(public.=) 'Active'::public.citext)
                UNION
                 SELECT t_reference_compound.container_id,
                    t_reference_compound.compound_id AS material_id
                   FROM public.t_reference_compound
                  WHERE (t_reference_compound.active > 0)) contentsq ON ((contentsq.container_id = mc.container_id)))
             LEFT JOIN ( SELECT t_file_attachment.entity_id,
                    count(*) AS files
                   FROM public.t_file_attachment
                  WHERE ((t_file_attachment.entity_type OPERATOR(public.=) 'material_container'::public.citext) AND (t_file_attachment.active > 0) AND (t_file_attachment.entity_id OPERATOR(public.<>) ALL (ARRAY['na'::public.citext, 'Staging'::public.citext, 'Met_Staging'::public.citext, '-80_Staging'::public.citext])))
                  GROUP BY t_file_attachment.entity_id) tfa ON ((tfa.entity_id OPERATOR(public.=) mc.container)))
             JOIN public.t_material_locations ml ON ((mc.location_id = ml.location_id)))
          GROUP BY mc.container, mc.type, ml.location, mc.comment, mc.barcode, mc.created, mc.status, mc.researcher, ml.freezer_tag, tfa.files, mc.container_id) containerq;


ALTER TABLE public.v_material_containers_detail_report OWNER TO d3l243;

--
-- Name: VIEW v_material_containers_detail_report; Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON VIEW public.v_material_containers_detail_report IS 'Exclude the staging containers because they have thousands of items, leading to slow query times on the Material Container Detail Report when this query looks for a file attachment associated with every container in the staging location';

--
-- Name: TABLE v_material_containers_detail_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_material_containers_detail_report TO readaccess;
GRANT SELECT ON TABLE public.v_material_containers_detail_report TO writeaccess;

