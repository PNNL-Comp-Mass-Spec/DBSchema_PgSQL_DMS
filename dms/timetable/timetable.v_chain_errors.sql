--
-- Name: v_chain_errors; Type: VIEW; Schema: timetable; Owner: d3l243
--

CREATE VIEW timetable.v_chain_errors AS
 SELECT filterq.ts AS entered,
    filterq.log_level,
    filterq.client_name,
    filterq.message,
    filterq.chain_id AS chain,
    filterq.task_id AS task,
    c.chain_name,
    c.run_at,
    t.task_order,
    t.task_name,
    t.kind,
    t.command,
    filterq.message_data,
    jsonb_pretty(filterq.message_data) AS formatted_data
   FROM ((( SELECT l.ts,
            l.log_level,
            l.client_name,
            l.message,
            l.message_data,
            ((l.message_data -> 'chain'::text))::integer AS chain_id,
            ((l.message_data -> 'task'::text))::integer AS task_id
           FROM timetable.log l
          WHERE (l.log_level = ANY (ARRAY['ERROR'::timetable.log_type, 'PANIC'::timetable.log_type]))
        UNION
         SELECT l.ts,
            l.log_level,
            l.client_name,
            (l.message || ' (error caught by exception handler)'::text),
            l.message_data,
            ((l.message_data -> 'chain'::text))::integer AS chain_id,
            ((l.message_data -> 'task'::text))::integer AS task_id
           FROM timetable.log l
          WHERE ((l.message ~~* 'Notice%'::text) AND ((l.message_data ->> 'notice'::text) ~~* '%Error caught%'::text))) filterq
     LEFT JOIN timetable.chain c ON ((filterq.chain_id = c.chain_id)))
     LEFT JOIN timetable.task t ON ((filterq.task_id = t.task_id)));


ALTER VIEW timetable.v_chain_errors OWNER TO d3l243;

