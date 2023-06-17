--
CREATE OR REPLACE PROCEDURE public.update_cached_dataset_instruments
(
    _processingMode int = 0,
    _datasetId Int = 0,
    _infoOnly boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Updates T_Cached_Dataset_Instruments
**
**  Arguments:
**    _processingMode   0 to only add new datasets; 1 to add new datasets and update existing information
**    _datasetId        When non-zero, a single dataset ID to add / update
**
**  Auth:   mem
**  Date:   04/15/2019 mem - Initial version
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _matchCount;
    _updateCount;
    _addon text;
BEGIN
    _message := '';
    _returnCode := '';

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------

    _processingMode := Coalesce(_processingMode, 0);
    _datasetId := Coalesce(_datasetId, 0);
    _infoOnly := Coalesce(_infoOnly, false);

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

    ------------------------------------------------
    -- Add new datasets to t_cached_dataset_folder_paths
    ------------------------------------------------

    If _processingMode = 0 Or _infoOnly Then

        If _infoOnly Then

            -- ToDo: Update this to use RAISE INFO

            ------------------------------------------------
            -- Preview the addition of new datasets
            ------------------------------------------------

            SELECT DS.dataset_id,
                   DS.instrument_id,
                   InstName.instrument,
                   'dataset to add to t_cached_dataset_instruments' As Status
            FROM t_dataset DS
                 INNER JOIN t_instrument_name InstName
                   ON DS.instrument_id = InstName.instrument_id
                 LEFT OUTER JOIN t_cached_dataset_instruments CachedInst
                   ON DS.dataset_id = CachedInst.dataset_id
            WHERE CachedInst.dataset_id IS Null
            Order By DS.dataset_id

            If Not FOUND Then
                Select 'No datasets need to be added to t_cached_dataset_instruments' As Status;
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
        End If;

    End If;

    If _processingMode > 0 Then

        If _infoOnly Then

            -- ToDo: Update this to use RAISE INFO

            ------------------------------------------------
            -- Preview the update of cached info
            ------------------------------------------------

            SELECT t.dataset_id,
                   t.instrument_id,
                   s.instrument_id AS InstID_New,
                   t.instrument,
                   s.instrument AS InstName_New,
                   'dataset to update in t_instrument_name' As Status
            FROM t_cached_dataset_instruments t
                 INNER JOIN ( SELECT DS.dataset_id,
                                     DS.instrument_id AS Instrument_ID,
                                     InstName.instrument AS Instrument
                              FROM t_dataset DS
                                   INNER JOIN t_instrument_name InstName
                                     ON DS.instrument_id = InstName.instrument_id ) s
                   ON t.dataset_id = s.dataset_id
            WHERE t.instrument_id <> s.instrument_id OR
                  t.instrument <> s.instrument
            ORDER By t.dataset_id

            If Not FOUND Then
                Select 'No data in t_cached_dataset_instruments needs to be updated' As Status;
            End If;

        Else

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
                _message := public.append_to_text(_message, _addon, _delimiter => '; ', _maxlength => 512);
        End If;

    End If;

    -- CALL post_log_entry ('Debug', _message, 'Update_Cached_Dataset_Instruments');

END
$$;

COMMENT ON PROCEDURE public.update_cached_dataset_instruments IS 'UpdateCachedDatasetInstruments';
