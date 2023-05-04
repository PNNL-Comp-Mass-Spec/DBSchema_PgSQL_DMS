--
CREATE OR REPLACE PROCEDURE public.validate_dataset_type
(
    _datasetID int,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _infoOnly boolean = false,
    _autoDefineOnAllMismatches boolean = true
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Validates the dataset type defined in T_Dataset for the given dataset based on the contents of T_Dataset_ScanTypes
**
**  Auth:   mem
**  Date:   05/13/2010 mem - Initial version
**          05/14/2010 mem - Added support for the generic scan types MSn and HMSn
**          05/17/2010 mem - Updated _autoDefineOnAllMismatches to default to true
**          08/30/2011 mem - Updated to prevent MS-HMSn from getting auto-defined
**          03/27/2012 mem - Added support for GC-MS
**          08/15/2012 mem - Added support for IMS-HMS-HMSn
**          10/08/2012 mem - No longer overriding dataset type MALDI-HMS
**          10/19/2012 mem - Improved support for IMS-HMS-HMSn
**          02/28/2013 mem - No longer overriding dataset type C60-SIMS-HMS
**          05/08/2014 mem - No longer updating the dataset comment with 'Auto-switched dataset type from HMS-HMSn to HMS-HCD-HMSn'
**          01/13/2016 mem - Add support for ETciD and EThcD spectra
**          08/25/2016 mem - Do not change the dataset type from EI-HMS to HMS
**                         - Do not update the dataset comment when auto-changing an HMS dataset
**          04/28/2017 mem - Do not update the dataset comment when auto-changing an IMS dataset
**          06/12/2018 mem - Send _maxLength to AppendToText
**          06/03/2019 mem - Check for 'IMS' in ScanFilter
**          10/10/2020 mem - No longer update the comment when auto switching the dataset type
**          10/13/2020 mem - Add support for datasets that only have MS2 spectra (they will be assigned dataset type HMS or MS, despite the fact that they have no MS1 spectra; this is by design)
**          05/26/2021 mem - Add support for low res HCD
**          07/01/2021 mem - Auto-switch from HMS-CID-MSn to HMS-MSn
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
    _dataset text;
    _warnMessage text;
    _currentDatasetType citext;
    _datasetTypeAutoGen citext;
    _newDatasetType citext;
    _autoDefineDSType boolean;
    _actualCountMS int;
    _actualCountHMS int;
    _actualCountGCMS int;
    _actualCountCIDMSn int;
    _actualCountCIDHMSn int;
    _actualCountETDMSn int;
    _actualCountETDHMSn int;
    _actualCountHCDMSn int;
    _actualCountHCDHMSn int;
    _actualCountETciDMSn int;
    _actualCountETciDHMSn int;
    _actualCountEThcDMSn int;
    _actualCountEThcDHMSn int;
    _actualCountAnyMSn int;
    _actualCountAnyHMSn int;
    _actualCountMRM int;
    _actualCountPQD int;
    _newDSTypeID int;
    _hasIMS boolean := false;
    _requiredAction text := '';
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, false);
    _autoDefineOnAllMismatches := Coalesce(_autoDefineOnAllMismatches, true);

    -----------------------------------------------------------
    -- Lookup the dataset type for the given Dataset ID
    -----------------------------------------------------------

    _currentDatasetType := '';

    SELECT dataset, INTO _dataset
           _currentDatasetType = DST.Dataset_Type
    FROM t_dataset DS
         LEFT OUTER JOIN t_dataset_rating_name DST
           ON DS.dataset_type_ID = DST.DST_Type_ID
    WHERE (DS.dataset_id = _datasetID)
    --
    GET DIAGNOSTICS _myRowCount = ROW_COUNT;

    If _myRowCount = 0 Then
        _message := 'dataset ID not found in t_dataset: ' || _datasetID::text;
        _returnCode := 'U5101';
        RETURN;
    End If;

    If Not Exists (SELECT * FROM t_dataset_scan_types WHERE dataset_id = _datasetID) Then
        _message := 'Warning: Scan type info not found in t_dataset_scan_types for dataset ' || _dataset;
        RETURN;
    End If;

    -- Use the following to summarize the various scan_type values in t_dataset_scan_types
    -- SELECT scan_type, COUNT(*) AS ScanTypeCount
    -- FROM t_dataset_scan_types
    -- GROUP BY scan_type

    -----------------------------------------------------------
    -- Summarize the scan type information in t_dataset_scan_types
    -----------------------------------------------------------

    SELECT
           _actualCountMS = SUM(CASE WHEN ScanType = 'MS'        Then 1 Else 0 End),
           _actualCountHMS  = SUM(CASE WHEN ScanType = 'HMS'     Then 1 Else 0 End),
           _actualCountGCMS   = SUM(CASE WHEN ScanType = 'GC-MS' Then 1 Else 0 End),

           _actualCountAnyMSn  = SUM(CASE WHEN ScanType LIKE '%-MSn'    OR ScanType = 'MSn'  Then 1 Else 0 End),
           _actualCountAnyHMSn = SUM(CASE WHEN ScanType LIKE '%-HMSn'   OR ScanType = 'HMSn' Then 1 Else 0 End),

           _actualCountCIDMSn  = SUM(CASE WHEN ScanType LIKE '%CID-MSn'  OR ScanType = 'MSn'  Then 1 Else 0 End),
           _actualCountCIDHMSn = SUM(CASE WHEN ScanType LIKE '%CID-HMSn' OR ScanType = 'HMSn' Then 1 Else 0 End),

           _actualCountETDMSn  = SUM(CASE WHEN ScanType LIKE '%ETD-MSn'  Then 1 Else 0 End),
           _actualCountETDHMSn = SUM(CASE WHEN ScanType LIKE '%ETD-HMSn' Then 1 Else 0 End),

           _actualCountHCDMSn  = SUM(CASE WHEN ScanType LIKE '%HCD-MSn'  Then 1 Else 0 End),
           _actualCountHCDHMSn = SUM(CASE WHEN ScanType LIKE '%HCD-HMSn' Then 1 Else 0 End),

           _actualCountETciDMSn  = SUM(CASE WHEN ScanType LIKE '%ETciD-MSn'  Then 1 Else 0 End),
           _actualCountETciDHMSn = SUM(CASE WHEN ScanType LIKE '%ETciD-HMSn' Then 1 Else 0 End),
           _actualCountEThcDMSn  = SUM(CASE WHEN ScanType LIKE '%EThcD-MSn'  Then 1 Else 0 End),
           _actualCountEThcDHMSn = SUM(CASE WHEN ScanType LIKE '%EThcD-HMSn' Then 1 Else 0 End),

           _actualCountMRM = SUM(CASE WHEN ScanType SIMILAR TO '%SRM' or ScanType LIKE '%MRM' OR ScanType LIKE 'Q[1-3]MS' Then 1 Else 0 End),
           _actualCountPQD = SUM(CASE WHEN ScanType LIKE '%PQD%' Then 1 Else 0 End)

    FROM t_dataset_scan_types
    WHERE dataset_id = _datasetID
    GROUP BY dataset_id

    If _infoOnly Then
           SELECT _actualCountMS AS ActualCountMS,
                  _actualCountHMS AS ActualCountHMS,
                  _actualCountGCMS AS ActualCountGCMS,
                  _actualCountAnyMSn As ActualCountAnyMSn,
                  _actualCountAnyHMSn As ActualCountAnyHMSn,
                  _actualCountCIDMSn AS ActualCountCIDMSn,
                  _actualCountCIDHMSn AS ActualCountCIDHMSn,
                  _actualCountETDMSn AS ActualCountETDMSn,
                  _actualCountETDHMSn AS ActualCountETDHMSn,
                  _actualCountHCDMSn AS ActualCountHCDMSn,
                  _actualCountHCDHMSn AS ActualCountHCDHMSn,
                  _actualCountETciDMSn AS ActualCountETciDMSn,
                  _actualCountETciDHMSn AS ActualCountETciDHMSn,
                  _actualCountEThcDMSn AS ActualCountEThcDMSn,
                  _actualCountEThcDHMSn AS ActualCountEThcDHMSn,
                  _actualCountMRM AS ActualCountMRM,
                  _actualCountPQD AS ActualCountPQD

    End If;

    -----------------------------------------------------------
    -- Compare the actual scan type counts to the current dataset type
    -----------------------------------------------------------

    _datasetTypeAutoGen := '';
    _newDatasetType := '';
    _autoDefineDSType := false;
    _warnMessage := '';
    _requiredAction := '';

    If _actualCountMRM > 0 Then
        -- Auto switch to MRM if not MRM or SRM

        If Not (_currentDatasetType LIKE '%SRM' OR
                _currentDatasetType LIKE '%MRM' OR
                _currentDatasetType LIKE '%SIM') Then

            _newDatasetType := 'MRM';

        End If;

        _requiredAction := 'FixDSType';
    End If;

    If _requiredAction = '' Then
        If Exists (Select * FROM t_dataset_scan_types WHERE dataset_id = _datasetID And scan_filter = 'IMS') Then
            _hasIMS := true;
        End If;

        If _hasIMS And _currentDatasetType Like 'HMS%' Then
            _newDatasetType := 'IMS-' || _currentDatasetType;
            _requiredAction := 'FixDSType';
        End If;

        If _requiredAction = '' And Not _hasIMS And _currentDatasetType Like 'IMS-%MS%' Then
            _newDatasetType := Substring(_currentDatasetType, 5, 100);
            _requiredAction := 'FixDSType';
        End If;
    End If;

    If _requiredAction = '' And _actualCountHMS > 0 AND Not (_currentDatasetType LIKE 'HMS%' OR _currentDatasetType LIKE '%-HMS' OR _currentDatasetType LIKE 'IMS-HMS%') Then
        -- Dataset contains HMS spectra, but the current dataset type doesn't reflect that this is an HMS dataset

        If Not _currentDatasetType LIKE 'IMS%' Then
            _autoDefineDSType := true;
            If _infoOnly Then
                RAISE INFO 'Set _autoDefineDSType to true because _actualCountHMS > 0 AND Not (_currentDatasetType LIKE ''HMS%%'' Or _currentDatasetType LIKE ''%%-HMS'')';
            End If;
        Else
            _newDatasetType := ' an HMS-based dataset type';
        End If;

        _requiredAction := 'AutoDefineDSType';
    End If;

    If _requiredAction = '' And
       (_actualCountCIDHMSn + _actualCountETDHMSn + _actualCountHCDHMSn + _actualCountETciDHMSn + _actualCountEThcDHMSn) > 0 AND
       Not _currentDatasetType LIKE '%-HMSn%' Then

        -- Dataset contains CID, ETD, or HCD HMSn spectra, but the current dataset type doesn't reflect that this is an HMSn dataset

        If _currentDatasetType IN ('IMS-HMS', 'IMS-HMS-MSn') Then
            _newDatasetType := 'IMS-HMS-HMSn';
        ElsIf Not _currentDatasetType LIKE 'IMS%' Then
            _autoDefineDSType := true;
            If _infoOnly Then
                RAISE INFO 'Set _autoDefineDSType to true because (_actualCountCIDHMSn + _actualCountETDHMSn + _actualCountHCDHMSn + _actualCountETciDHMSn + _actualCountEThcDHMSn) > 0 AND Not _currentDatasetType LIKE ''%%-HMSn%%''';
            End If;

        Else
            _newDatasetType := ' an HMS-based dataset type';
        End If;

        _requiredAction := 'AutoDefineDSType';
    End If;

    If _requiredAction = '' And
       (_actualCountCIDMSn + _actualCountETDMSn + _actualCountHCDMSn + _actualCountETciDMSn + _actualCountEThcDMSn) > 0 AND
       Not _currentDatasetType LIKE '%-MSn%' Then

        -- Dataset contains CID or ETD MSn spectra, but the current dataset type doesn't reflect that this is an MSn dataset
        If _currentDatasetType = 'IMS-HMS' Then
            _newDatasetType := 'IMS-HMS-MSn';
        ElsIf Not _currentDatasetType LIKE 'IMS%' Then
            _autoDefineDSType := true;
            If _infoOnly Then
                RAISE INFO 'Set _autoDefineDSType to true because (_actualCountCIDMSn + _actualCountETDMSn + _actualCountHCDMSn + _actualCountETciDMSn + _actualCountEThcDMSn) > 0 AND Not _currentDatasetType LIKE ''%%-MSn%%''';
            End If;

        Else
            _newDatasetType := ' an MSn-based dataset type';
        End If;

        _requiredAction := 'AutoDefineDSType';
    End If;

    If _requiredAction = '' And (_actualCountETDMSn + _actualCountETDHMSn) > 0 AND Not _currentDatasetType LIKE '%ETD%' Then

        -- Dataset has ETD scans, but current dataset type doesn't reflect this
        If Not _currentDatasetType LIKE 'IMS%' Then
            _autoDefineDSType := true;
            If _infoOnly Then
                RAISE INFO 'Set _autoDefineDSType to true because (_actualCountETDMSn + _actualCountETDHMSn) > 0 AND Not _currentDatasetType LIKE ''%%ETD%%''';
            End If;
        Else
            _newDatasetType := ' an ETD-based dataset type';
        End If;

        _requiredAction := 'AutoDefineDSType';
    End If;

    If _requiredAction = '' And  _actualCountHCDMSn + _actualCountHCDHMSn > 0 AND Not _currentDatasetType LIKE '%HCD%' Then

        -- Dataset has HCD scans, but current dataset type doesn't reflect this
        If Not _currentDatasetType LIKE 'IMS%' Then
            _autoDefineDSType := true;
            If _infoOnly Then
                RAISE INFO 'Set _autoDefineDSType to true because _actualCountHCDMSn + _actualCountHCDHMSn > 0 AND Not _currentDatasetType LIKE ''%%HCD%%''';
            End If;
        Else
            _newDatasetType := ' an HCD-based dataset type';
        End If;

        _requiredAction := 'AutoDefineDSType';
    End If;

    If _requiredAction = '' And _actualCountPQD > 0 AND Not _currentDatasetType LIKE '%PQD%' Then
        -- Dataset has PQD scans, but current dataset type doesn't reflect this
        If Not _currentDatasetType LIKE 'IMS%' Then
            _autoDefineDSType := true;
            If _infoOnly Then
                RAISE INFO 'Set _autoDefineDSType to true because _actualCountPQD > 0 AND Not _currentDatasetType LIKE ''%%PQD%%''';
            End If;
        Else
            _newDatasetType := ' a PQD-based dataset type';
        End If;

        _requiredAction := 'AutoDefineDSType';
    End If;

    If _requiredAction = '' And _actualCountHCDMSn + _actualCountHCDHMSn = 0 AND _currentDatasetType LIKE '%HCD%' Then
        -- Dataset does not have HCD scans, but current dataset type says it does
        If Not _currentDatasetType LIKE 'IMS%' Then
            _autoDefineDSType := true;
            If _infoOnly Then
                RAISE INFO 'Set _autoDefineDSType to true because _actualCountHCDMSn + _actualCountHCDHMSn = 0 AND _currentDatasetType LIKE ''%%HCD%%''';
            End If;
        Else
            _warnMessage := 'Warning: Dataset type is ' || _currentDatasetType || ' but no HCD scans are present';
        End If;

        _requiredAction := 'AutoDefineDSType';
    End If;

    If _requiredAction = '' And (_actualCountETDMSn + _actualCountETDHMSn) = 0 AND _currentDatasetType LIKE '%ETD%' Then
        -- Dataset does not have ETD scans, but current dataset type says it does
        If Not _currentDatasetType LIKE 'IMS%' Then
            _autoDefineDSType := true;
            If _infoOnly Then
                RAISE INFO 'Set _autoDefineDSType to true because (_actualCountETDMSn + _actualCountETDHMSn) = 0 AND _currentDatasetType LIKE ''%%ETD%%''';
            End If;
        Else
            _warnMessage := 'Warning: Dataset type is ' || _currentDatasetType || ' but no ETD scans are present';
        End If;

        _requiredAction := 'AutoDefineDSType';
    End If;

    If _requiredAction = '' And _actualCountAnyMSn > 0 AND Not _currentDatasetType LIKE '%-MSn%' Then
        -- Dataset contains MSn spectra, but the current dataset type doesn't reflect that this is an MSn dataset
        If _currentDatasetType = 'IMS-HMS' Then
            _newDatasetType := 'IMS-HMS-MSn';
        ElsIf Not _currentDatasetType LIKE 'IMS%' Then
            _autoDefineDSType := true;
            If _infoOnly Then
                RAISE INFO 'Set _autoDefineDSType to true because _actualCountAnyMSn > 0 AND Not _currentDatasetType LIKE ''%%-MSn%%''';
            End If;
        Else
            _newDatasetType := ' an MSn-based dataset type';
        End If;

        _requiredAction := 'AutoDefineDSType';
    End If;

    If _requiredAction = '' And (_actualCountCIDHMSn + _actualCountETDHMSn + _actualCountHCDHMSn + _actualCountETciDHMSn + _actualCountEThcDHMSn) = 0 AND _currentDatasetType LIKE '%-HMSn%' Then
        -- Dataset does not have HMSn scans, but current dataset type says it does
        If Not _currentDatasetType LIKE 'IMS%' Then
            _autoDefineDSType := true;
            If _infoOnly Then
                RAISE INFO 'Set _autoDefineDSType to true because (_actualCountCIDHMSn + _actualCountETDHMSn + _actualCountHCDHMSn + _actualCountETciDHMSn + _actualCountEThcDHMSn) = 0 AND _currentDatasetType LIKE ''%%-HMSn%%''';
            End If;
        Else
            _warnMessage := 'Warning: Dataset type is ' || _currentDatasetType || ' but no high res MSn scans are present';
        End If;

        _requiredAction := 'AutoDefineDSType';
    End If;

    If _requiredAction = '' And (_actualCountCIDMSn + _actualCountETDMSn + _actualCountHCDMSn + _actualCountETciDMSn + _actualCountEThcDMSn) = 0 AND _currentDatasetType LIKE '%-MSn%' Then
        -- Dataset does not have MSn scans, but current dataset type says it does
        If Not _currentDatasetType LIKE 'IMS%' Then
            _autoDefineDSType := true;
            If _infoOnly Then
                RAISE INFO 'Set _autoDefineDSType to true because (_actualCountCIDMSn + _actualCountETDMSn + _actualCountHCDMSn + _actualCountETciDMSn + _actualCountEThcDMSn) = 0 AND _currentDatasetType LIKE ''%%-MSn%%''';
            End If;
        Else
            _warnMessage := 'Warning: Dataset type is ' || _currentDatasetType || ' but no low res MSn scans are present';
        End If;

        _requiredAction := 'AutoDefineDSType';
    End If;

    If _requiredAction = '' And _actualCountHMS = 0 AND (_currentDatasetType LIKE 'HMS%' Or _currentDatasetType LIKE '%-HMS') Then
        -- Dataset does not have HMS scans, but current dataset type says it does
        If Not _currentDatasetType LIKE 'IMS%' Then
            _autoDefineDSType := true;
            If _infoOnly Then
                RAISE INFO 'Set _autoDefineDSType to true because _actualCountHMS = 0 AND (_currentDatasetType LIKE ''HMS%%'' Or _currentDatasetType LIKE ''%%-HMS'')';
            End If;
        Else
            _warnMessage := 'Warning: Dataset type is ' || _currentDatasetType || ' but no HMS scans are present';
        End If;

        _requiredAction := 'AutoDefineDSType';
    End If;

    If _requiredAction = '' And _actualCountAnyHMSn > 0 AND Not _currentDatasetType LIKE '%-HMSn%' Then
        -- Dataset contains HMSn spectra, but the current dataset type doesn't reflect that this is an HMSn dataset
        If _currentDatasetType = 'IMS-HMS' Then
            _newDatasetType := 'IMS-HMS-HMSn';
        ElsIf Not _currentDatasetType LIKE 'IMS%' Then
            _autoDefineDSType := true;
            If _infoOnly Then
                RAISE INFO 'Set _autoDefineDSType to true because _actualCountAnyHMSn > 0 AND Not _currentDatasetType LIKE ''%%-HMSn%%''';
            End If;
        Else
            _newDatasetType := ' an HMSn-based dataset type';
        End If;

        _requiredAction := 'AutoDefineDSType';
    End If;

    If _requiredAction In ('', 'AutoDefineDSType') Then

        -----------------------------------------------------------
        -- Possibly auto-generate the dataset type
        -- If _autoDefineDSType is true, will update the dataset type to this value
        -- Otherwise, will compare to the actual dataset type and post a warning if they differ
        -----------------------------------------------------------

        If Not _currentDatasetType LIKE 'IMS%' AND NOT _currentDatasetType IN ('MALDI-HMS', 'C60-SIMS-HMS') Then
            -- Auto-define the dataset type based on the scan type counts
            -- The auto-defined types will be one of the following:
                -- MS
                -- HMS
                -- MS-MSn
                -- HMS-MSn
                -- HMS-HMSn
                -- GC-MS
            -- In addition, if HCD scans are present, -HCD will be in the middle
            -- Furthermore, if ETD scans are present, -ETD or -CID/ETD will be in the middle
            -- And finally, if ETciD or EThcD scans are present, -ETciD or -EThcD will be in the middle

            If _actualCountHMS > 0 Then
                _datasetTypeAutoGen := 'HMS';
            Else
                _datasetTypeAutoGen := 'MS';

                If _actualCountMS = 0 And (_actualCountCIDHMSn + _actualCountETDHMSn + _actualCountHCDHMSn + _actualCountETciDHMSn + _actualCountEThcDHMSn + _actualCountAnyHMSn) > 0 Then
                    -- Dataset only has fragmentation spectra and no MS1 spectra
                    -- Since all of the fragmentation spectra are high res, use 'HMS'
                    _datasetTypeAutoGen := 'HMS';
                End If;

                If _actualCountGCMS > 0 Then
                    _datasetTypeAutoGen := 'GC-MS';
                End If;
            End If;

            If (_actualCountETciDMSn + _actualCountEThcDMSn + _actualCountETciDHMSn + _actualCountEThcDHMSn) > 0 Then
                -- Has ETciD or EThcD spectra

                If (_actualCountETciDMSn + _actualCountETciDHMSn) > 0 AND (_actualCountEThcDMSn + _actualCountEThcDHMSn) > 0 Then
                    _datasetTypeAutoGen := _datasetTypeAutoGen || '-ETciD-EThcD';
                Else

                    If (_actualCountETciDMSn + _actualCountETciDHMSn) > 0 Then
                        _datasetTypeAutoGen := _datasetTypeAutoGen || '-ETciD';
                    End If;

                    If (_actualCountEThcDMSn + _actualCountEThcDHMSn) > 0 Then
                        _datasetTypeAutoGen := _datasetTypeAutoGen || '-EThcD';
                    End If;

                End If;

                If (_actualCountETciDHMSn + _actualCountEThcDHMSn) > 0 Then
                    _datasetTypeAutoGen := _datasetTypeAutoGen || '-HMSn';
                Else
                    _datasetTypeAutoGen := _datasetTypeAutoGen || '-MSn';
                End If;

            Else
                -- No ETciD or EThcD spectra

                If _actualCountHCDMSn + _actualCountHCDHMSn > 0 Then
                    _datasetTypeAutoGen := _datasetTypeAutoGen || '-HCD';
                End If;

                If _actualCountPQD > 0 Then
                    _datasetTypeAutoGen := _datasetTypeAutoGen || '-PQD';
                End If;

                If (_actualCountCIDHMSn + _actualCountETDHMSn + _actualCountHCDHMSn) > 0 Then
                    -- One or more High res CID, ETD, or HCD MSn spectra
                    If (_actualCountETDMSn + _actualCountETDHMSn) > 0 Then
                        -- One or more ETD spectra
                        If _actualCountCIDHMSn > 0 Then
                            _datasetTypeAutoGen := _datasetTypeAutoGen || '-CID/ETD-HMSn';
                        ElsIf _actualCountCIDMSn > 0
                            _datasetTypeAutoGen := _datasetTypeAutoGen || '-CID/ETD-MSn';
                        ElsIf _actualCountETDHMSn > 0
                            _datasetTypeAutoGen := _datasetTypeAutoGen || '-ETD-HMSn';
                        Else
                            _datasetTypeAutoGen := _datasetTypeAutoGen || '-ETD-MSn';
                        End If;
                    Else
                        -- No ETD spectra
                        If _actualCountCIDHMSn > 0 Then
                             _datasetTypeAutoGen := _datasetTypeAutoGen || '-CID-HMSn';
                        ElsIf _actualCountCIDMSn > 0 OR _actualCountPQD > 0
                            _datasetTypeAutoGen := _datasetTypeAutoGen || '-CID-MSn';
                        Else
                            _datasetTypeAutoGen := _datasetTypeAutoGen || '-HMSn';
                        End If;
                    End If;
                Else
                    -- No high res MSn spectra

                    If (_actualCountCIDMSn + _actualCountETDMSn + _actualCountHCDMSn) > 0 Then
                        -- One or more Low res CID, ETD, or HCD MSn spectra
                        If (_actualCountETDMSn) > 0 Then
                            -- One or more ETD spectra
                            If _actualCountCIDMSn > 0 Then
                                _datasetTypeAutoGen := _datasetTypeAutoGen || '-CID/ETD';
                            Else
                                _datasetTypeAutoGen := _datasetTypeAutoGen || '-ETD';
                            End If;
                        Else
                            -- No ETD spectra
                            If _actualCountCIDMSn > 0 OR _actualCountPQD > 0 Then
                                _datasetTypeAutoGen := _datasetTypeAutoGen || '-CID';
                            Else
                                _datasetTypeAutoGen := _datasetTypeAutoGen;
                            End If;
                        End If;

                        _datasetTypeAutoGen := _datasetTypeAutoGen || '-MSn';
                    End If;

                End If;

                -- Possibly auto-fix the auto-generated dataset type
                If _datasetTypeAutoGen = 'HMS-HCD' Then
                    If _actualCountHCDMSn > 0 And _actualCountHCDHMSn = 0 Then
                        _datasetTypeAutoGen := 'HMS-HCD-MSn';
                    Else
                        _datasetTypeAutoGen := 'HMS-HCD-HMSn';
                    End If;
                End If;

                If _datasetTypeAutoGen = 'HMS-CID-MSn' Then
                    _datasetTypeAutoGen := 'HMS-MSn';
                End If;
            End If;

        End If;

        If _datasetTypeAutoGen <> '' AND _autoDefineOnAllMismatches Then
            _autoDefineDSType := true;
            If _infoOnly Then
                RAISE INFO 'Set _autoDefineDSType to true because _datasetTypeAutoGen <> '''' (it is %) AND _autoDefineOnAllMismatches is true', _datasetTypeAutoGen;
            End If;
        End If;

        If _autoDefineDSType Then
            If _datasetTypeAutoGen <> _currentDatasetType And _datasetTypeAutoGen <> '' Then
                _newDatasetType := _datasetTypeAutoGen;
            End If;
        Else
            If _newDatasetType = '' And _warnMessage = '' Then
                If _datasetTypeAutoGen <> _currentDatasetType And _datasetTypeAutoGen <> '' Then
                    _warnMessage := 'Warning: Dataset type is ' || _currentDatasetType || ' while auto-generated type is ' || _datasetTypeAutoGen;
                End If;
            End If;
        End If;
    End If;

    -----------------------------------------------------------
    -- Action: FixDSType
    -----------------------------------------------------------

    -----------------------------------------------------------
    -- If a warning message was defined, display it
    -----------------------------------------------------------
    --
    If _warnMessage <> '' And Not (_currentDatasetType Like 'IMS%' and _datasetTypeAutoGen Like 'IMS%') Then
        _message := _warnMessage;

        RAISE WARNING '% (%)', _message, _dataset;
        RETURN;
    End If;

    -----------------------------------------------------------
    -- If a new dataset type is defined, update _newDSTypeID
    -----------------------------------------------------------
    --
    If _newDatasetType <> '' Then
        _newDSTypeID := 0;

        SELECT DST_Type_ID INTO _newDSTypeID
        FROM t_dataset_rating_name
        WHERE (Dataset_Type = _newDatasetType)
        --
        GET DIAGNOSTICS _myRowCount = ROW_COUNT;

        If _newDSTypeID <> 0 Then

            If _newDatasetType = 'HMS' And _currentDatasetType = 'EI-HMS' Then
                -- Leave the dataset type as 'EI-HMS'
                If _infoOnly Then
                    Select 'Leaving dataset type unchanged as ' || _currentDatasetType AS Comment
                End If;
                RETURN;
            End If;

            _message := 'Auto-switched dataset type from ' || _currentDatasetType || ' to ' || _newDatasetType;

            If Not _infoOnly Then
                UPDATE t_dataset
                SET dataset_type_ID = _newDSTypeID
                WHERE dataset_id = _datasetID
                --
                GET DIAGNOSTICS _myRowCount = ROW_COUNT;
            Else
                SELECT _newDatasetType AS NewDatasetType,
                       _newDSTypeID AS NewDSTypeID
            End If;
        Else
            _message := 'Unrecognized dataset type based on actual scan types; need to auto-switch from ' || _currentDatasetType || ' to ' || _newDatasetType;
        End If;
    End If;

    If _infoOnly Then
        If char_length(_message) = 0 Then
            _message := 'Dataset type is valid: ' || _currentDatasetType;
        End If;

        RAISE INFO '%', _message;
        RAISE INFO 'Dataset: %', _dataset;
    End If;

END
$$;

COMMENT ON PROCEDURE public.validate_dataset_type IS 'ValidateDatasetType';
