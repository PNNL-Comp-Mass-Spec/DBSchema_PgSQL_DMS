--
-- Name: v_data_analysis_request_queue_times; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_data_analysis_request_queue_times AS
 SELECT outerq.request_id,
    outerq.created,
    outerq.state,
    outerq.closed,
        CASE
            WHEN (outerq.state = 0) THEN NULL::numeric
            WHEN (outerq.state = 4) THEN round((EXTRACT(epoch FROM (outerq.closed - outerq.created)) / (86400)::numeric))
            ELSE round((EXTRACT(epoch FROM (COALESCE((outerq.closed)::timestamp with time zone, CURRENT_TIMESTAMP) - (outerq.created)::timestamp with time zone)) / (86400)::numeric))
        END AS days_in_queue,
    round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (outerq.statefirstentered)::timestamp with time zone)) / (86400)::numeric)) AS days_in_state
   FROM ( SELECT r.request_id,
            r.created,
            r.state,
            closedq.closed,
            stateenteredq.statefirstentered
           FROM ((public.t_data_analysis_request r
             LEFT JOIN ( SELECT t_data_analysis_request_updates.request_id,
                    t_data_analysis_request_updates.new_state_id,
                    max(t_data_analysis_request_updates.entered) AS closed
                   FROM public.t_data_analysis_request_updates
                  WHERE ((t_data_analysis_request_updates.new_state_id = 4) AND (t_data_analysis_request_updates.old_state_id <> 4))
                  GROUP BY t_data_analysis_request_updates.request_id, t_data_analysis_request_updates.new_state_id) closedq ON ((closedq.request_id = r.request_id)))
             LEFT JOIN ( SELECT t_data_analysis_request_updates.request_id,
                    t_data_analysis_request_updates.new_state_id AS state_id,
                    min(t_data_analysis_request_updates.entered) AS statefirstentered
                   FROM public.t_data_analysis_request_updates
                  GROUP BY t_data_analysis_request_updates.request_id, t_data_analysis_request_updates.new_state_id) stateenteredq ON (((stateenteredq.request_id = r.request_id) AND (stateenteredq.state_id = r.state))))) outerq;


ALTER TABLE public.v_data_analysis_request_queue_times OWNER TO d3l243;

--
-- Name: TABLE v_data_analysis_request_queue_times; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_data_analysis_request_queue_times TO readaccess;
GRANT SELECT ON TABLE public.v_data_analysis_request_queue_times TO writeaccess;

