--
-- Name: validate_dataset_type(integer, text, text, boolean, boolean); Type: PROCEDURE; Schema: public; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE public.validate_dataset_type(IN _datasetid integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _infoonly boolean DEFAULT false, IN _autodefineonallmismatches boolean DEFAULT true)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Validate the dataset type defined in t_dataset for the given dataset based on the contents of t_dataset_scantypes
**
**  Arguments:
**    _datasetID                    Dataset ID
**    _message                      Status message
**    _returnCode                   Return code
**    _infoonly                     When true, preview updates
**    _autoDefineOnAllMismatches    When true, auto-update the dataset type
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
**          06/12/2018 mem - Send _maxLength to append_to_text
**          06/03/2019 mem - Check for 'IMS' in ScanFilter
**          10/10/2020 mem - No longer update the comment when auto switching the dataset type
**          10/13/2020 mem - Add support for datasets that only have MS2 spectra (they will be assigned dataset type HMS or MS, despite the fact that they have no MS1 spectra; this is by design)
**          05/26/2021 mem - Add support for low res HCD
**          07/01/2021 mem - Auto-switch from HMS-CID-MSn to HMS-MSn
**          06/12/2023 mem - Sum actual scan counts, not simply 0 or 1
**                         - Ported to PostgreSQL
**          09/07/2023 mem - Align assignment statements
**          09/08/2023 mem - Adjust capitalization of keywords
**          01/10/2024 mem - Add support for DIA datasets
**          01/30/2024 mem - Auto-switch from HMS-CID-HMSn to HMS-HMSn
**
*****************************************************/
DECLARE
    _dataset text;
    _warnMessage text;
    _currentDatasetType citext;
    _datasetTypeAutoGen citext;
    _newDatasetType citext;
    _autoDefineDSType boolean;
    _scanCounts record;
    _newDSTypeID int;
    _hasIMS boolean := false;
    _requiredAction text := '';
    _logMessage text;
