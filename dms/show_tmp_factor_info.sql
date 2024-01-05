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
**          06/23/2023 mem - Increase column widths
**
*****************************************************/
DECLARE
    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
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

    _formatSpecifier := '%-10s %-80s %-30s %-45s %-12s %-12s %-14s';

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
                                 '--------------------------------------------------------------------------------',
                                 '------------------------------',
                                 '---------------------------------------------',
                                 '------------',
                                 '------------',
                                 '--------------'
                                );

    RAISE INFO '%', _infoHead;
    RAISE INFO '%', _infoHeadSeparator;

    FOR _previewData IN
        SELECT Entry_ID, Identifier, Factor, Value, DatasetID, RequestID, UpdateSkipCode
        FROM Tmp_FactorInfo
        ORDER BY Entry_ID
    LOOP
        _infoData := format(_formatSpecifier,
                            _previewData.Entry_ID,
                            _previewData.Identifier,
                            _previewData.Factor,
                            _previewData.Value,
                            _previewData.DatasetID,
                            _previewData.RequestID,
                            _previewData.UpdateSkipCode
                           );

        RAISE INFO '%', _infoData;
    END LOOP;

END
$$;


ALTER PROCEDURE public.show_tmp_factor_info() OWNER TO d3l243;

