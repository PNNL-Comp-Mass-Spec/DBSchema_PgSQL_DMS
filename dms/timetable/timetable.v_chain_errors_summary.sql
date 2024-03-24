--
-- Name: v_chain_errors_summary; Type: VIEW; Schema: timetable; Owner: d3l243
--

CREATE VIEW timetable.v_chain_errors_summary AS
 SELECT v_chain_errors.chain,
    v_chain_errors.task,
    v_chain_errors.chain_name,
    v_chain_errors.task_name,
    v_chain_errors.message,
    v_chain_errors.command,
    count(*) AS entries,
    min(v_chain_errors.entered) AS entered_min,
    max(v_chain_errors.entered) AS entered_max
   FROM timetable.v_chain_errors
  GROUP BY v_chain_errors.chain, v_chain_errors.task, v_chain_errors.chain_name, v_chain_errors.task_name, v_chain_errors.message, v_chain_errors.command;


ALTER VIEW timetable.v_chain_errors_summary OWNER TO d3l243;