BEGIN
    _message := '';
    _returnCode := '';

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    _infoOnly                  := Coalesce(_infoOnly, false);
    _autoDefineOnAllMismatches := Coalesce(_autoDefineOnAllMismatches, true);

    -----------------------------------------------------------
    -- Lookup the dataset type for the given Dataset ID
    -----------------------------------------------------------

    SELECT DS.dataset,
           DST.Dataset_Type
    INTO _dataset, _currentDatasetType
    FROM t_dataset DS
         LEFT OUTER JOIN t_dataset_type_name DST
           ON DS.dataset_type_ID = DST.dataset_type_ID
    WHERE DS.dataset_id = _datasetID;

    If Not FOUND Then
        _message := format('Dataset ID not found in t_dataset: %s', _datasetID);
        _returnCode := 'U5201';
        RETURN;
    End If;

    If Not Exists (SELECT dataset_id FROM t_dataset_scan_types WHERE dataset_id = _datasetID) Then
        _message := format('Warning: Scan type info not found in t_dataset_scan_types for dataset %s', _dataset);
        RETURN;
    End If;

    -- Use the following to summarize the various scan_type values in t_dataset_scan_types
    -- SELECT scan_type, COUNT(entry_id) AS scan_type_count
    -- FROM t_dataset_scan_types
    -- GROUP BY scan_type

    -----------------------------------------------------------
    -- Summarize the scan type information in t_dataset_scan_types
    -----------------------------------------------------------

    SELECT SUM(CASE WHEN Scan_Type = 'MS'    Then scan_count Else 0 End) AS ActualCountMS,
           SUM(CASE WHEN Scan_Type = 'HMS'   Then scan_count Else 0 End) AS ActualCountHMS,
           SUM(CASE WHEN Scan_Type = 'GC-MS' Then scan_count Else 0 End) AS ActualCountGCMS,

           SUM(CASE WHEN Scan_Type LIKE '%-MSn'    OR Scan_Type = 'MSn'  Then scan_count Else 0 End) AS ActualCountAnyMSn,
           SUM(CASE WHEN Scan_Type LIKE '%-HMSn'   OR Scan_Type = 'HMSn' Then scan_count Else 0 End) AS ActualCountAnyHMSn,

           SUM(CASE WHEN Scan_Type LIKE '%CID-MSn'  OR Scan_Type = 'MSn'  Then scan_count Else 0 End) AS ActualCountCIDMSn,
           SUM(CASE WHEN Scan_Type LIKE '%CID-HMSn' OR Scan_Type = 'HMSn' Then scan_count Else 0 End) AS ActualCountCIDHMSn,

           SUM(CASE WHEN Scan_Type LIKE '%ETD-MSn'  Then scan_count Else 0 End) AS ActualCountETDMSn,
           SUM(CASE WHEN Scan_Type LIKE '%ETD-HMSn' Then scan_count Else 0 End) AS ActualCountETDHMSn,

           SUM(CASE WHEN Scan_Type LIKE '%HCD-MSn'  Then scan_count Else 0 End) AS ActualCountHCDMSn,
           SUM(CASE WHEN Scan_Type LIKE '%HCD-HMSn' Then scan_count Else 0 End) AS ActualCountHCDHMSn,

           SUM(CASE WHEN Scan_Type LIKE '%ETciD-MSn'  Then scan_count Else 0 End) AS ActualCountETciDMSn,
           SUM(CASE WHEN Scan_Type LIKE '%ETciD-HMSn' Then scan_count Else 0 End) AS ActualCountETciDHMSn,
           SUM(CASE WHEN Scan_Type LIKE '%EThcD-MSn'  Then scan_count Else 0 End) AS ActualCountEThcDMSn,
           SUM(CASE WHEN Scan_Type LIKE '%EThcD-HMSn' Then scan_count Else 0 End) AS ActualCountEThcDHMSn,

           SUM(CASE WHEN Scan_Type LIKE 'DIA%' Then scan_count Else 0 End)                                                             AS ActualCountDIA,
           SUM(CASE WHEN Scan_Type LIKE '%SRM' Or Scan_Type LIKE '%MRM' OR Scan_Type SIMILAR TO 'Q[1-3]MS' Then scan_count Else 0 End) AS ActualCountMRM,
           SUM(CASE WHEN Scan_Type LIKE '%PQD%' Then scan_count Else 0 End)                                                            AS ActualCountPQD
    INTO _scanCounts
    FROM t_dataset_scan_types
    WHERE dataset_id = _datasetID
    GROUP BY dataset_id;

    If _infoOnly Then
        RAISE INFO '';
        RAISE INFO 'Actual scan counts for % (Dataset ID %)', _dataset, _datasetID;
        RAISE INFO '%', format('      MS:  %6s,        HMS: %6s, GCMS: %6s', _scanCounts.ActualCountMS, _scanCounts.ActualCountHMS, _scanCounts.ActualCountGCMS);
        RAISE INFO '%', format('      MRM: %6s,        PQD: %6s, DIA:  %6s', _scanCounts.ActualCountMRM, _scanCounts.ActualCountPQD, _scanCounts.ActualCountDIA);
        RAISE INFO '%', format('  Any MSn: %6s,   Any HMSn: %6s',            _scanCounts.ActualCountAnyMSn, _scanCounts.ActualCountAnyHMSn);
        RAISE INFO '%', format('  CID MSn: %6s,   CID HMSn: %6s',            _scanCounts.ActualCountCIDMSn, _scanCounts.ActualCountCIDHMSn);
        RAISE INFO '%', format('  ETD MSn: %6s,   ETD HMSn: %6s',            _scanCounts.ActualCountETDMSn, _scanCounts.ActualCountETDHMSn);
        RAISE INFO '%', format('  HCD MSn: %6s,   HCD HMSn: %6s',            _scanCounts.ActualCountHCDMSn, _scanCounts.ActualCountHCDHMSn);
        RAISE INFO '%', format('ETciD MSn: %6s, ETciD HMSn: %6s',            _scanCounts.ActualCountETciDMSn, _scanCounts.ActualCountETciDHMSn);
        RAISE INFO '%', format('EThcD MSn: %6s, EThcD HMSn: %6s',            _scanCounts.ActualCountEThcDMSn, _scanCounts.ActualCountEThcDHMSn);
        RAISE INFO '';
    End If;

    -----------------------------------------------------------
    -- Compare the actual scan type counts to the current dataset type
    -----------------------------------------------------------

    _datasetTypeAutoGen := '';
    _newDatasetType     := '';
    _autoDefineDSType   := false;
    _warnMessage        := '';
    _requiredAction     := '';

    If _scanCounts.ActualCountMRM > 0 Then
        -- Auto switch to MRM if not MRM or SRM

        If Not (_currentDatasetType Like '%SRM' Or
                _currentDatasetType Like '%MRM' Or
                _currentDatasetType Like '%SIM'
               ) Then

            _newDatasetType := 'MRM';

        End If;

        _requiredAction := 'FixDSType';
    End If;

    If _requiredAction = '' Then
        If Exists (SELECT dataset_id FROM t_dataset_scan_types WHERE dataset_id = _datasetID And scan_filter = 'IMS') Then
            _hasIMS := true;
        End If;

        If _hasIMS And _currentDatasetType Like 'HMS%' Then
            _newDatasetType := format('IMS-%s', _currentDatasetType);
            _requiredAction := 'FixDSType';
        End If;

        If _requiredAction = '' And Not _hasIMS And _currentDatasetType Like 'IMS-%MS%' Then
            _newDatasetType := Substring(_currentDatasetType, 5, 100);
            _requiredAction := 'FixDSType';
        End If;
    End If;

    If _requiredAction = '' And _scanCounts.ActualCountHMS > 0 And
       Not (_currentDatasetType Like 'HMS%' Or
            _currentDatasetType Like '%-HMS' Or
            _currentDatasetType Like 'IMS-HMS%'
           ) Then

        -- Dataset contains HMS spectra, but the current dataset type doesn't reflect that this is an HMS dataset

        If Not _currentDatasetType Like 'IMS%' Then
            _autoDefineDSType := true;

            If _infoOnly Then
                RAISE INFO 'Set _autoDefineDSType to true because ActualCountHMS > 0 And Not (_currentDatasetType Like ''HMS%%'' Or _currentDatasetType Like ''%%-HMS'')';
            End If;
        Else
            _newDatasetType := ' an HMS-based dataset type';
        End If;

        _requiredAction := 'AutoDefineDSType';
    End If;

    If _requiredAction = '' And
       (_scanCounts.ActualCountCIDHMSn + _scanCounts.ActualCountETDHMSn + _scanCounts.ActualCountHCDHMSn + _scanCounts.ActualCountETciDHMSn + _scanCounts.ActualCountEThcDHMSn) > 0 And
       Not _currentDatasetType Like '%-HMSn%' Then

        -- Dataset contains CID, ETD, or HCD HMSn spectra, but the current dataset type doesn't reflect that this is an HMSn dataset

        If _currentDatasetType In ('IMS-HMS', 'IMS-HMS-MSn') Then
            _newDatasetType := 'IMS-HMS-HMSn';
        ElsIf Not _currentDatasetType Like 'IMS%' Then
            _autoDefineDSType := true;

            If _infoOnly Then
                RAISE INFO 'Set _autoDefineDSType to true because (ActualCountCIDHMSn + ActualCountETDHMSn + ActualCountHCDHMSn + ActualCountETciDHMSn + ActualCountEThcDHMSn) > 0 And Not _currentDatasetType Like ''%%-HMSn%%''';
            End If;

        Else
            _newDatasetType := ' an HMS-based dataset type';
        End If;

        _requiredAction := 'AutoDefineDSType';
    End If;

    If _requiredAction = '' And
       (_scanCounts.ActualCountCIDMSn + _scanCounts.ActualCountETDMSn + _scanCounts.ActualCountHCDMSn + _scanCounts.ActualCountETciDMSn + _scanCounts.ActualCountEThcDMSn) > 0 And
       Not _currentDatasetType Like '%-MSn%' Then

        -- Dataset contains CID or ETD MSn spectra, but the current dataset type doesn't reflect that this is an MSn dataset
        If _currentDatasetType = 'IMS-HMS' Then
            _newDatasetType := 'IMS-HMS-MSn';
        ElsIf Not _currentDatasetType Like 'IMS%' Then
            _autoDefineDSType := true;

            If _infoOnly Then
                RAISE INFO 'Set _autoDefineDSType to true because (ActualCountCIDMSn + ActualCountETDMSn + ActualCountHCDMSn + ActualCountETciDMSn + ActualCountEThcDMSn) > 0 And Not _currentDatasetType Like ''%%-MSn%%''';
            End If;

        Else
            _newDatasetType := ' an MSn-based dataset type';
        End If;

        _requiredAction := 'AutoDefineDSType';
    End If;

    If _requiredAction = '' And (_scanCounts.ActualCountETDMSn + _scanCounts.ActualCountETDHMSn) > 0 And Not _currentDatasetType Like '%ETD%' Then

        -- Dataset has ETD scans, but current dataset type doesn't reflect this
        If Not _currentDatasetType Like 'IMS%' Then
            _autoDefineDSType := true;

            If _infoOnly Then
                RAISE INFO 'Set _autoDefineDSType to true because (ActualCountETDMSn + ActualCountETDHMSn) > 0 And Not _currentDatasetType Like ''%%ETD%%''';
            End If;

        Else
            _newDatasetType := ' an ETD-based dataset type';
        End If;

        _requiredAction := 'AutoDefineDSType';
    End If;

    If _requiredAction = '' And  _scanCounts.ActualCountHCDMSn + _scanCounts.ActualCountHCDHMSn > 0 And Not _currentDatasetType Like '%HCD%' Then

        -- Dataset has HCD scans, but current dataset type doesn't reflect this
        If Not _currentDatasetType Like 'IMS%' Then
            _autoDefineDSType := true;

            If _infoOnly Then
                RAISE INFO 'Set _autoDefineDSType to true because ActualCountHCDMSn + ActualCountHCDHMSn > 0 And Not _currentDatasetType Like ''%%HCD%%''';
            End If;

        Else
            _newDatasetType := ' an HCD-based dataset type';
        End If;

        _requiredAction := 'AutoDefineDSType';
    End If;

    If _requiredAction = '' And _scanCounts.ActualCountPQD > 0 And Not _currentDatasetType Like '%PQD%' Then
        -- Dataset has PQD scans, but current dataset type doesn't reflect this
        If Not _currentDatasetType Like 'IMS%' Then
            _autoDefineDSType := true;

            If _infoOnly Then
                RAISE INFO 'Set _autoDefineDSType to true because ActualCountPQD > 0 And Not _currentDatasetType Like ''%%PQD%%''';
            End If;

        Else
            _newDatasetType := ' a PQD-based dataset type';
        End If;

        _requiredAction := 'AutoDefineDSType';
    End If;

    If _requiredAction = '' And _scanCounts.ActualCountHCDMSn + _scanCounts.ActualCountHCDHMSn = 0 And _currentDatasetType Like '%HCD%' Then
        -- Dataset does not have HCD scans, but current dataset type says it does
        If Not _currentDatasetType Like 'IMS%' Then
            _autoDefineDSType := true;

            If _infoOnly Then
                RAISE INFO 'Set _autoDefineDSType to true because ActualCountHCDMSn + ActualCountHCDHMSn = 0 And _currentDatasetType Like ''%%HCD%%''';
            End If;

        Else
            _warnMessage := format('Warning: Dataset type is %s but no HCD scans are present', _currentDatasetType);
        End If;

        _requiredAction := 'AutoDefineDSType';
    End If;

    If _requiredAction = '' And (_scanCounts.ActualCountETDMSn + _scanCounts.ActualCountETDHMSn) = 0 And _currentDatasetType Like '%ETD%' Then
        -- Dataset does not have ETD scans, but current dataset type says it does
        If Not _currentDatasetType Like 'IMS%' Then
            _autoDefineDSType := true;

            If _infoOnly Then
                RAISE INFO 'Set _autoDefineDSType to true because (ActualCountETDMSn + ActualCountETDHMSn) = 0 And _currentDatasetType Like ''%%ETD%%''';
            End If;

        Else
            _warnMessage := format('Warning: Dataset type is %s but no ETD scans are present', _currentDatasetType);
        End If;

        _requiredAction := 'AutoDefineDSType';
    End If;

    If _requiredAction = '' And _scanCounts.ActualCountAnyMSn > 0 And Not _currentDatasetType Like '%-MSn%' Then
        -- Dataset contains MSn spectra, but the current dataset type doesn't reflect that this is an MSn dataset
        If _currentDatasetType = 'IMS-HMS' Then
            _newDatasetType := 'IMS-HMS-MSn';
        ElsIf Not _currentDatasetType Like 'IMS%' Then
            _autoDefineDSType := true;

            If _infoOnly Then
                RAISE INFO 'Set _autoDefineDSType to true because ActualCountAnyMSn > 0 And Not _currentDatasetType Like ''%%-MSn%%''';
            End If;

        Else
            _newDatasetType := ' an MSn-based dataset type';
        End If;

        _requiredAction := 'AutoDefineDSType';
    End If;

    If _requiredAction = '' And (_scanCounts.ActualCountCIDHMSn + _scanCounts.ActualCountETDHMSn + _scanCounts.ActualCountHCDHMSn + _scanCounts.ActualCountETciDHMSn + _scanCounts.ActualCountEThcDHMSn) = 0 And _currentDatasetType Like '%-HMSn%' Then
        -- Dataset does not have HMSn scans, but current dataset type says it does
        If Not _currentDatasetType Like 'IMS%' Then
            _autoDefineDSType := true;

            If _infoOnly Then
                RAISE INFO 'Set _autoDefineDSType to true because (ActualCountCIDHMSn + ActualCountETDHMSn + ActualCountHCDHMSn + ActualCountETciDHMSn + ActualCountEThcDHMSn) = 0 And _currentDatasetType Like ''%%-HMSn%%''';
            End If;

        Else
            _warnMessage := format('Warning: Dataset type is %s but no high res MSn scans are present', _currentDatasetType);
        End If;

        _requiredAction := 'AutoDefineDSType';
    End If;

    If _requiredAction = '' And (_scanCounts.ActualCountCIDMSn + _scanCounts.ActualCountETDMSn + _scanCounts.ActualCountHCDMSn + _scanCounts.ActualCountETciDMSn + _scanCounts.ActualCountEThcDMSn) = 0 And _currentDatasetType Like '%-MSn%' Then
        -- Dataset does not have MSn scans, but current dataset type says it does
        If Not _currentDatasetType Like 'IMS%' Then
            _autoDefineDSType := true;

            If _infoOnly Then
                RAISE INFO 'Set _autoDefineDSType to true because (ActualCountCIDMSn + ActualCountETDMSn + ActualCountHCDMSn + ActualCountETciDMSn + ActualCountEThcDMSn) = 0 And _currentDatasetType Like ''%%-MSn%%''';
            End If;

        Else
            _warnMessage := format('Warning: Dataset type is %s but no low res MSn scans are present', _currentDatasetType);
        End If;

        _requiredAction := 'AutoDefineDSType';
    End If;

    If _requiredAction = '' And _scanCounts.ActualCountHMS = 0 And (_currentDatasetType Like 'HMS%' Or _currentDatasetType Like '%-HMS') Then
        -- Dataset does not have HMS scans, but current dataset type says it does
        If Not _currentDatasetType Like 'IMS%' Then
            _autoDefineDSType := true;

            If _infoOnly Then
                RAISE INFO 'Set _autoDefineDSType to true because ActualCountHMS = 0 And (_currentDatasetType Like ''HMS%%'' Or _currentDatasetType Like ''%%-HMS'')';
            End If;

        Else
            _warnMessage := format('Warning: Dataset type is %s but no HMS scans are present', _currentDatasetType);
        End If;

        _requiredAction := 'AutoDefineDSType';
    End If;

    If _requiredAction = '' And _scanCounts.ActualCountAnyHMSn > 0 And Not _currentDatasetType Like '%-HMSn%' Then
        -- Dataset contains HMSn spectra, but the current dataset type doesn't reflect that this is an HMSn dataset
        If _currentDatasetType = 'IMS-HMS' Then
            _newDatasetType := 'IMS-HMS-HMSn';
        ElsIf Not _currentDatasetType Like 'IMS%' Then
            _autoDefineDSType := true;

            If _infoOnly Then
                RAISE INFO 'Set _autoDefineDSType to true because ActualCountAnyHMSn > 0 And Not _currentDatasetType Like ''%%-HMSn%%''';
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

        If Not _currentDatasetType Like 'IMS%' And Not _currentDatasetType In ('MALDI-HMS', 'C60-SIMS-HMS') Then
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

            If _scanCounts.ActualCountHMS > 0 Then
                _datasetTypeAutoGen := 'HMS';
            Else
                _datasetTypeAutoGen := 'MS';

                If _scanCounts.ActualCountMS = 0 And (_scanCounts.ActualCountCIDHMSn + _scanCounts.ActualCountETDHMSn + _scanCounts.ActualCountHCDHMSn + _scanCounts.ActualCountETciDHMSn + _scanCounts.ActualCountEThcDHMSn + _scanCounts.ActualCountAnyHMSn) > 0 Then
                    -- Dataset only has fragmentation spectra and no MS1 spectra
                    -- Since all of the fragmentation spectra are high res, use 'HMS'
                    _datasetTypeAutoGen := 'HMS';
                End If;

                If _scanCounts.ActualCountGCMS > 0 Then
                    _datasetTypeAutoGen := 'GC-MS';
                End If;
            End If;

            If (_scanCounts.ActualCountETciDMSn + _scanCounts.ActualCountEThcDMSn + _scanCounts.ActualCountETciDHMSn + _scanCounts.ActualCountEThcDHMSn) > 0 Then
                -- Has ETciD or EThcD spectra

                If (_scanCounts.ActualCountETciDMSn + _scanCounts.ActualCountETciDHMSn) > 0 And (_scanCounts.ActualCountEThcDMSn + _scanCounts.ActualCountEThcDHMSn) > 0 Then
                    _datasetTypeAutoGen := _datasetTypeAutoGen || '-ETciD-EThcD';
                Else

                    If (_scanCounts.ActualCountETciDMSn + _scanCounts.ActualCountETciDHMSn) > 0 Then
                        _datasetTypeAutoGen := _datasetTypeAutoGen || '-ETciD';
                    End If;

                    If (_scanCounts.ActualCountEThcDMSn + _scanCounts.ActualCountEThcDHMSn) > 0 Then
                        _datasetTypeAutoGen := _datasetTypeAutoGen || '-EThcD';
                    End If;

                End If;

                If (_scanCounts.ActualCountETciDHMSn + _scanCounts.ActualCountEThcDHMSn) > 0 Then
                    _datasetTypeAutoGen := _datasetTypeAutoGen || '-HMSn';
                Else
                    _datasetTypeAutoGen := _datasetTypeAutoGen || '-MSn';
                End If;

            Else
                -- No ETciD or EThcD spectra

                If _scanCounts.ActualCountHCDMSn + _scanCounts.ActualCountHCDHMSn > 0 Then
                    _datasetTypeAutoGen := _datasetTypeAutoGen || '-HCD';
                End If;

                If _scanCounts.ActualCountPQD > 0 Then
                    _datasetTypeAutoGen := _datasetTypeAutoGen || '-PQD';
                End If;

                If (_scanCounts.ActualCountCIDHMSn + _scanCounts.ActualCountETDHMSn + _scanCounts.ActualCountHCDHMSn) > 0 Then
                    -- One or more High res CID, ETD, or HCD MSn spectra
                    If (_scanCounts.ActualCountETDMSn + _scanCounts.ActualCountETDHMSn) > 0 Then
                        -- One or more ETD spectra
                        If _scanCounts.ActualCountCIDHMSn > 0 Then
                            _datasetTypeAutoGen := _datasetTypeAutoGen || '-CID/ETD-HMSn';
                        ElsIf _scanCounts.ActualCountCIDMSn > 0 Then
                            _datasetTypeAutoGen := _datasetTypeAutoGen || '-CID/ETD-MSn';
                        ElsIf _scanCounts.ActualCountETDHMSn > 0 Then
                            _datasetTypeAutoGen := _datasetTypeAutoGen || '-ETD-HMSn';
                        Else
                            _datasetTypeAutoGen := _datasetTypeAutoGen || '-ETD-MSn';
                        End If;
                    Else
                        -- No ETD spectra
                        If _scanCounts.ActualCountCIDHMSn > 0 Then
                             _datasetTypeAutoGen := _datasetTypeAutoGen || '-CID-HMSn';
                        ElsIf _scanCounts.ActualCountCIDMSn > 0 OR _scanCounts.ActualCountPQD > 0 Then
                            _datasetTypeAutoGen := _datasetTypeAutoGen || '-CID-MSn';
                        Else
                            _datasetTypeAutoGen := _datasetTypeAutoGen || '-HMSn';
                        End If;
                    End If;
                Else
                    -- No high res MSn spectra

                    If (_scanCounts.ActualCountCIDMSn + _scanCounts.ActualCountETDMSn + _scanCounts.ActualCountHCDMSn) > 0 Then
                        -- One or more Low res CID, ETD, or HCD MSn spectra
                        If (_scanCounts.ActualCountETDMSn) > 0 Then
                            -- One or more ETD spectra
                            If _scanCounts.ActualCountCIDMSn > 0 Then
                                _datasetTypeAutoGen := _datasetTypeAutoGen || '-CID/ETD';
                            Else
                                _datasetTypeAutoGen := _datasetTypeAutoGen || '-ETD';
                            End If;
                        Else
                            -- No ETD spectra
                            If _scanCounts.ActualCountCIDMSn > 0 Or _scanCounts.ActualCountPQD > 0 Then
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
                    If _scanCounts.ActualCountHCDMSn > 0 And _scanCounts.ActualCountHCDHMSn = 0 Then
                        _datasetTypeAutoGen := 'HMS-HCD-MSn';
                    Else
                        _datasetTypeAutoGen := 'HMS-HCD-HMSn';
                    End If;
                End If;

                If _datasetTypeAutoGen = 'HMS-CID-MSn' Then
                    _datasetTypeAutoGen := 'HMS-MSn';
                End If;

                If _datasetTypeAutoGen = 'HMS-CID-HMSn' Then
                    _datasetTypeAutoGen := 'HMS-HMSn';
                End If;

                If _scanCounts.ActualCountDIA > 0 Then
                    _datasetTypeAutoGen := format('DIA-%s', _datasetTypeAutoGen);
                End If;

            End If;

        End If;

        If _datasetTypeAutoGen <> '' And _autoDefineOnAllMismatches Then
            _autoDefineDSType := true;

            If _infoOnly Then
                RAISE INFO 'Set _autoDefineDSType to true because _datasetTypeAutoGen <> '''' (it is %) and _autoDefineOnAllMismatches is true', _datasetTypeAutoGen;
            End If;

        End If;

        If _autoDefineDSType Then
            If _datasetTypeAutoGen <> _currentDatasetType And _datasetTypeAutoGen <> '' Then
                _newDatasetType := _datasetTypeAutoGen;
            End If;
        Else
            If _newDatasetType = '' And _warnMessage = '' Then
                If _datasetTypeAutoGen <> _currentDatasetType And _datasetTypeAutoGen <> '' Then
                    _warnMessage := format('Warning: Dataset type is %s while auto-generated type is %s', _currentDatasetType, _datasetTypeAutoGen);
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

    If _warnMessage <> '' And Not (_currentDatasetType Like 'IMS%' and _datasetTypeAutoGen Like 'IMS%') Then
        _message := _warnMessage;

        RAISE WARNING '% (%)', _message, _dataset;
        RETURN;
    End If;

    -----------------------------------------------------------
    -- If a new dataset type is defined, update _newDSTypeID
    -----------------------------------------------------------

    If _newDatasetType <> '' Then
        _newDSTypeID := 0;

        SELECT dataset_type_id
        INTO _newDSTypeID
        FROM t_dataset_type_name
        WHERE Dataset_Type = _newDatasetType;

        If Not FOUND Then
            _message := format('Unrecognized dataset type based on actual scan types; need to auto-switch from %s to %s', _currentDatasetType, _newDatasetType);

            If Not _infoOnly Then
                _logMessage := format('%s for dataset ID %s (%s)', _message, _datasetID, _dataset);
                CALL post_log_entry ('Error', _logMessage, 'validate_dataset_type', _duplicateEntryHoldoffHours => 1);
            End If;
        Else
            If _newDatasetType = 'HMS' And _currentDatasetType = 'EI-HMS' Then
                -- Leave the dataset type as 'EI-HMS'
                If _infoOnly Then
                    _message := format('Leaving dataset type unchanged as %s', _currentDatasetType);
                    RAISE INFO '%', _message;
                End If;
                RETURN;
            End If;

            _message := format('%s dataset type from %s to %s',
                               CASE WHEN _infoOnly
                                    THEN 'Would auto-switch'
                                    ELSE 'Auto-switched'
                               END,
                               _currentDatasetType,
                               _newDatasetType);

            If Not _infoOnly Then
                UPDATE t_dataset
                SET dataset_type_ID = _newDSTypeID
                WHERE dataset_id = _datasetID;
            Else
                RAISE INFO 'New dataset type: % (dataset type ID %)', _newDatasetType, _newDSTypeID;
            End If;
        End If;
    End If;

    If _infoOnly Then
        If Coalesce(_message, '') = '' Then
            _message := format('Dataset type is valid: %s', _currentDatasetType);
        End If;

        RAISE INFO '%', _message;
        RAISE INFO 'Dataset: %', _dataset;
    End If;

END
$$;


ALTER PROCEDURE public.validate_dataset_type(IN _datasetid integer, INOUT _message text, INOUT _returncode text, IN _infoonly boolean, IN _autodefineonallmismatches boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE validate_dataset_type(IN _datasetid integer, INOUT _message text, INOUT _returncode text, IN _infoonly boolean, IN _autodefineonallmismatches boolean); Type: COMMENT; Schema: public; Owner: d3l243
--

COMMENT ON PROCEDURE public.validate_dataset_type(IN _datasetid integer, INOUT _message text, INOUT _returncode text, IN _infoonly boolean, IN _autodefineonallmismatches boolean) IS 'ValidateDatasetType';

