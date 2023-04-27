--
CREATE OR REPLACE PROCEDURE public.update_cached_secondary_sep_usage
(
    INOUT _message text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates the data in T_Secondary_Sep_Usage
**
**  Auth:   mem
**  Date:   11/18/2015 mem - Initial Version
**          02/23/2016 mem - Add set XACT_ABORT on
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _callingProcName text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN

    _message := '';

    Begin

        MERGE INTO t_secondary_sep_usage AS t
        USING ( SELECT
                    SS.separation_type_id,
                    SUM(CASE
                            WHEN public.months_between(DS.Created, CURRENT_TIMESTAMP) <= 12 THEN 1
                            ELSE 0
                        END) AS Usage_Last12Months,
                    SUM(CASE
                            WHEN DS.Dataset_ID IS NULL THEN 0
                            ELSE 1
                        END) AS Usage_AllYears,
                    MAX(DS.created) AS Most_Recent_Use
                FROM t_secondary_sep SS
                     LEFT OUTER JOIN t_dataset DS
                       ON DS.separation_type = SS.separation_type
                GROUP BY SS.separation_type_id, SS.separation_type
              ) AS s
        ON (t.separation_type_id = s.separation_type_id)
        WHEN MATCHED AND
             (t.Usage_Last12Months IS DISTINCT FROM s.Usage_Last12Months OR
              t.Usage_AllYears IS DISTINCT FROM s.Usage_AllYears or
              t.Most_Recent_Use IS DISTINCT FROM s.Most_Recent_Use) THEN
            UPDATE SET
                Usage_Last12Months = s.Usage_Last12Months,
                Usage_AllYears = s.Usage_AllYears,
                Most_Recent_Use = s.Most_Recent_Use
        WHEN NOT MATCHED THEN
            INSERT (separation_type_id, Usage_Last12Months, Usage_AllYears, Most_Recent_Use)
            VALUES (s.separation_type_id, s.Usage_Last12Months, s.Usage_AllYears, s.Most_Recent_Use);

        -- Delete rows in t_secondary_sep_usage that are not in t_secondary_sep

        DELETE FROM t_secondary_sep_usage target
        WHERE NOT EXISTS (SELECT SS.separation_type_id
                          FROM t_secondary_sep SS
                          WHERE target.separation_type_id = SS.separation_type_id
                         );

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => true);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;
    END;

END
$$;

COMMENT ON PROCEDURE public.update_cached_secondary_sep_usage IS 'UpdateCachedSecondarySepUsage';
