--
-- Name: v_chain_start_times; Type: VIEW; Schema: timetable; Owner: d3l243
--

CREATE VIEW timetable.v_chain_start_times AS
 SELECT leadq.chain,
    leadq.start_time,
    leadq.next_start_time,
    ((leadq.next_start_time - leadq.start_time))::interval minute AS start_delta,
    c.run_at,
    i.interval_description
   FROM ((( SELECT filterq.start_time,
            filterq.chain,
            lead(filterq.start_time, 1) OVER (PARTITION BY filterq.chain ORDER BY filterq.start_time) AS next_start_time
           FROM ( SELECT log.ts AS start_time,
                    ((log.message_data -> 'chain'::text))::integer AS chain
                   FROM timetable.log
                  WHERE (log.message = 'Starting chain'::text)) filterq) leadq
     JOIN timetable.chain c ON ((leadq.chain = c.chain_id)))
     LEFT JOIN timetable.t_cron_interval i ON (((c.run_at)::text = (i.cron_interval)::text)));


ALTER VIEW timetable.v_chain_start_times OWNER TO d3l243;

