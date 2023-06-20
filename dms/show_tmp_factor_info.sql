--
-- Name: show_tmp_factor_info(); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.show_tmp_factor_info()
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Show the contents of temporary table Tmp_FactorInfo
**      This procedure is called from public.update_requested_run_factors
**
**  Required table format:
**
**      CREATE TEMP TABLE Tmp_FactorInfo (
**          Entry_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
**          Identifier text null,           -- Could be RequestID or DatasetName
**          Factor text null,
**          Value text null,
**          DatasetID int null,             -- DatasetID; not always present
**          RequestID int null,
**          UpdateSkipCode int              -- 0 to update, 1 means unchanged, 2 means invalid factor name
**      );
**
**  Auth:   mem
**  Date:   12/13/2022 mem - Initial release
**
*****************************************************/
DECLARE
    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _infoData text;
    _factorInfo record;
BEGIN

    RAISE INFO '';

    If Not Exists (
       SELECT *
       FROM information_schema.tables
       WHERE table_type = 'LOCAL TEMPORARY' AND
             table_name::citext = 'Tmp_FactorInfo'
    ) Then
        RAISE WARNING 'Temporary table Tmp_FactorInfo does not exist; nothing to preview';
        RETURN;
    End If;

    If Not Exists (SELECT * FROM Tmp_FactorInfo) Then
        RAISE INFO 'Temp table Tmp_FactorInfo is empty; nothing to preview';
        RETURN;
    End If;

    -- Show contents of Tmp_FactorInfo
    --

    _formatSpecifier := '%-10s %-60s %-10s %-10s %-12s %-12s %-15s';

    _infoHead := format(_formatSpecifier,
                        'Entry_ID',
                        'Identifier',
                        'Factor',
                        'Value',
                        'DatasetID',
                        'RequestID',
                        'UpdateSkipCode'
                    );

    _infoHeadSeparator := format(_formatSpecifier,
                        '----------',
                        '------------------------------------------------------------',
                        '----------',
                        '----------',
                        '------------',
                        '------------',
                        '---------------'
                    );

    RAISE INFO '%', _infoHead;
    RAISE INFO '%', _infoHeadSeparator;

    FOR _factorInfo IN
        SELECT Entry_ID, Identifier, Factor, Value, DatasetID, RequestID, UpdateSkipCode
        FROM Tmp_FactorInfo
        ORDER BY Entry_ID
    LOOP
        _infoData := format(_formatSpecifier,
                                _factorInfo.Entry_ID,
                                _factorInfo.Identifier,
                                _factorInfo.Factor,
                                _factorInfo.Value,
                                _factorInfo.DatasetID,
                                _factorInfo.RequestID,
                                _factorInfo.UpdateSkipCode
                            );

        RAISE INFO '%', _infoData;

    END LOOP;

END
$$;


ALTER PROCEDURE public.show_tmp_factor_info() OWNER TO d3l243;

