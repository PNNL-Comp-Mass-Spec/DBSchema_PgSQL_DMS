--
-- Name: trig_db_sql_drop; Type: EVENT TRIGGER; Schema: -; Owner: d3l243
--

CREATE EVENT TRIGGER trig_db_sql_drop ON sql_drop
   EXECUTE FUNCTION public.log_ddl_sql_drop();


ALTER EVENT TRIGGER trig_db_sql_drop OWNER TO d3l243;

