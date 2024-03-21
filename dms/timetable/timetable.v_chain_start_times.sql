--
-- Name: v_chain_start_times; Type: VIEW; Schema: timetable; Owner: d3l243
--

CREATE VIEW timetable.v_chain_start_times AS
 WITH rankq AS (
         SELECT filterq.start_time,
            filterq.chain,
            row_number() OVER (PARTITION BY filterq.chain ORDER BY filterq.start_time) AS start_order
           FROM ( SELECT log.ts AS start_time,
                    ((log.message_data -> 'chain'::text))::integer AS chain
                   FROM timetable.log
                  WHERE (log.message = 'Starting chain'::text)) filterq
        )
 SELECT a.chain,
    a.start_time,
    b.start_time AS next_start_time,
    ((b.start_time - a.start_time))::interval minute AS start_delta,
    c.run_at,
    i.interval_description
   FROM (((rankq a
     JOIN rankq b ON (((a.chain = b.chain) AND (b.start_order = (a.start_order + 1)))))
     JOIN timetable.chain c ON ((a.chain = c.chain_id)))
     LEFT JOIN timetable.t_cron_interval i ON (((c.run_at)::text = (i.cron_interval)::text)));


ALTER VIEW timetable.v_chain_start_times OWNER TO d3l243;

