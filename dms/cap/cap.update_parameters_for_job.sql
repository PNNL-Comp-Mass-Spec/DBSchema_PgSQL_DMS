--
-- Name: update_parameters_for_job(text, text, text, boolean); Type: PROCEDURE; Schema: cap; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE cap.update_parameters_for_job(IN _joblist text, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _infoonly boolean DEFAULT false)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Update parameters for one or more capture task jobs (using values from tables in the public schema)
**
**      Updates Storage_Server, Instrument, Instrument_Class, etc. in table cap.t_tasks
**      Re-generates the capture task job parameters, storing in table cap.t_task_parameters
**
**  Arguments:
**    _jobList      Comma separated list of capture task jobs to update
**    _infoOnly     When true, show updated values in cap.t_tasks and show the new job parameters
**
**  Auth:   grk
**  Date:   12/16/2009 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          01/14/2010 grk - removed path ID fields
**          01/28/2010 grk - modified to use create_parameters_for_job, and to take list of capture task jobs
**          04/13/2010 mem - Fixed bug that didn't properly update T_task_Parameters when Tmp_Job_Parameters contains multiple capture task jobs (because _jobList contained multiple capture task jobs)
**                         - Added support for capture task jobs being present in T_Tasks but not present in T_task_Parameters
**          05/18/2011 mem - Updated _jobList to varchar(max)
**          09/17/2012 mem - Now updating Storage_Server in T_Tasks if it differs from V_DMS_Dataset_Metadata
**          08/27/2013 mem - Now updating 4 fields in T_Tasks if they are null (which will be the case if a capture task job was copied from T_Tasks_History to T_Tasks yet the job had no parameters in T_task_Parameters_History)
**          05/29/2015 mem - Add support for column Capture_Subfolder
**          06/01/2015 mem - Changed update logic for Capture_Subfolder to pull from cap.V_DMS_Get_Dataset_Definition _unless_ the value in V_DMS_Get_Dataset_Definition is null
**          03/24/2016 mem - Switch to using udfParseDelimitedIntegerList to parse the list of capture task jobs
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW instead of RAISERROR
**          01/30/2018 mem - Always update instrument settings using data in DMS (Storage_Server, Instrument, Instrument_Class, Max_Simultaneous_Captures, Capture_Subfolder)
**          05/17/2019 mem - Switch from folder to directory
**          08/31/2022 mem - Rename view V_DMS_Capture_Job_Parameters to V_DMS_Dataset_Metadata
**          10/08/2022 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _schemaName text;
    _nameWithSchema text;
    _authorized bool;

    _jobInfo record;
    _xmlParameters xml;

    _formatSpecifier text;
    _infoHead text;
    _infoHeadSeparator text;
    _infoData text;
    _previewData record;

    _sqlState text;
    _exceptionMessage text;
    _exceptionDetail text;
    _exceptionContext text;
