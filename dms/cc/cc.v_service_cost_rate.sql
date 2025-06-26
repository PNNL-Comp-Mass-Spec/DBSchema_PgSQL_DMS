--
-- Name: v_service_cost_rate; Type: VIEW; Schema: cc; Owner: d3l243
--

CREATE VIEW cc.v_service_cost_rate AS
 SELECT cr.cost_group_id,
    costgroup.description,
    servicetype.service_type,
    cr.adjustment,
    cr.base_rate_per_hour_adj,
    cr.overhead_hours_per_run,
    cr.base_rate_per_run,
    cr.labor_rate_per_hour,
    cr.labor_hours_per_run,
    cr.labor_rate_per_run,
    (cr.base_rate_per_run + cr.labor_rate_per_run) AS total_rate_per_run,
    cr.service_type_id
   FROM ((cc.t_service_cost_rate cr
     JOIN cc.t_service_type servicetype ON ((servicetype.service_type_id = cr.service_type_id)))
     JOIN cc.t_service_cost_group costgroup ON ((costgroup.cost_group_id = cr.cost_group_id)));


ALTER VIEW cc.v_service_cost_rate OWNER TO d3l243;

