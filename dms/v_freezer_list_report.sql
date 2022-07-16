--
-- Name: v_freezer_list_report; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_freezer_list_report AS
 SELECT f.freezer_id,
    f.freezer,
    f.freezer_tag,
    f.comment,
    count(mc.container_id) AS containers
   FROM ((public.t_material_containers mc
     JOIN public.t_material_locations ml ON ((mc.location_id = ml.location_id)))
     RIGHT JOIN public.t_material_freezers f ON (((ml.freezer_tag OPERATOR(public.=) f.freezer_tag) AND (ml.status OPERATOR(public.<>) 'Inactive'::public.citext) AND (mc.status OPERATOR(public.<>) 'Inactive'::public.citext))))
  GROUP BY f.freezer_id, f.freezer, f.freezer_tag, f.comment, ml.status;


ALTER TABLE public.v_freezer_list_report OWNER TO d3l243;

--
-- Name: TABLE v_freezer_list_report; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_freezer_list_report TO readaccess;

