--
-- Name: v_sample_prep_request_queue_times; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_sample_prep_request_queue_times AS
 SELECT outerq.request_id,
    outerq.created,
    outerq.state_id,
    outerq.complete_or_closed,
        CASE
            WHEN (outerq.state_id = 0) THEN NULL::numeric
            WHEN (outerq.state_id = ANY (ARRAY[4, 5])) THEN round((EXTRACT(epoch FROM (outerq.complete_or_closed - outerq.created)) / (86400)::numeric))
            ELSE round((EXTRACT(epoch FROM (COALESCE((outerq.complete_or_closed)::timestamp with time zone, CURRENT_TIMESTAMP) - (outerq.created)::timestamp with time zone)) / (86400)::numeric))
        END AS days_in_queue,
        CASE
            WHEN (outerq.state_id = 5) THEN NULL::numeric
            ELSE round((EXTRACT(epoch FROM (CURRENT_TIMESTAMP - (outerq.statefirstentered)::timestamp with time zone)) / (86400)::numeric))
        END AS days_in_state
   FROM ( SELECT spr.prep_request_id AS request_id,
            spr.created,
            spr.state_id,
                CASE
                    WHEN (prepcompleteq.prepcomplete IS NULL) THEN closedq.closed
                    WHEN (closedq.closed IS NULL) THEN prepcompleteq.prepcomplete
                    WHEN (prepcompleteq.prepcomplete < closedq.closed) THEN prepcompleteq.prepcomplete
                    ELSE closedq.closed
                END AS complete_or_closed,
            prepcompleteq.prepcomplete,
            closedq.closed,
            stateenteredq.statefirstentered
           FROM (((public.t_sample_prep_request spr
             LEFT JOIN ( SELECT t_sample_prep_request_updates.request_id,
                    max(t_sample_prep_request_updates.date_of_change) AS prepcomplete
                   FROM public.t_sample_prep_request_updates
                  WHERE ((t_sample_prep_request_updates.end_state_id = 4) AND (t_sample_prep_request_updates.beginning_state_id <> 4))
                  GROUP BY t_sample_prep_request_updates.request_id) prepcompleteq ON ((prepcompleteq.request_id = spr.prep_request_id)))
             LEFT JOIN ( SELECT t_sample_prep_request_updates.request_id,
                    max(t_sample_prep_request_updates.date_of_change) AS closed
                   FROM public.t_sample_prep_request_updates
                  WHERE ((t_sample_prep_request_updates.end_state_id = 5) AND (t_sample_prep_request_updates.beginning_state_id <> 5))
                  GROUP BY t_sample_prep_request_updates.request_id) closedq ON ((closedq.request_id = spr.prep_request_id)))
             LEFT JOIN ( SELECT t_sample_prep_request_updates.request_id,
                    t_sample_prep_request_updates.end_state_id AS state_id,
                    min(t_sample_prep_request_updates.date_of_change) AS statefirstentered
                   FROM public.t_sample_prep_request_updates
                  GROUP BY t_sample_prep_request_updates.request_id, t_sample_prep_request_updates.end_state_id) stateenteredq ON (((stateenteredq.request_id = spr.prep_request_id) AND (stateenteredq.state_id = spr.state_id))))) outerq;


ALTER TABLE public.v_sample_prep_request_queue_times OWNER TO d3l243;

--
-- Name: TABLE v_sample_prep_request_queue_times; Type: ACL; Schema: public; Owner: d3l243
--

GRANT SELECT ON TABLE public.v_sample_prep_request_queue_times TO readaccess;

