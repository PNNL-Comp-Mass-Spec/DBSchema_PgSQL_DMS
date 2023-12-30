--
-- Name: update_cached_dataset_instruments(integer, integer, boolean, text, text); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.update_cached_dataset_instruments(IN _processingmode integer DEFAULT 0, IN _datasetid integer DEFAULT 0, IN _infoonly boolean DEFAULT false, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update t_cached_dataset_instruments
**
**  Arguments:
**    _processingMode   Processing mode: 0 to only add new datasets; 1 to add new datasets and update existing information
**    _datasetId        When non-zero, a single dataset ID to add / update
**    _infoOnly         When true, preview updates
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   mem
**  Date:   04/15/2019 mem - Initial version
**          10/06/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _matchCount int;
    _updateCount int;
    _addon text;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _previewData record;
    _infoData text;
BEGIN
    _message := '';
    _returnCode := '';

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    _processingMode := Coalesce(_processingMode, 0);
    _datasetId      := Coalesce(_datasetId, 0);
    _infoOnly       := Coalesce(_infoOnly, false);

    If _datasetId > 0 And Not _infoOnly Then
        MERGE INTO t_cached_dataset_instruments AS t
        USING ( SELECT DS.dataset_id,
                       DS.instrument_id As Instrument_ID,
                       InstName.instrument As Instrument
                FROM t_dataset DS
                     INNER JOIN t_instrument_name InstName
                       ON DS.instrument_id = InstName.instrument_id
                WHERE DS.dataset_id = _datasetId
              ) AS s
        ON (t.dataset_id = s.dataset_id)
        WHEN MATCHED AND
             (t.instrument_id <> s.instrument_id OR
              t.instrument <> s.instrument) THEN
            UPDATE SET
                instrument_id = s.instrument_id,
                instrument = s.instrument
        WHEN NOT MATCHED THEN
            INSERT(dataset_id, instrument_id, instrument)
            VALUES(s.dataset_id, s.instrument_id, s.instrument);

        RETURN;
    End If;

    If _processingMode = 0 Or _infoOnly Then

        ------------------------------------------------
        -- Add new datasets to t_cached_dataset_instruments
        ------------------------------------------------

        If _infoOnly Then

            -- Preview the addition of new datasets

            RAISE INFO '';

            _formatSpecifier := '%-10s %-13s %-25s %-50s';

            _infoHead := format(_formatSpecifier,
                                'Dataset_ID',
                                'Instrument_ID',
                                'Instrument',
                                'Status'
                               );

            _infoHeadSeparator := format(_formatSpecifier,
                                         '----------',
                                         '-------------',
                                         '-------------------------',
                                         '--------------------------------------------------'
                                        );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;
            _matchCount = 0;

            FOR _previewData IN
                SELECT DS.Dataset_ID,
                       DS.Instrument_ID,
                       InstName.Instrument,
                       'Dataset to add to t_cached_dataset_instruments' As Status
                FROM t_dataset DS
                     INNER JOIN t_instrument_name InstName
                       ON DS.instrument_id = InstName.instrument_id
                     LEFT OUTER JOIN t_cached_dataset_instruments CachedInst
                       ON DS.dataset_id = CachedInst.dataset_id
                WHERE CachedInst.dataset_id IS Null AND (_datasetId = 0 OR DS.dataset_id = _datasetId)
                ORDER BY DS.dataset_id
            LOOP
                _infoData := format(_formatSpecifier,
                                    _previewData.Dataset_ID,
                                    _previewData.Instrument_ID,
                                    _previewData.Instrument,
                                    _previewData.Status
                                   );

                RAISE INFO '%', _infoData;

                _matchCount := _matchCount + 1;
            END LOOP;

            If _matchCount = 0 Then
                RAISE INFO '';
                RAISE INFO 'No datasets need to be added to t_cached_dataset_instruments';
            End If;

        Else

            ------------------------------------------------
            -- Add new datasets
            ------------------------------------------------

            INSERT INTO t_cached_dataset_instruments (dataset_id,
                                                      instrument_id,
                                                      instrument)
            SELECT DS.dataset_id,
                   DS.instrument_id,
                   InstName.instrument
            FROM t_dataset DS
                 INNER JOIN t_instrument_name InstName
                   ON DS.instrument_id = InstName.instrument_id
                 LEFT OUTER JOIN t_cached_dataset_instruments CachedInst
                   ON DS.dataset_id = CachedInst.dataset_id
            WHERE CachedInst.dataset_id IS NULL;
            --
            GET DIAGNOSTICS _matchCount = ROW_COUNT;

            If _matchCount > 0 Then
                _message := format('Added %s new %s', _matchCount, public.check_plural(_matchCount, 'dataset', 'datasets'));
            End If;

            -- Only exit this procedure if _infoOnly is false (which is the case in this branch of the If/Else statement)
            RETURN;
        End If;

    End If;

    ------------------------------------------------
    -- Processing mode is non-zero (or _infoOnly is true)
    ------------------------------------------------

    If _infoOnly Then

        ------------------------------------------------
        -- Preview the update of cached info
        ------------------------------------------------

        RAISE INFO '';

        _formatSpecifier := '%-10s %-13s %-17s %-22s %-22s %-40s';

        _infoHead := format(_formatSpecifier,
                            'Dataset_ID',
                            'Instrument_ID',
                            'Instrument_ID_New',
                            'Instrument_Name',
                            'Instrument_Name_New',
                            'Status'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '-------------',
                                     '-----------------',
                                     '----------------------',
                                     '----------------------',
                                     '----------------------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;
        _matchCount := 0;

        FOR _previewData IN
            SELECT t.Dataset_ID,
                   t.Instrument_ID,
                   s.instrument_id AS Instrument_ID_New,
                   t.Instrument AS Instrument_Name,
                   s.instrument AS Instrument_Name_New,
                   'Dataset to update in t_instrument_name' As Status
            FROM t_cached_dataset_instruments t
                 INNER JOIN ( SELECT DS.dataset_id,
                                     DS.instrument_id AS Instrument_ID,
                                     InstName.instrument AS Instrument
                              FROM t_dataset DS
                                   INNER JOIN t_instrument_name InstName
                                     ON DS.instrument_id = InstName.instrument_id ) s
                   ON t.dataset_id = s.dataset_id
            WHERE (t.instrument_id <> s.instrument_id OR t.instrument <> s.instrument) AND
                  (_datasetId = 0 OR s.dataset_id = _datasetId)
            ORDER By t.dataset_id
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Dataset_ID,
                                _previewData.Instrument_ID,
                                _previewData.Instrument_ID_New,
                                _previewData.Instrument_Name,
                                _previewData.Instrument_Name_New,
                                _previewData.Status
                               );

            RAISE INFO '%', _infoData;
            _matchCount := _matchCount + 1;
        END LOOP;

        If _matchCount = 0 Then
            RAISE INFO '';
            RAISE INFO 'No data in t_cached_dataset_instruments needs to be updated';
        End If;

        RETURN;
    End If;

    ------------------------------------------------
    -- Update cached info
    ------------------------------------------------

    MERGE INTO t_cached_dataset_instruments AS t
    USING ( SELECT DS.dataset_id,
                   DS.instrument_id As Instrument_ID,
                   InstName.instrument As Instrument
            FROM t_dataset DS
                 INNER JOIN t_instrument_name InstName
                   ON DS.instrument_id = InstName.instrument_id
          ) AS s
    ON (t.dataset_id = s.dataset_id)
    WHEN MATCHED AND
         (t.instrument_id <> s.instrument_id OR
          t.instrument <> s.instrument) THEN
        UPDATE SET
            instrument_id = s.instrument_id,
            instrument = s.instrument
    WHEN NOT MATCHED THEN
        INSERT(dataset_id, instrument_id, instrument)
        VALUES(s.dataset_id, s.instrument_id, s.instrument);
    --
    GET DIAGNOSTICS _updateCount = ROW_COUNT;

    If _updateCount > 0 Then
        _addon := format('%s %s via a merge', _updateCount, public.check_plural(_updateCount, 'dataset was updated', 'datasets were updated'));
        _message := public.append_to_text(_message, _addon);
    End If;

    -- CALL post_log_entry ('Debug', _message, 'Update_Cached_Dataset_Instruments');

END
$$;


ALTER PROCEDURE public.update_cached_dataset_instruments(IN _processingmode integer, IN _datasetid integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE update_cached_dataset_instruments(IN _processingmode integer, IN _datasetid integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.update_cached_dataset_instruments(IN _processingmode integer, IN _datasetid integer, IN _infoonly boolean, INOUT _message text, INOUT _returncode text) IS 'UpdateCachedDatasetInstruments';

