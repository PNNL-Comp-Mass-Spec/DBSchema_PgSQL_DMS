--
CREATE OR REPLACE PROCEDURE sw.add_update_job_parameter_xml
(
    INOUT _xmlParameters XML,
    _section text,
    _paramName text,
    _value text,
    _deleteParam boolean = false,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _infoOnly boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Adds or updates an entry in the XML parameters in _xmlParameters
**      Alternatively, use _deleteParam = true to delete the given parameter
**
**  Arguments:
**    _xmlParameters          XML to update (Input/output parameter)
**    _section       Example: JobParameters
**    _paramName     Example: SourceJob
**    _value         value for parameter _paramName in section _section
**    _deleteParam   When false, adds/updates the given parameter; when true, deletes the parameter
**
**  Auth:   mem
**  Date:   01/19/2012 mem - Initial Version (refactored from Add_Update_Job_Parameter)
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          04/11/2022 mem - Expand Section and Name to varchar(128)
**                         - Expand _value to varchar(4000)
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _currentSchema text;
    _currentProcedure text;
    _authorized boolean;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    SELECT schema_name, object_name
    INTO _currentSchema, _currentProcedure
    FROM get_current_function_info('<auto>', _showDebug => false);

    SELECT authorized
    INTO _authorized
    FROM public.verify_sp_authorized(_currentProcedure, _currentSchema, _logError => true);

    If Not _authorized Then
        -- Commit changes to persist the message logged to public.t_log_entries
        COMMIT;

        _message := format('User %s cannot use procedure %s', CURRENT_USER, _nameWithSchema);
        RAISE EXCEPTION '%', _message;
    End If;

    ---------------------------------------------------
    -- Get job parameters into table format
    ---------------------------------------------------
    --
    CREATE TEMP TABLE Tmp_Job_Parameters (
        Section text,
        Name text,
        Value text
    );

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    _infoOnly := Coalesce(_infoOnly, false);

    ---------------------------------------------------
    -- Populate Tmp_Job_Parameters with the parameters
    ---------------------------------------------------
    --
    INSERT INTO Tmp_Job_Parameters
        (Section, Name, Value)
    SELECT XmlQ.section, XmlQ.name, XmlQ.value
    FROM (
        SELECT xmltable.*
        FROM ( SELECT ('<params>' || _xmlParameters::text || '</params>')::xml as rooted_xml
             ) Src,
             XMLTABLE('//params/Param'
                      PASSING Src.rooted_xml
                      COLUMNS section citext PATH '@Section',
                              name citext PATH '@Name',
                              value citext PATH '@Value')
         ) XmlQ;

    If _infoOnly Then

        -- ToDo: Update this to use RAISE INFO

        SELECT 'Before update' AS Note, *
        FROM Tmp_Job_Parameters
        ORDER BY Section
    End If;

    If Not _deleteParam Then
        ---------------------------------------------------
        -- Add/update the specified parameter
        -- First try an update
        ---------------------------------------------------
        --
        UPDATE Tmp_Job_Parameters
        SET VALUE = _value
        WHERE Section = _section AND
              Name = _paramName;

        If Not FOUND Then
            -- Match not found; Insert a new parameter
            INSERT INTO Tmp_Job_Parameters(Section, Name, Value)
            VALUES (_section, _paramName, _value);
        End If;
    Else
        ---------------------------------------------------
        -- Delete the specified parameter
        ---------------------------------------------------
        --
        DELETE FROM Tmp_Job_Parameters
        WHERE Section = _section AND
              Name = _paramName;
    End If;

    If _infoOnly Then

        -- ToDo: Update this to use RAISE INFO

        ---------------------------------------------------
        -- Preview the parameters
        ---------------------------------------------------
        --
        SELECT 'After update' AS Note, *
        FROM Tmp_Job_Parameters
        ORDER BY Section
    Else

        -- ToDo: update this to use XMLAGG(XMLELEMENT(
        --       Look for similar capture task code in cap.*

        SELECT ( SELECT Section, Name, Value
                 FROM Tmp_Job_Parameters Param
                 ORDER BY Section
                 FOR XML AUTO )
        INTO _xmlParameters;
    End If;

END
$$;

COMMENT ON PROCEDURE sw.add_update_job_parameter_xml IS 'AddUpdateJobParameterXML';
