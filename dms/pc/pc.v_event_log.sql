--
-- Name: v_event_log; Type: VIEW; Schema: pc; Owner: d3l243
--

CREATE VIEW pc.v_event_log AS
 SELECT el.event_id,
    el.target_type,
        CASE el.target_type
            WHEN 1 THEN 'Protein Collection'::text
            ELSE NULL::text
        END AS target,
    el.target_id,
    el.target_state,
        CASE
            WHEN (el.target_type = 1) THEN
            CASE
                WHEN ((el.target_state = 0) AND (el.prev_target_state > 0)) THEN 'Deleted'::text
                ELSE (pcs.state)::text
            END
            ELSE NULL::text
        END AS state_name,
    el.prev_target_state,
    el.entered,
    el.entered_by
   FROM (pc.t_event_log el
     LEFT JOIN pc.t_protein_collection_states pcs ON (((el.target_state = pcs.collection_state_id) AND (el.target_type = 1))));


ALTER TABLE pc.v_event_log OWNER TO d3l243;

--
-- Name: TABLE v_event_log; Type: ACL; Schema: pc; Owner: d3l243
--

GRANT SELECT ON TABLE pc.v_event_log TO readaccess;
GRANT SELECT ON TABLE pc.v_event_log TO writeaccess;

