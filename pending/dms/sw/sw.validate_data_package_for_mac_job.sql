--
CREATE OR REPLACE PROCEDURE sw.validate_data_package_for_mac_job
(
    _dataPackageID int,
    _scriptName citext,
    INOUT _tool text,
    _mode text = 'add',
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Verify configuration and contents of a data package suitable for running a given MAC job from job template
**
**  Auth:   grk
**  Date:   10/29/2012 grk - Initial release
**          11/01/2012 grk - eliminated job template
**          01/31/2013 mem - Renamed MSGFDB to MSGFPlus
**                         - Updated error messages shown to user
**          02/13/2013 mem - Fix misspelled word
**          02/18/2013 mem - Fix misspelled word
**          08/13/2013 mem - Now validating required analysis tools for the MAC_iTRAQ script
**          08/14/2013 mem - Now validating datasets and jobs for script Global_Label-Free_AMT_Tag
**          04/20/2014 mem - Now mentioning ReporterTol param file when MASIC counts are not correct for an Isobaric_Labeling or MAC_iTRAQ script
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          11/15/2017 mem - Use AppendToText to combine strings
**                         - Include data package ID in log messages
**          01/11/2018 mem - Allow PRIDE_Converter jobs to have multiple MSGF+ jobs for each dataset
**          04/06/2018 mem - Allow Phospho_FDR_Aggregator jobs to have multiple MSGF+ jobs for each dataset
**          06/12/2018 mem - Send _maxLength to AppendToText
**          05/01/2019 mem - Fix typo counting SEQUEST jobs
**          03/09/2021 mem - Add support for MaxQuant
**          08/26/2021 mem - Add support for MSFragger
**          10/02/2021 mem - No longer require that DeconTools jobs exist for MAC_iTRAQ jobs (similarly, MAC_TMT10Plex jobs don't need DeconTools)
**          06/30/2022 mem - Use new parameter file column name
**          12/07/2022 mem - Include script name in the error message
**          03/27/2023 mem - Add support for DiaNN
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _myRowCount int := 0;
BEGIN

    _dataPackageID := Coalesce(_dataPackageID, 0);
    _tool := '';

    BEGIN
        ---------------------------------------------------
        -- Create table to hold data package datasets
        -- and job counts
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_DataPackageItems (
              Dataset_ID int,
              Dataset text,
              Decon2LS_V2 int NULL,
              MASIC int NULL,
              MSGFPlus int NULL,
              SEQUEST int NULL
            )

        ---------------------------------------------------
        -- Populate with package datasets
        ---------------------------------------------------

        INSERT INTO Tmp_DataPackageItems( Dataset_ID,
                                           Dataset )
        SELECT DISTINCT Dataset_ID,
                        Dataset
        FROM dpkg.t_data_package_datasets AS TPKG
        WHERE (TPKG.Data_Package_ID = _dataPackageID)

        ---------------------------------------------------
        -- Determine job counts per dataset for required tools
        ---------------------------------------------------

        UPDATE Tmp_DataPackageItems
        Set
            Decon2LS_V2 = TargetTable.Decon2LS_V2,
            MASIC = TargetTable.MASIC,
            MSGFPlus = TargetTable.MSGFPlus,
            SEQUEST = TargetTable.SEQUEST
        FROM Tmp_DataPackageItems INNER JOIN

        /********************************************************************************
        ** This UPDATE query includes the target table name in the FROM clause
        ** The WHERE clause needs to have a self join to the target table, for example:
        **   UPDATE Tmp_DataPackageItems
        **   SET ...
        **   FROM source
        **   WHERE source.id = Tmp_DataPackageItems.id;
        ********************************************************************************/

                               ToDo: Fix this query

        (
            SELECT
                TPKG.Dataset,
                SUM(CASE WHEN TPKG.Tool = 'Decon2LS_V2' THEN 1 ELSE 0 END) AS Decon2LS_V2,
                SUM(CASE WHEN TPKG.Tool = 'MASIC_Finnigan' AND TD.[Param File] LIKE '%ReporterTol%' THEN 1 ELSE 0 END) AS MASIC,
                SUM(CASE WHEN TPKG.Tool LIKE 'MSGFPlus%' THEN 1 ELSE 0 END) AS MSGFPlus,
                SUM(CASE WHEN TPKG.Tool LIKE 'SEQUEST%' THEN 1 ELSE 0 END) AS SEQUEST
            FROM    dpkg.T_Data_Package_Analysis_Jobs AS TPKG
                    INNER JOIN public.V_Source_Analysis_Job AS TD ON TPKG.Job = TD.Job
            WHERE   ( TPKG.Data_Package_ID = _dataPackageID )
            GROUP BY TPKG.Dataset
        ) TargetTable ON Tmp_DataPackageItems.Dataset = TargetTable.Dataset

        ---------------------------------------------------
        -- Assess job/tool coverage of datasets
        ---------------------------------------------------

        Declare
            _errMsg text = '',
            _datasetCount int,
            _deconToolsCountNotOne int,
            _masicCountNotOne int,
            _msgfPlusCountExactlyOne int,
            _msgfPlusCountNotOne int,
            _msgfPlusCountOneOrMore int,
            _sequestCountExactlyOne int,
            _sequestCountNotOne int,
            _sequestCountOneOrMore int

        SELECT COUNT(*)
        INTO _datasetCount
        FROM Tmp_DataPackageItems;

        SELECT COUNT(*)
        INTO _deconToolsCountNotOne
        FROM Tmp_DataPackageItems
        WHERE Decon2LS_V2 <> 1;

        SELECT COUNT(*)
        INTO _masicCountNotOne
        FROM Tmp_DataPackageItems
        WHERE MASIC <> 1;

        SELECT COUNT(*)
        INTO _msgfPlusCountExactlyOne
        FROM Tmp_DataPackageItems
        WHERE MSGFPlus = 1;

        SELECT COUNT(*)
        INTO _msgfPlusCountNotOne
        FROM Tmp_DataPackageItems
        WHERE MSGFPlus <> 1;

        SELECT COUNT(*)
        INTO _msgfPlusCountOneOrMore
        FROM Tmp_DataPackageItems
        WHERE MSGFPlus >= 1;

        SELECT COUNT(*)
        INTO _sequestCountExactlyOne
        FROM Tmp_DataPackageItems
        WHERE SEQUEST = 1;

        SELECT COUNT(*)
        INTO _sequestCountNotOne
        FROM Tmp_DataPackageItems
        WHERE SEQUEST <> 1;

        SELECT COUNT(*)
        INTO _sequestCountOneOrMore
        FROM Tmp_DataPackageItems
        WHERE SEQUEST >= 1;

        DROP TABLE Tmp_DataPackageItems;

        If _scriptName ILIKE ('MaxQuant%') Or _scriptName ILIKE ('MSFragger%') Or _scriptName ILIKE ('DiaNN%') Then
            If _datasetCount = 0 Then
                _errMsg := format('Data package currently does not have any datasets (script %s)', _scriptName);
            End If;
        End If;

        If Not _scriptName In ('Global_Label-Free_AMT_Tag') AND Not _scriptName ILIKE ('MaxQuant%') AND Not _scriptName ILIKE ('MSFragger%') AND Not _scriptName ILIKE ('DiaNN%') Then
            If _scriptName = 'PRIDE_Converter' Then
                If _msgfPlusCountOneOrMore > 0 Then
                    _tool := 'msgfplus';
                ElsIf _sequestCountOneOrMore > 0
                    _tool := 'sequest';
                End If;
            End If;

            If _tool = '' And _msgfPlusCountOneOrMore > 0 Then
                If _msgfPlusCountNotOne = 0 And _msgfPlusCountExactlyOne = _msgfPlusCountOneOrMore Then
                    _tool := 'msgfplus';
                Else
                    If _scriptName In ('Phospho_FDR_Aggregator') Then
                        -- Allow multiple MSGF+ jobs for each dataset;
                    End If;
                        _tool := 'msgfplus';
                    Else
                        _errMsg := format('Data package does not have exactly one MSGFPlus job for each dataset (%s invalid datasets); script %s',
                                            _msgfPlusCountNotOne, _scriptName;
                End If;
            End If;

            If _tool = '' And _sequestCountOneOrMore > 0 Then
                If _sequestCountNotOne = 0 And _sequestCountExactlyOne = _sequestCountOneOrMore Then
                    _tool := 'sequest';
                Else
                    If _scriptName In ('Phospho_FDR_Aggregator') Then
                        -- Allow multiple Sequest jobs for each dataset;
                    End If;
                        _tool := 'sequest';
                    Else
                        _errMsg := format('Data package does not have exactly one Sequest job for each dataset (%s invalid datasets); script %s',
                                            _sequestCountNotOne, _scriptName);
                End If;
            End If;

            If _tool = '' Then
                _errMsg := public.append_to_text(_errMsg,
                            format('Data package must have one or more MSGFPlus (or Sequest) jobs; error validating script %s' _scriptName),
                            0, '; ', 1024);
            End If;
        End If;

        ---------------------------------------------------
        -- Determine if job/tool coverage is acceptable for
        -- given job template
        ---------------------------------------------------

        If _scriptName IN ('Isobaric_Labeling') Then
            If _deconToolsCountNotOne > 0 Then
                _errMsg := public.append_to_text(_errMsg,
                            format('There must be exactly one Decon2LS_V2 job per dataset for script %s', scriptName), 0, '; ', 1024);
            End If;

            If _masicCountNotOne > 0 Then
                _errMsg := public.append_to_text(_errMsg,
                            format('There must be exactly one MASIC_Finnigan job per dataset (and that job must use a param file with ReporterTol in the name) for script %s', scriptName),
                            0, '; ', 1024);
            End If;
        End If;

        If _scriptName IN ('MAC_iTRAQ', 'MAC_TMT10Plex') Then
            If _masicCountNotOne > 0 Then
                _errMsg := public.append_to_text(_errMsg,
                            format('There must be exactly one MASIC_Finnigan job per dataset (and that job must use a param file with ReporterTol in the name) for script %s', scriptName),
                            0, '; ', 1024);
            End If;
        End If;

        If _scriptName IN ('Global_Label-Free_AMT_Tag') Then
            If _deconToolsCountNotOne > 0 Then
                _errMsg := public.append_to_text(_errMsg, format('There must be exactly one Decon2LS_V2 job per dataset for script %s', scriptName), 0, '; ', 1024);
            End If;
        End If;

        If _errMsg <> '' Then
            _errMsg := 'Data package ' || Cast(_dataPackageID as text) || ' is not configured correctly for this job: ' || _errMsg;
             RAISE EXCEPTION '%', _errMsg;
        End If;

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

    DROP TABLE Tmp_DataPackageItems;
END
$$;

COMMENT ON PROCEDURE sw.validate_data_package_for_mac_job IS 'ValidateDataPackageForMACJob';
