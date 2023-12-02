--
-- Name: v_mgr_type_list_by_param; Type: VIEW; Schema: mc; Owner: d3l243
--

CREATE VIEW mc.v_mgr_type_list_by_param AS
 SELECT groupq.param_name,
    (string_agg((groupq.mgr_type_name)::text, (', '::public.citext)::text ORDER BY (groupq.mgr_type_name)::text))::public.citext AS mgr_type_list
   FROM ( SELECT DISTINCT pt.param_name,
            lookupq.mgr_type_name
           FROM (((mc.t_mgr_type_param_type_map mp
             JOIN mc.t_mgr_types mt ON ((mp.mgr_type_id = mt.mgr_type_id)))
             JOIN mc.t_param_type pt ON ((mp.param_type_id = pt.param_type_id)))
             JOIN ( SELECT DISTINCT pt2.param_name,
                    mt2.mgr_type_name
                   FROM ((mc.t_mgr_type_param_type_map mtpm
                     JOIN mc.t_mgr_types mt2 ON ((mtpm.mgr_type_id = mt2.mgr_type_id)))
                     JOIN mc.t_param_type pt2 ON ((mtpm.param_type_id = pt2.param_type_id)))) lookupq ON ((pt.param_name OPERATOR(public.=) lookupq.param_name)))) groupq
  GROUP BY groupq.param_name;


ALTER VIEW mc.v_mgr_type_list_by_param OWNER TO d3l243;

--
-- Name: TABLE v_mgr_type_list_by_param; Type: ACL; Schema: mc; Owner: d3l243
--

GRANT SELECT ON TABLE mc.v_mgr_type_list_by_param TO readaccess;
GRANT SELECT ON TABLE mc.v_mgr_type_list_by_param TO writeaccess;

