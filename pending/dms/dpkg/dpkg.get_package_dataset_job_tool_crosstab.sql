--
CREATE OR REPLACE PROCEDURE dpkg.get_package_dataset_job_tool_crosstab
(
    _dataPackageID INT,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _callingUser text = ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Crosstab of data package datasets against job count per tool
**
**  Auth:   grk
**  Date:   05/26/2010 grk - Initial release
**          02/23/2016 mem - Add set XACT_ABORT on
**          05/18/2016 mem - Log errors to T_Log_Entries
**          10/26/2022 mem - Change column #id to lowercase
**          10/31/2022 mem - Use new column name id in the temp table
**          12/15/2023 mem - Ported to PostgreSQL
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
        -- Create temporary tables
        ---------------------------------------------------

        CREATE TEMP TABLE Tmp_Tools (
            tool text
        );

        CREATE TEMP TABLE Tmp_Scratch  (
            dataset text,
            total INT
        );

        CREATE TEMP TABLE Tmp_Datasets (
            dataset text,
            jobs INT NULL,
            id INT
        );

        ---------------------------------------------------
        -- Get list of package datasets
        ---------------------------------------------------

        INSERT INTO Tmp_Datasets( dataset,
                                  id )
        SELECT DISTINCT dataset,
                        _dataPackageID
        FROM dpkg.t_data_package_datasets
        WHERE data_pkg_id = _dataPackageID;

        -- Update job counts
        UPDATE Tmp_Datasets
        SET Jobs = TX.Total
        FROM (
                SELECT dataset,
                       COUNT(job) AS Total
                FROM dpkg.t_data_package_analysis_jobs
                WHERE data_pkg_id = _dataPackageID
                GROUP BY dataset
             ) CountQ
        WHERE ON CountQ.dataset = Tmp_Datasets.dataset;

        ---------------------------------------------------
        -- Get list of tools covered by package jobs
        ---------------------------------------------------

        INSERT INTO Tmp_Tools ( tool )
        SELECT DISTINCT tool
        FROM dpkg.t_data_package_analysis_jobs
        WHERE data_pkg_id = _dataPackageID;

        ---------------------------------------------------
        -- Add columns to temp dataset table for each tool
        -- and update it with package job count
        ---------------------------------------------------

        WHILE true
        LOOP

            SELECT Tool
            INTO _colName
            FROM Tmp_Tools
            LIMIT 1;

            If Not FOUND Then
                -- Break out of the while loop
                EXIT;
            End If;

            DELETE FROM Tmp_Tools WHERE Tool = _colName;

            _sql := format('ALTER TABLE Tmp_Datasets ADD %I INT NULL', _colName);
            EXEC(_sql);

            DELETE FROM Tmp_Scratch

            INSERT INTO Tmp_Scratch ( dataset, Total )
            SELECT dataset,
                   COUNT(job) AS Total
            FROM dpkg.t_data_package_analysis_jobs
            WHERE data_pkg_id = _dataPackageID AND
                  tool = _colName
            GROUP BY dataset;

            _sql := format('UPDATE Tmp_Datasets SET %I = TX.Total FROM Tmp_Datasets INNER JOIN Tmp_Scratch TX ON TX.Dataset = Tmp_Datasets.Dataset', _colName);
            EXEC(_sql)

        END LOOP;

        -- ToDo: Return the results using a cursor, since the number of columns can vary

        RETURN QUERY
        SELECT *
        FROM Tmp_Datasets

    EXCEPTION
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        If _logErrors Then
            _message := local_error_handler (
                            _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                            _callingProcLocation => '', _logError => true);
        Else
            _message := _exceptionMessage;
        End If;

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

    END;

    DROP TABLE IF EXISTS Tmp_Tools;
    DROP TABLE IF EXISTS Tmp_Scratch;
    DROP TABLE IF EXISTS Tmp_Datasets
END
$$;

COMMENT ON PROCEDURE dpkg.get_package_dataset_job_tool_crosstab IS 'GetPackageDatasetJobToolCrosstab';