BEGIN

    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, name_with_schema
    INTO _schemaName, _nameWithSchema
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_nameWithSchema, _schemaName, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    BEGIN

        -----------------------------------------------------------
        -- Parse the capture task job list
        -----------------------------------------------------------

        CREATE TEMP TABLE Tmp_Job_List (
            Job int
        );

        INSERT INTO Tmp_Job_List (Job)
        SELECT Value
        FROM public.parse_delimited_integer_list(_jobList, ',')
        ORDER BY Value;

        -- Update values in T_Tasks

        If _infoOnly Then

            RAISE INFO ' ';

            _formatSpecifier := '%-10s %-20s %-20s %-20s %-20s %-50s %-50s';

            _infoHead := format(_formatSpecifier,
                                'Job',
                                'Storage_Server',
                                'Instrument',
                                'Instrument_Class',
                                'Max_Simultaneous_Cap',
                                'Dataset',
                                'Capture_Subfolder'

                            );

            _infoHeadSeparator := format(_formatSpecifier,
                                '----------',
                                '--------------------',
                                '--------------------',
                                '--------------------',
                                '--------------------',
                                '--------------------------------------------------',
                                '--------------------------------------------------'
                            );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT Target.Job,
                       Coalesce(VDD.Storage_Server_Name, Target.Storage_Server) AS StorageServer,
                       Coalesce(VDD.Instrument_Name, Target.Instrument) AS Instrument,
                       Coalesce(VDD.Instrument_Class, Target.Instrument_Class) AS InstrumentClass,
                       Coalesce(VDD.Max_Simultaneous_Captures, Target.Max_Simultaneous_Captures) AS MaxSimultaneousCaptures,
                       Target.Dataset,
                       Coalesce(VDD.Capture_Subfolder, Target.Capture_Subfolder) AS CaptureSubfolder
                FROM cap.t_tasks Target INNER JOIN
                     Tmp_Job_List AS JL ON Target.Job = JL.Job INNER JOIN
                     cap.V_DMS_Get_Dataset_Definition AS VDD ON Target.Dataset_ID = VDD.Dataset_ID
                ORDER BY Target.job

            LOOP
                _infoData := format(_formatSpecifier,
                                        _previewData.Job,
                                        _previewData.StorageServer,
                                        _previewData.Instrument,
                                        _previewData.InstrumentClass,
                                        _previewData.MaxSimultaneousCaptures,
                                        _previewData.Dataset,
                                        _previewData.CaptureSubfolder
                                );

                RAISE INFO '%', _infoData;

            END LOOP;

        Else

            UPDATE cap.t_tasks Target
            SET Storage_Server = Coalesce(VDD.Storage_Server_Name, Target.Storage_Server),
                Instrument = Coalesce(VDD.Instrument_Name, Target.Instrument),
                Instrument_Class = Coalesce(VDD.Instrument_Class, Target.Instrument_Class),
                Max_Simultaneous_Captures = Coalesce(VDD.Max_Simultaneous_Captures, Target.Max_Simultaneous_Captures),
                Capture_Subfolder = Coalesce(VDD.Capture_Subfolder, Target.Capture_Subfolder)
            FROM Tmp_Job_List AS JL, cap.V_DMS_Get_Dataset_Definition AS VDD
            WHERE Target.Job = JL.Job AND
                  Target.Dataset_ID = VDD.Dataset_ID;

        End If;

        ---------------------------------------------------
        -- Create temp table for capture task jobs that are being updated
        -- and populate it
        ---------------------------------------------------
        --
        CREATE TEMP TABLE Tmp_Jobs (
            Job int NOT NULL,
            Priority int NULL,
            Script text NULL,
            State int NOT NULL,
            Dataset text NULL,
            Dataset_ID int NULL,
            Results_Directory_Name text NULL,
            Storage_Server text NULL,
            Instrument text NULL,
            Instrument_Class text NULL,
            Max_Simultaneous_Captures int NULL,
            Capture_Subdirectory text NULL
        );
        --
        INSERT INTO Tmp_Jobs (
            Job,
            Priority,
            Script,
            State,
            Dataset,
            Dataset_ID,
            Results_Directory_Name,
            Storage_Server,
            Instrument,
            Instrument_Class,
            Max_Simultaneous_Captures,
            Capture_Subdirectory
        )
        SELECT J.Job,
               J.Priority,
               J.Script,
               J.State,
               J.Dataset,
               J.Dataset_ID,
               J.Results_Folder_Name,
               J.Storage_Server,
               J.Instrument,
               J.Instrument_Class,
               J.Max_Simultaneous_Captures,
               J.Capture_Subfolder
        FROM cap.t_tasks J
             INNER JOIN Tmp_Job_List
               ON J.Job = Tmp_Job_List.Job;

        ---------------------------------------------------
        -- Temp table to accumulate XML parameters for
        -- capture task jobs in list
        ---------------------------------------------------
        --
        CREATE TEMP TABLE Tmp_Job_Parameters (
            Job int NOT NULL,
            Parameters xml NULL
        );

        ---------------------------------------------------
        -- Loop through capture task jobs and accumulate parameters
        -- into temp table
        ---------------------------------------------------
        --

        FOR _jobInfo IN
            SELECT Job,
                   Dataset,
                   Dataset_ID AS DatasetID,
                   Script,
                   Storage_Server As StorageServer,
                   Instrument,
                   Instrument_Class as InstrumentClass,
                   Max_Simultaneous_Captures As MaxSimultaneousCaptures,
                   Capture_Subdirectory AS CaptureSubdirectory
            FROM Tmp_Jobs
            ORDER BY Job
        LOOP
            -- Get parameters for the capture task job as XML
            --
            _xmlParameters := cap.create_parameters_for_job (
                                    _jobInfo.Job, _jobInfo.Dataset, _jobInfo.DatasetID,
                                    _jobInfo.Script, _jobInfo.StorageServer,
                                    _jobInfo.Instrument, _jobInfo.InstrumentClass,
                                    _jobInfo.MaxSimultaneousCaptures, _jobInfo.CaptureSubdirectory);

            -- Store the parameters
            INSERT INTO Tmp_Job_Parameters (Job, Parameters)
            VALUES (_jobInfo.Job, _xmlParameters);

        END LOOP;

        ---------------------------------------------------
        -- Replace params in T_task_Parameters (or output debug messages)
        ---------------------------------------------------
        --
        If _infoOnly Then

            RAISE INFO ' ';

            _formatSpecifier := '%-10s %-50s';

            _infoHead := format(_formatSpecifier,
                                'Job',
                                'Parameters'
                            );

            _infoHeadSeparator := format(_formatSpecifier,
                                '----------',
                                '--------------------------------------------------'
                            );

            RAISE INFO '%', _infoHead;
            RAISE INFO '%', _infoHeadSeparator;

            FOR _previewData IN
                SELECT Job,
                       Parameters::text AS Params
                FROM Tmp_Job_Parameters
                ORDER BY Job
            LOOP
                _infoData := format(_formatSpecifier,
                                        _previewData.Job,
                                        _previewData.Params
                                );

                RAISE INFO '%', _infoData;

            END LOOP;

        Else
            -- Update existing capture task jobs in T_task_Parameters
            --
            UPDATE cap.t_task_parameters Target
            SET Parameters = Source.Parameters
            FROM Tmp_Job_Parameters Source
            WHERE Target.Job = Source.Job;

            -- Add any missing capture task jobs
            --
            INSERT INTO cap.t_task_parameters( job,
                                               parameters )
            SELECT Source.Job,
                   Source.Parameters
            FROM Tmp_Job_Parameters Source
                 LEFT OUTER JOIN cap.t_task_parameters
                   ON Source.Job = cap.t_task_parameters.Job
            WHERE cap.t_task_parameters.Job IS NULL;

        End If;

        DROP TABLE Tmp_Job_List;
        DROP TABLE Tmp_Jobs;
        DROP TABLE Tmp_Job_Parameters;

    EXCEPTION
      WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS
                _sqlState         = returned_sqlstate,
                _exceptionMessage = message_text,
                _exceptionDetail  = pg_exception_detail,
                _exceptionContext = pg_exception_context;

        _message := local_error_handler (
                        _sqlState, _exceptionMessage, _exceptionDetail, _exceptionContext,
                        _callingProcLocation => '', _logError => false);

        If Coalesce(_returnCode, '') = '' Then
            _returnCode := _sqlState;
        End If;

        DROP TABLE IF EXISTS Tmp_Job_List;
        DROP TABLE IF EXISTS Tmp_Jobs;
        DROP TABLE IF EXISTS Tmp_Job_Parameters;

    END;
END
$$;


ALTER PROCEDURE cap.update_parameters_for_job(IN _joblist text, INOUT _message text, INOUT _returncode text, IN _infoonly boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE update_parameters_for_job(IN _joblist text, INOUT _message text, INOUT _returncode text, IN _infoonly boolean); Type: COMMENT; Schema: cap; Owner: d3l243
--

COMMENT ON PROCEDURE cap.update_parameters_for_job(IN _joblist text, INOUT _message text, INOUT _returncode text, IN _infoonly boolean) IS 'UpdateParametersForJob';

