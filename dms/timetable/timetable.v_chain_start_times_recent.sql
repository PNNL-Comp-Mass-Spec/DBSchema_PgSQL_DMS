--
-- Name: v_chain_start_times_recent; Type: VIEW; Schema: timetable; Owner: d3l243
--

CREATE VIEW timetable.v_chain_start_times_recent AS
 SELECT leadq.chain_id,
    leadq.start_time,
    leadq.next_start_time,
    ((leadq.next_start_time - leadq.start_time))::interval minute AS start_delta,
    c.run_at,
    i.interval_description
   FROM ((( SELECT filterq.start_time,
            filterq.chain_id,
            lead(filterq.start_time, 1) OVER (PARTITION BY filterq.chain_id ORDER BY filterq.start_time) AS next_start_time
           FROM ( SELECT log.ts AS start_time,
                    ((log.message_data -> 'chain'::text))::integer AS chain_id
                   FROM timetable.log
                  WHERE (log.message = 'Starting chain'::text)) filterq) leadq
     JOIN timetable.chain c ON ((leadq.chain_id = c.chain_id)))
     LEFT JOIN timetable.t_cron_interval i ON (((c.run_at)::text = (i.cron_interval)::text)));


ALTER VIEW timetable.v_chain_start_times_recent OWNER TO d3l243;

--
-- Name: TABLE v_chain_start_times_recent; Type: ACL; Schema: timetable; Owner: d3l243
--

GRANT SELECT ON TABLE timetable.v_chain_start_times_recent TO writeaccess;
GRANT INSERT,DELETE,TRUNCATE,UPDATE ON TABLE timetable.v_chain_start_times_recent TO pgdms;

