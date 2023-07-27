--
CREATE OR REPLACE PROCEDURE public.validate_analysis_job_request_datasets
(
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _autoRemoveNotReleasedDatasets boolean = false,
    _toolName text = 'unknown',
    _allowNewDatasets boolean = false,
    _allowNonReleasedDatasets boolean = false,
    _showDebugMessages boolean = false,
    _showDatasetInfoTable boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Validates datasets in temporary table Tmp_DatasetInfo
**
**      The calling procedure must create Tmp_DatasetInfo and populate it with the dataset names;
**      the remaining columns in the table will be populated by this procedure
**
**      CREATE TEMP TABLE Tmp_DatasetInfo (
**          Dataset_Name text,
**          Dataset_ID int NULL,
**          Instrument_Class text NULL,
**          Dataset_State_ID int NULL,
**          Archive_State_ID int NULL,
**          Dataset_Type text NULL,
**          Dataset_Rating_ID smallint NULL,
**      );
**
**  Arguments:
**    _message                         Output: error message
**    _returnCode                      Output: empty string if no error, error code if a validation problem
**    _autoRemoveNotReleasedDatasets   When true, automatically removes datasets from Tmp_DatasetInfo if they have an invalid rating
**    _allowNewDatasets                When false, all datasets must have state 3 (Complete); when true, will also allow datasets with state 1 or 2 (New or Capture In Progress)
**    _allowNonReleasedDatasets        When true, allow datasets to have a rating of 'Not Released'
**    _showDebugMessages               When true, show message info
**    _showDatasetInfoTable            When true, if _showDebugMessages is also true, show the contents of Tmp_DatasetInfo
**
**  Auth:   mem
**  Date:   11/12/2012 mem - Initial version (extracted code from Add_Update_Analysis_Job_Request and Validate_Analysis_Job_Parameters)
**          03/05/2013 mem - Added parameter _autoRemoveNotReleasedDatasets
**          08/02/2013 mem - Tweaked message for 'Not Released' datasets
**          03/30/2015 mem - Tweak warning message grammar
**          04/23/2015 mem - Added parameter _toolName
**          06/24/2015 mem - Added parameter _showDebugMessages
**          07/20/2016 mem - Tweak error messages
**          12/06/2017 mem - Add _allowNewDatasets
**          07/30/2019 mem - Tabs to spaces
**          03/10/2021 mem - Skip HMS vs. MS check when the tool is MaxQuant
**          05/25/2021 mem - Add _allowNonReleasedDatasets
**          08/26/2021 mem - Skip HMS vs. MS check when the tool is MSFragger
**          10/20/2022 mem - Added parameter _showDatasetInfoTable
**          03/22/2023 mem - Also auto-remove datasets named 'Dataset Name' and 'Dataset_Name' from Tmp_DatasetInfo
**          03/27/2023 mem - Skip HMS vs. MS check when the tool is DiaNN
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _list text;
    _notReleasedCount int := 0;
    _hmsCount int := 0;
    _msCount int := 0;
BEGIN
    _message := '';
    _returnCode := '';

    _autoRemoveNotReleasedDatasets := Coalesce(_autoRemoveNotReleasedDatasets, false);
    _toolName = Coalesce(_toolName, 'unknown');
    _allowNewDatasets := Coalesce(_allowNewDatasets, false);
    _allowNonReleasedDatasets := Coalesce(_allowNonReleasedDatasets, false);
    _showDebugMessages := Coalesce(_showDebugMessages, false);
    _showDatasetInfoTable := Coalesce(_showDatasetInfoTable, false);

    ---------------------------------------------------
    -- Auto-delete dataset column names from Tmp_DatasetInfo
    ---------------------------------------------------

    DELETE FROM Tmp_DatasetInfo
    WHERE Dataset_Name::citext IN ('Dataset', 'Dataset Name', 'Dataset_Name', 'Dataset_Num')

    ---------------------------------------------------
    -- Update the additional info in Tmp_DatasetInfo
    ---------------------------------------------------

    UPDATE Tmp_DatasetInfo
    SET Tmp_DatasetInfo.dataset_id = t_dataset.dataset_id,
        Tmp_DatasetInfo.instrument_class = t_instrument_class.instrument_class,
        Tmp_DatasetInfo.dataset_state_id = t_dataset.dataset_state_id,
        Tmp_DatasetInfo.archive_state_id = Coalesce(t_dataset_archive.archive_state_id, 0),
        Tmp_DatasetInfo.Dataset_Type = t_dataset_rating_name.Dataset_Type,
        Tmp_DatasetInfo.Dataset_Rating_ID = t_dataset.dataset_rating_id
    FROM t_dataset
         INNER JOIN t_instrument_name
           ON t_dataset.instrument_id = t_instrument_name.instrument_id
         INNER JOIN t_instrument_class
           ON t_instrument_name.instrument_class = t_instrument_class.instrument_class
         INNER JOIN t_dataset_rating_name
           ON t_dataset_type_name.dataset_type_id = t_dataset.dataset_type_ID
         LEFT OUTER JOIN t_dataset_archive
           ON t_dataset.dataset_id = t_dataset_archive.dataset_id
    WHERE Tmp_DatasetInfo.dataset = t_dataset.dataset;

    If _showDebugMessages And _showDatasetInfoTable Then

        RAISE INFO '';

        _formatSpecifier := '%-10s %-25s %-16s %-16s %-25s %-17s %-80s';

        _infoHead := format(_formatSpecifier,
                            'Dataset_ID',
                            'Instrument_Class',
                            'Dataset_State_ID',
                            'Archive_State_ID',
                            'Dataset_Type',
                            'Dataset_Rating_ID',
                            'Dataset'
                           );

        _infoHeadSeparator := format(_formatSpecifier,
                                     '----------',
                                     '-------------------------',
                                     '----------------',
                                     '----------------',
                                     '-------------------------',
                                     '-----------------',
                                     '--------------------------------------------------------------------------------'
                                    );

        RAISE INFO '%', _infoHead;
        RAISE INFO '%', _infoHeadSeparator;

        FOR _previewData IN
            SELECT Dataset_ID,
                   Instrument_Class,
                   Dataset_State_ID,
                   Archive_State_ID,
                   Dataset_Type,
                   Dataset_Rating_ID,
                   Dataset_Name AS Dataset
            FROM Tmp_DatasetInfo
            ORDER BY Dataset_Name
        LOOP
            _infoData := format(_formatSpecifier,
                                _previewData.Dataset_ID,
                                _previewData.Instrument_Class,
                                _previewData.Dataset_State_ID,
                                _previewData.Archive_State_ID,
                                _previewData.Dataset_Type,
                                _previewData.Dataset_Rating_ID,
                                _previewData.Dataset
                               );

            RAISE INFO '%', _infoData;
        END LOOP;

    End If;

    ---------------------------------------------------
    -- Make sure none of the datasets has a rating of -5 (Not Released)
    ---------------------------------------------------

    SELECT COUNT(Dataset_Name)
    INTO _notReleasedCount
    FROM Tmp_DatasetInfo
    WHERE dataset_rating_id = -5;

    If _notReleasedCount > 0 And Not _allowNonReleasedDatasets Then

        SELECT string_agg(Dataset_Name, ', ' ORDER BY Dataset_Name)
        INTO _list
        FROM Tmp_DatasetInfo
        WHERE dataset_rating_id = -5;

        -- Truncate if over 400 characters long
        If char_length(_list) >= 400 Then
            _list := format('%s...', Left(_list, 397));
        End If;

        If Not _autoRemoveNotReleasedDatasets Then
            If _notReleasedCount = 1 Then
                _message := format('Dataset is "Not Released": %s', _list);
            Else
                _message := format('%s datasets are "Not Released": %s', _notReleasedCount, _list);
            End If;

            If _showDebugMessages Then
                RAISE INFO '%', _message;
            End If;

            _returnCode := 'U5201';
            RETURN;
        Else
            _message := format('Skipped %s "Not Released" %s: %s', _notReleasedCount, public.check_plural(_notReleasedCount, 'dataset', 'datasets'), _list);

            If _showDebugMessages Then
                RAISE INFO '%', _message;
            End If;

            DELETE FROM Tmp_DatasetInfo
            WHERE dataset_rating_id = -5;

        End If;
    End If;

    ---------------------------------------------------
    -- Verify that datasets in list all exist
    ---------------------------------------------------

    SELECT string_agg(Dataset_Name, ', ' ORDER BY Dataset_Name)
    INTO _list
    FROM Tmp_DatasetInfo
    WHERE Dataset_ID IS NULL;

    If Coalesce(_list, '') <> '' Then
        _message := format('The following datasets were not in the database: %s', _list);

        If _showDebugMessages Then
            RAISE INFO '%', _message;
        End If;

        _returnCode := 'U5202';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Verify state of datasets
    -- If _allowNewDatasets is false, they must all have state Complete
    -- If _allowNewDatasets is true, we also allow New and Capture In Progress datasets
    ---------------------------------------------------

    SELECT string_agg(Dataset_Name, ', ' ORDER BY Dataset_Name)
    INTO _list
    FROM Tmp_DatasetInfo
    WHERE (NOT _allowNewDatasets AND     dataset_state_id <> 3) OR
          (    _allowNewDatasets AND NOT dataset_state_id IN (1,2,3));

    If Coalesce(_list, '') <> '' Then
        _message := format('The following datasets were not in correct state: %s', _list);
        If _showDebugMessages Then
            RAISE INFO '%', _message;
        End If;

        _returnCode := 'U5203';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Verify rating of datasets
    ---------------------------------------------------

    SELECT string_agg(Dataset_Name, ', ' ORDER BY Dataset_Name)
    INTO _list
    FROM Tmp_DatasetInfo
    WHERE dataset_rating_id IN (-1, -2);

    If Coalesce(_list, '') <> '' Then
        _message := format('The following datasets have a rating of -1 (No Data) or -2 (Data Files Missing): %s', _list);
        If _showDebugMessages Then
            RAISE INFO '%', _message;
        End If;

        _returnCode := 'U5204';
        RETURN;
    End If;

    ---------------------------------------------------
    -- Do not allow high res datasets to be mixed with low res datasets
    -- (though this is OK if the tool is MSXML_Gen, MaxQuant, MSFragger, or DiaNN)
    ---------------------------------------------------

    SELECT COUNT(Dataset_Name)
    INTO _hmsCount
    FROM Tmp_DatasetInfo
    WHERE Dataset_Type ILIKE 'HMS%' OR
          Dataset_Type ILIKE 'IMS-HMS%';

    SELECT COUNT(Dataset_Name)
    INTO _msCount
    FROM Tmp_DatasetInfo
    WHERE Dataset_Type LIKE 'MS%' OR
          Dataset_Type LIKE 'IMS-MS%';

    If _hmsCount > 0 AND _msCount > 0 AND NOT _toolName::citext IN ('MSXML_Gen', 'MaxQuant', 'MSFragger', 'DiaNN') Then
        _message := format('You cannot mix high-res MS datasets with low-res datasets; create separate analysis job requests. '
                           'You currently have %s high res (HMS) and %s low res (MS) datasets', _hmsCount, _msCount);

        If _showDebugMessages Then
            RAISE INFO '%', _message;
        End If;

        _returnCode := 'U5205';
        RETURN;
    End If;

END
$$;

COMMENT ON PROCEDURE public.validate_analysis_job_request_datasets IS 'ValidateAnalysisJobRequestDatasets';
