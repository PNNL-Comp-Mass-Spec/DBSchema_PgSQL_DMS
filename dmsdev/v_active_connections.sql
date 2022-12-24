--
-- Name: v_active_connections; Type: VIEW; Schema: public; Owner: d3l243
--

CREATE VIEW public.v_active_connections AS
 SELECT pg_stat_activity.client_addr AS host_ip,
    pg_stat_activity.client_hostname AS host,
    pg_stat_activity.client_port AS port,
    pg_stat_activity.application_name AS application,
    pg_stat_activity.usename AS user_name,
    pg_stat_activity.datname AS db_name,
    pg_stat_activity.pid,
    pg_stat_activity.backend_start,
    pg_stat_activity.query_start,
    pg_stat_activity.state,
    pg_stat_activity.wait_event,
    pg_stat_activity.query
   FROM pg_stat_activity;


ALTER TABLE public.v_active_connections OWNER TO d3l243;

