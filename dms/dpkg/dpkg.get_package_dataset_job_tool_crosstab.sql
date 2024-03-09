--
-- Name: get_package_dataset_job_tool_crosstab(integer, refcursor, text, text, text); Type: PROCEDURE; Schema: dpkg; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE dpkg.get_package_dataset_job_tool_crosstab(IN _datapackageid integer, INOUT _results refcursor DEFAULT '_results'::refcursor, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _callinguser text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $_$
/****************************************************
**
**  Desc:
**      Create a crosstab of data package datasets and anlysis tools,
**      listing the number of jobs for each tool (by dataset)
**
**  Arguments:
**    _dataPackageID        Data package ID
**    _results              Output: RefCursor for viewing the results
**    _message              Status message
**    _returnCode           Return code
**
**  Use this to view the data returned by the _results cursor
**  Note that this will result in an error if no matching items are found
**
**      BEGIN;
**          CALL dpkg.get_package_dataset_job_tool_crosstab(_dataPackageID => '3050');
**          FETCH ALL FROM _results;
**      END;
**
**  Alternatively, use an anonymous code block (though it cannot return query results; it can only store them in a table or display them with RAISE INFO)
**
**      DO
**      LANGUAGE plpgsql
**      $block$
**      DECLARE
**          _results refcursor := '_results'::refcursor;
**          _message text;
**          _returnCode text;
**          _currentRow record;
**      BEGIN
**          CALL dpkg.get_package_dataset_job_tool_crosstab (
**                      _dataPackageID => 3050,
**                      _results       => _results,
**                      _message       => _message,
**                      _returnCode    => _returnCode
**                );
**
**          RAISE INFO '';
**
**          If Exists (SELECT name FROM pg_cursors WHERE name = '_results') Then
**              RAISE INFO 'Cursor has data';
**
**              WHILE true
**              LOOP
**                  FETCH NEXT FROM _results
**                  INTO _currentRow;
**
**                  If Not FOUND Then
**                      EXIT;
**                  End If;
**
**                  RAISE INFO 'Dataset: %, Total Jobs: %, DeconTools Jobs: %, MASIC Jobs: %, MSGFPlus Jobs: %',
**                              _currentRow.Dataset,
**                              _currentRow.jobs,
**                              _currentRow."Decon2LS_V2",
**                              _currentRow."MASIC_Finnigan",
**                              _currentRow."MSGFPlus";
**              END LOOP;
**          Else
**              RAISE INFO 'Cursor is not open';
**          End If;
**      END
**      $block$;
**
**  Auth:   grk
**  Date:   05/26/2010 grk - Initial release
**          02/23/2016 mem - Add set XACT_ABORT on
**          05/18/2016 mem - Log errors to T_Log_Entries
**          10/26/2022 mem - Change column #id to lowercase
**          10/31/2022 mem - Use new column name id in the temp table
**          08/15/2023 mem - Ported to PostgreSQL
**          09/28/2023 mem - Obtain dataset names and analysis tool names from T_Dataset and T_Analysis_Tool
**
*****************************************************/
DECLARE
    _colName text := '';
    _sql text;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN
    _message := '';
    _returnCode := '';

    BEGIN

        ---------------------------------------------------
        -- Validate the data package ID
        ---------------------------------------------------

        _dataPackageID := Coalesce(_dataPackageID, 0);

        If Not Exists (SELECT data_pkg_id FROM dpkg.t_data_package WHERE data_pkg_id = _dataPackageID) Then
            _message := format('Data package ID %s not found in dpkg.t_data_package', _dataPackageID);
            RAISE WARNING '%', _message;
            RETURN;
        End If;

        ---------------------------------------------------
        -- Create temporary tables
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_Tools (
            Tool text
        );

        CREATE TEMP TABLE Tmp_Scratch  (
            Dataset text,
            Total int
        );

        DROP TABLE IF EXISTS Tmp_Datasets;

        CREATE TEMP TABLE Tmp_Datasets (
            Dataset text,
            Jobs int NULL,
            ID int
        );

        ---------------------------------------------------
        -- Get list of package datasets
        ---------------------------------------------------

        INSERT INTO Tmp_Datasets (Dataset, ID)
        SELECT DISTINCT DS.dataset,
                        DPD.data_pkg_id
        FROM dpkg.t_data_package_datasets DPD
        INNER JOIN public.t_dataset DS
               ON DPD.Dataset_ID = DS.Dataset_ID
        WHERE DPD.data_pkg_id = _dataPackageID;

        -- Update job counts
        UPDATE Tmp_Datasets
        SET Jobs = CountQ.Total
        FROM ( SELECT DS.dataset,
                      COUNT(DPJ.job) AS Total
               FROM dpkg.t_data_package_analysis_jobs DPJ
                    INNER JOIN public.t_analysis_Job AJ
                      ON AJ.job = DPJ.job
                    INNER JOIN public.t_dataset DS
                      ON AJ.dataset_id = DS.dataset_id
               WHERE DPJ.data_pkg_id = _dataPackageID
               GROUP BY DS.dataset
             ) CountQ
        WHERE CountQ.dataset = Tmp_Datasets.dataset;

        ---------------------------------------------------
        -- Get list of tools referenced by package jobs
        ---------------------------------------------------

        INSERT INTO Tmp_Tools (Tool)
        SELECT DISTINCT T.analysis_tool
        FROM dpkg.t_data_package_analysis_jobs DPJ
             INNER JOIN public.t_analysis_job AJ
               ON AJ.job = DPJ.job
             INNER JOIN public.t_analysis_tool T
               ON AJ.analysis_tool_id = T.analysis_tool_id
        WHERE DPJ.data_pkg_id = _dataPackageID;

        ---------------------------------------------------
        -- Add columns to temp dataset table for each tool
        -- and update it with package job count
        ---------------------------------------------------

        FOR _colName IN
            SELECT Tool
            FROM Tmp_Tools
            ORDER BY Tool
        LOOP

            _sql := format('ALTER TABLE Tmp_Datasets ADD COLUMN %I int NULL', _colName);
            EXECUTE _sql;

            TRUNCATE TABLE Tmp_Scratch;

            INSERT INTO Tmp_Scratch (Dataset, Total)
            SELECT DS.dataset,
                   COUNT(DPJ.job) AS total
            FROM dpkg.t_data_package_analysis_jobs DPJ
                 INNER JOIN public.t_analysis_job AJ
                   ON AJ.job = DPJ.job
                 INNER JOIN public.t_dataset DS
                   ON AJ.dataset_id = DS.dataset_ID
                 INNER JOIN public.t_analysis_tool T
                   ON AJ.analysis_tool_id = T.analysis_tool_id
            WHERE DPJ.data_pkg_id = _dataPackageID AND
                  T.analysis_tool = _colName
            GROUP BY DS.dataset;

            _sql := format('UPDATE Tmp_Datasets SET %I = TX.Total FROM Tmp_Scratch TX WHERE TX.Dataset = Tmp_Datasets.Dataset', _colName);
            EXECUTE _sql;

        END LOOP;

        -- Return the results using a cursor, since the number of columns can vary

        Open _results For
            SELECT *
            FROM Tmp_Datasets;

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

    -- Do not drop Tmp_Datasets since it is used by the cursor
    DROP TABLE IF EXISTS Tmp_Tools;
    DROP TABLE IF EXISTS Tmp_Scratch;
END
$_$;


ALTER PROCEDURE dpkg.get_package_dataset_job_tool_crosstab(IN _datapackageid integer, INOUT _results refcursor, INOUT _message text, INOUT _returncode text, IN _callinguser text) OWNER TO d3l243;

