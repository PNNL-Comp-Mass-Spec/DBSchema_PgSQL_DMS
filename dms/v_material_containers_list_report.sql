--
-- Name: v_material_containers_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_material_containers_list_report AS
 SELECT containerq.container,
    containerq.type,
    containerq.location,
    containerq.items,
    containerq.filecount AS files,
    containerq.comment,
    containerq.status,
    'New Biomaterial'::text AS action,
    containerq.created,
    public.get_material_container_campaign_list(containerq.container_id, containerq.items) AS campaigns,
    containerq.researcher,
    containerq.container_id AS id
   FROM ( SELECT mc.container,
            mc.type,
            ml.location,
            (count(contentsq.material_id))::integer AS items,
            mc.comment,
            mc.status,
            mc.created,
            mc.container_id,
            mc.researcher,
            tfa.filecount
           FROM (((public.t_material_containers mc
             JOIN public.t_material_locations ml ON ((mc.location_id = ml.location_id)))
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
                    count(*) AS filecount
                   FROM public.t_file_attachment
                  WHERE ((t_file_attachment.entity_type OPERATOR(public.=) 'material_container'::public.citext) AND (t_file_attachment.active > 0))
                  GROUP BY t_file_attachment.entity_id) tfa ON ((tfa.entity_id OPERATOR(public.=) mc.container)))
          GROUP BY mc.container, mc.type, ml.location, mc.comment, mc.created, mc.status, mc.container_id, mc.researcher, tfa.filecount) containerq;


ALTER TABLE public.v_material_containers_list_report OWNER TO d3l243;

--
-- Name: TABLE v_material_containers_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_material_containers_list_report TO readaccess;
GRANT SELECT ON TABLE public.v_material_containers_list_report TO writeaccess;

