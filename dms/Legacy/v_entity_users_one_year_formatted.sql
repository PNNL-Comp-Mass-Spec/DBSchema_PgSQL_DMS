CREATE OR REPLACE VIEW v_entity_users_one_year
AS
SELECT 'Analysis job owner' AS entity,
       owner_username AS username,
       COUNT(*) AS items
FROM t_analysis_job
WHERE created BETWEEN CURRENT_TIMESTAMP - Interval '12 months' AND CURRENT_TIMESTAMP
GROUP BY owner_username
UNION
SELECT 'Analysis job request user' AS entity,
       U.username,
       COUNT(*) AS items
FROM t_analysis_job_request AJR
     INNER JOIN t_users U
       ON AJR.user_id = U.user_id
WHERE AJR.created BETWEEN CURRENT_TIMESTAMP - Interval '12 months' AND CURRENT_TIMESTAMP
GROUP BY U.username
UNION
SELECT 'Biomaterial contact' AS entity,
       contact_username AS username,
       COUNT(*) AS items
FROM t_biomaterial
WHERE created BETWEEN CURRENT_TIMESTAMP - Interval '12 months' AND CURRENT_TIMESTAMP
GROUP BY contact_username
UNION
SELECT 'Dataset operator' AS entity,
       operator_username AS username,
       COUNT(*) AS items
FROM t_dataset
WHERE created BETWEEN CURRENT_TIMESTAMP - Interval '12 months' AND CURRENT_TIMESTAMP
GROUP BY operator_username
UNION
SELECT 'Experiment group researcher' AS entity,
       researcher_username AS username,
       COUNT(*) AS items
FROM t_experiment_groups
WHERE created BETWEEN CURRENT_TIMESTAMP - Interval '12 months' AND CURRENT_TIMESTAMP
GROUP BY researcher_username
UNION
SELECT 'Experiment researcher' AS entity,
       researcher_username AS username,
       COUNT(*) AS items
FROM t_experiments
WHERE created BETWEEN CURRENT_TIMESTAMP - Interval '12 months' AND CURRENT_TIMESTAMP
GROUP BY researcher_username
UNION
SELECT 'Cart config entered' AS entity,
       entered_by AS username,
       COUNT(*) AS items
FROM t_lc_cart_configuration
WHERE entered BETWEEN CURRENT_TIMESTAMP - Interval '12 months' AND CURRENT_TIMESTAMP
GROUP BY entered_by
UNION
SELECT 'Cart config updated' AS entity,
       updated_by AS username,
       COUNT(*) AS items
FROM t_lc_cart_configuration
WHERE entered BETWEEN CURRENT_TIMESTAMP - Interval '12 months' AND CURRENT_TIMESTAMP
GROUP BY updated_by
UNION
SELECT 'LC column operator' AS entity,
       operator_username AS username,
       COUNT(*) AS items
FROM t_lc_column
WHERE created BETWEEN CURRENT_TIMESTAMP - Interval '12 months' AND CURRENT_TIMESTAMP
GROUP BY operator_username
UNION
SELECT 'Reference compount contact' AS entity,
       contact_username AS username,
       COUNT(*) AS items
FROM t_reference_compound
WHERE created BETWEEN CURRENT_TIMESTAMP - Interval '12 months' AND CURRENT_TIMESTAMP
GROUP BY contact_username
UNION
SELECT 'Requested run requester' AS entity,
       requester_username AS username,
       COUNT(*) AS items
