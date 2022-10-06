--
-- Name: update_bto_usage(boolean); Type: FUNCTION; Schema: ont; Owner: d3l243
--

CREATE OR REPLACE FUNCTION ont.update_bto_usage(_infoonly boolean DEFAULT false) RETURNS TABLE(tissue_id public.citext, usage_all_time integer, usage_last_12_months integer)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:   Updates the usage columns in ont.t_cv_bto
**
**  Auth:   mem
**  Date:   11/08/2018 mem - Initial version
**          04/05/2022 mem - Ported to PostgreSQL
**          04/07/2022 mem - Use the query results to report status messages
**          10/04/2022 mem - Change _infoOnly from integer to boolean
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _rowDescription text;
    _message text := '';
    _message2 text := '';
    _rowsUpdated int := 0;
BEGIN
    _infoOnly := Coalesce(_infoOnly, true);

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

    If Not _infoOnly Then
        ---------------------------------------------------
        -- Update ont.t_cv_bto
        ---------------------------------------------------

        UPDATE ont.t_cv_bto
        SET usage_last_12_months = s.usage_last_12_months,
            usage_all_time = s.usage_all_time
        FROM Tmp_UsageStats s
        WHERE ont.t_cv_bto.Identifier = s.Tissue_ID AND
              (ont.t_cv_bto.Usage_Last_12_Months <> s.Usage_Last_12_Months Or
               ont.t_cv_bto.Usage_All_Time <> s.Usage_All_Time);
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _myRowCount > 0 Then
            _rowsUpdated := _rowsUpdated + _myRowCount;

            SELECT * FROM public.check_plural(_myRowCount, 'row', 'rows')
            INTO _rowDescription;

            _message := 'Updated ' || Cast(_myRowCount As text) || ' ' || _rowDescription || ' in ont.t_cv_bto';
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

            SELECT * FROM public.check_plural(_myRowCount, 'row', 'rows')
            INTO _rowDescription;

            _message2 := 'Set usage stats to 0 for ' || Cast(_myRowCount As text) || ' ' || _rowDescription || ' in ont.t_cv_bto';

            If _message = '' Then
                _message := _message2;
            Else
                _message := _message || '; ' || _message2;
            End If;
        End If;

        If _rowsUpdated = 0 Then
            _message := 'Usage stats are already up-to-date';
        End If;

        RETURN QUERY
        SELECT _message::citext, 0, 0;
    Else
        ---------------------------------------------------
        -- Preview new/updated usage stats
        ---------------------------------------------------

        RETURN QUERY
        SELECT identifier, s.usage_all_time, s.usage_last_12_months
        FROM ont.t_cv_bto INNER JOIN Tmp_UsageStats s
               ON ont.t_cv_bto.Identifier = s.Tissue_ID
        WHERE ont.t_cv_bto.Usage_Last_12_Months <> s.Usage_Last_12_Months Or
              ont.t_cv_bto.Usage_All_Time <> s.Usage_All_Time;

        If Not FOUND Then
            RETURN QUERY
            SELECT 'Usage stats are already up-to-date'::citext, 0, 0;
        End If;
    End If;

    DROP TABLE Tmp_UsageStats;

END
$$;


ALTER FUNCTION ont.update_bto_usage(_infoonly boolean) OWNER TO d3l243;

--
-- Name: FUNCTION update_bto_usage(_infoonly boolean); Type: COMMENT; Schema: ont; Owner: d3l243
--

COMMENT ON FUNCTION ont.update_bto_usage(_infoonly boolean) IS 'UpdateBTOUsage';

