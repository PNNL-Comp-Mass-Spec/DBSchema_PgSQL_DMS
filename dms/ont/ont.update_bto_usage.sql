--
-- Name: update_bto_usage(integer); Type: FUNCTION; Schema: ont; Owner: d3l243
--

CREATE OR REPLACE FUNCTION ont.update_bto_usage(_infoonly integer DEFAULT 0) RETURNS TABLE(tissue_id public.citext, usage_all_time integer, usage_last_12_months integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Updates the usage columns in ont.t_cv_bto
**
**  Auth:   mem
**  Date:   11/08/2018 mem - Initial version
**          04/05/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _rowDescription text;
    _message text := '';
    _message2 text := '';
    _rowsUpdated int := 0;
BEGIN
    _infoOnly := Coalesce(_infoOnly, 1);

    ---------------------------------------------------
    -- Populate a temporary table with tissue usage stats for DMS experiments
    ---------------------------------------------------
    --

    CREATE TEMP TABLE Tmp_UsageStats (
        Tissue_ID            citext NOT NULL,
        Usage_All_Time       int NOT NULL,
        Usage_Last_12_Months int NOT NULL Default 0
    );

    INSERT INTO Tmp_UsageStats( Tissue_ID,
                                Usage_All_Time )
    SELECT E.Tissue_ID,
           Count(*) AS Usage_All_Time
    FROM public.T_Experiments E
    WHERE NOT E.Tissue_ID IS NULL
    GROUP BY E.Tissue_ID;

    UPDATE Tmp_UsageStats
    SET Usage_Last_12_Months = SourceQ.Usage_Last_12_Months
    FROM ( SELECT E.Tissue_ID AS Tissue_ID,
                  Count(*) AS Usage_Last_12_Months
            FROM public.T_Experiments E
            WHERE NOT E.Tissue_ID IS NULL AND
                  E.Created >= CURRENT_DATE + INTERVAL '-365 days'
            GROUP BY E.Tissue_ID ) SourceQ
    WHERE Tmp_UsageStats.Tissue_ID = SourceQ.Tissue_ID;

    If _infoOnly = 0 Then
        ---------------------------------------------------
        -- Update ont.t_cv_bto
        ---------------------------------------------------

        UPDATE ont.t_cv_bto
        SET usage_last_12_months = Source.usage_last_12_months,
            usage_all_time = Source.usage_all_time
        FROM Tmp_UsageStats Source
        WHERE ont.t_cv_bto.Identifier = Source.Tissue_ID AND
              (ont.t_cv_bto.Usage_Last_12_Months <> Source.Usage_Last_12_Months Or
               ont.t_cv_bto.Usage_All_Time <> Source.Usage_All_Time);
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount > 0 Then
            _rowsUpdated := _rowsUpdated + _myRowCount;

            SELECT * FROM public.CheckPlural(_myRowCount, 'row', 'rows')
            INTO _rowDescription;

            _message := 'updated ' || Cast(_myRowCount As text) || ' ' || _rowDescription || ' in ont.t_cv_bto';
        End If;

        UPDATE ont.t_cv_bto
        SET usage_last_12_months = 0,
            usage_all_time = 0
        WHERE NOT ont.t_cv_bto.Identifier in (SELECT s.Tissue_ID FROM Tmp_UsageStats s) AND
                  (ont.t_cv_bto.Usage_Last_12_Months > 0 Or ont.t_cv_bto.Usage_All_Time > 0);
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount > 0 Then
            _rowsUpdated := _rowsUpdated + _myRowCount;

            SELECT * FROM public.CheckPlural(_myRowCount, 'row', 'rows')
            INTO _rowDescription;

            _message2 := 'Set usage stats to 0 for ' || Cast(_myRowCount As text) || ' ' || _rowDescription || ' in ont.t_cv_bto';

            If _message = '' Then
                _message := _message2;
            Else
                _message := _message || '; ' || _message2;
            End If;
        End If;

        If _rowsUpdated = 0 Then
            _message := 'Usage stats were already up-to-date';
        End If;

        If length(_message) > 0 Then
            Raise Info '%', _message;
        End If;
    Else
        ---------------------------------------------------
        -- Preview the usage stats
        ---------------------------------------------------
        RETURN QUERY
        SELECT s.Tissue_ID, s.Usage_All_Time, s.Usage_Last_12_Months
        FROM Tmp_UsageStats s
        ORDER BY s.Usage_All_Time DESC;
    End If;

    -- If not dropped here, the temporary table will persist until the calling session ends
    DROP TABLE Tmp_UsageStats;

END
$$;


ALTER FUNCTION ont.update_bto_usage(_infoonly integer) OWNER TO d3l243;

--
-- Name: FUNCTION update_bto_usage(_infoonly integer); Type: COMMENT; Schema: ont; Owner: d3l243
--

COMMENT ON FUNCTION ont.update_bto_usage(_infoonly integer) IS 'UpdateBTOUsage';