FROM t_requested_run
WHERE created BETWEEN CURRENT_TIMESTAMP - Interval '12 months' AND CURRENT_TIMESTAMP
GROUP BY requester_username
UNION
SELECT 'Requested run updater' AS entity,
       Replace(updated_by, 'PNL\', '')::citext AS username,
       COUNT(*) AS items
FROM t_requested_run
WHERE created BETWEEN CURRENT_TIMESTAMP - Interval '12 months' AND CURRENT_TIMESTAMP
GROUP BY 2
UNION
SELECT entity,
       Replace(Replace(entered_by, ' (via dmswebuser)', ''), 'PNL\', '')::citext AS username,
       SUM(items) AS items
FROM ( SELECT 'Analysis job state change in sw.t_jobs' AS entity,
              entered_by,
              COUNT(*) AS items
       FROM sw.t_job_events
       WHERE entered BETWEEN CURRENT_TIMESTAMP - Interval '12 months' AND CURRENT_TIMESTAMP
       GROUP BY entered_by ) CountQ
GROUP BY entity, 2
UNION
SELECT 'Analysis job owner in sw.t_jobs' AS entity,
       owner_username AS username,
       COUNT(*) AS items
FROM sw.t_jobs
WHERE imported BETWEEN CURRENT_TIMESTAMP - Interval '12 months' AND CURRENT_TIMESTAMP
GROUP BY owner_username
UNION
SELECT 'Procedure usage in sw schema' AS entity,
       calling_user AS username,
       COUNT(*) AS items
FROM sw.t_sp_usage
WHERE entered BETWEEN CURRENT_TIMESTAMP - Interval '12 months' AND CURRENT_TIMESTAMP
GROUP BY calling_user
UNION
SELECT 'Capture task state change in cap.t_tasks' AS entity,
       Replace(entered_by, 'PNL\', '')::citext AS username,
       COUNT(*) AS items
FROM cap.t_task_events
WHERE entered BETWEEN CURRENT_TIMESTAMP - Interval '12 months' AND CURRENT_TIMESTAMP
GROUP BY 2
UNION
SELECT 'Data package owner' AS entity,
       owner_username AS username,
       COUNT(*) AS items
FROM dpkg.t_data_package
WHERE created BETWEEN CURRENT_TIMESTAMP - Interval '12 months' AND CURRENT_TIMESTAMP
GROUP BY owner_username
UNION
SELECT 'Data package requester' AS entity,
       requester AS username,
       COUNT(*) AS items
FROM dpkg.t_data_package
WHERE created BETWEEN CURRENT_TIMESTAMP - Interval '12 months' AND CURRENT_TIMESTAMP
GROUP BY requester
UNION
SELECT entity,
       CASE WHEN Semicolon_Position > 1
            THEN Left(entered_by, Semicolon_Position - 1)::citext
            ELSE entered_by
       END AS Entered_By,
       SUM(items) AS items
FROM (
    SELECT entity,
           CASE WHEN Via_Position > 1 AND (Semicolon_Position = 0 OR Via_Position < Semicolon_Position)
                THEN Left(entered_by, Via_Position - 1)::citext
                ELSE entered_by
           END AS Entered_By,
           Semicolon_Position,
           SUM(items) AS items
    FROM ( SELECT entity,
                  entered_by,
                  Position(' (via' in entered_by) AS Via_Position,
                  Position(';' in entered_by) AS Semicolon_Position,
                  items
           FROM ( SELECT 'Entity state change: ' || target AS entity,
                         Replace(entered_by, 'PNL\', '')::citext as entered_by,
                         COUNT(*) AS items
                  FROM v_event_log
                  WHERE entered BETWEEN CURRENT_TIMESTAMP - Interval '12 months' AND CURRENT_TIMESTAMP
                  GROUP BY 1, 2
                ) CountQ
          ) PositionQ
    GROUP BY entity, 2, Semicolon_Position) ReplaceQ
GROUP BY entity, 2
UNION
SELECT 'Requested run batch user' AS entity,
       U.username,
       COUNT(*) AS items
FROM t_requested_run_batches RRB
     INNER JOIN t_users U
       ON RRB.owner_user_id = U.user_id
WHERE RRB.created BETWEEN CURRENT_TIMESTAMP - Interval '12 months' AND CURRENT_TIMESTAMP
GROUP BY U.username
UNION
SELECT 'Requested run batch group user' AS entity,
       U.username,
       COUNT(*) AS items
FROM t_requested_run_batch_group RRBG
     INNER JOIN t_users U
       ON RRBG.owner_user_id = U.user_id
WHERE RRBG.created BETWEEN CURRENT_TIMESTAMP - Interval '12 months' AND CURRENT_TIMESTAMP
GROUP BY U.username
UNION
SELECT 'Sample prep request requester' AS entity,
       requester_username AS username,
       COUNT(*) AS items
FROM t_sample_prep_request
WHERE created BETWEEN CURRENT_TIMESTAMP - Interval '12 months' AND CURRENT_TIMESTAMP
GROUP BY requester_username
UNION
SELECT entity,
       assigned_personnel::citext AS username,
       items
FROM (
    SELECT entity,
           CASE WHEN Position('(' IN assigned_personnel) > 0
                THEN (regexp_match(assigned_personnel, '\((.+)\)'))[1]
                ELSE assigned_personnel
           END AS assigned_personnel,
           items
    FROM (
            SELECT entity,
                   Trim(regexp_split_to_table(assigned_personnel, ';')) AS assigned_personnel,
                   items
            FROM (
            SELECT 'Sample prep request personnel' AS entity,
                   assigned_personnel,
                   COUNT(*) AS items
            FROM t_sample_prep_request
            WHERE created BETWEEN CURRENT_TIMESTAMP - Interval '12 months' AND CURRENT_TIMESTAMP
            GROUP BY assigned_personnel) CountQ
         ) SplitQ
     ) MatchQ
WHERE NOT assigned_personnel IS null
UNION
SELECT 'Sample submission receiver' AS entity,
       U.username,
       COUNT(*) AS items
FROM t_sample_submission SS
     INNER JOIN t_users U
       ON SS.received_by_user_id = U.user_id
WHERE SS.created BETWEEN CURRENT_TIMESTAMP - Interval '12 months' AND CURRENT_TIMESTAMP
GROUP BY U.username
UNION
SELECT 'New user' AS entity,
       username,
       COUNT(*) AS items
FROM t_users
WHERE created BETWEEN CURRENT_TIMESTAMP - Interval '12 months' AND CURRENT_TIMESTAMP
GROUP BY username;
