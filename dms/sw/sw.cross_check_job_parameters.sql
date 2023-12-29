--
-- Name: cross_check_job_parameters(integer, text, text, boolean); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.cross_check_job_parameters(IN _job integer, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text, IN _ignoresignaturemismatch boolean DEFAULT true)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Compare the data in Tmp_Job_Steps to existing data in T_Job_Steps to look for incompatibilities
**      This procedure is only used if procedure sw.create_job_steps() is called with Mode 'ExtendExistingJob' Or 'UpdateExistingJob'
**
**      See procedure sw.create_job_steps() for the table definition of Tmp_Job_Steps
**
**  Arguments:
**    _job                          Job number
**    _message                      Status message
**    _returnCode                   Return code
**    _ignoreSignatureMismatch      When true, ignore differences in the signature column; sw.create_job_steps() always sets this to true
**
**  Auth:   grk
**  Date:   02/03/2009 grk - Initial release  (http://prismtrac.pnl.gov/trac/ticket/720)
**          03/11/2009 mem - Now including Old/New step tool and Old/New Signatures if differences are found (Ticket #725, http://prismtrac.pnl.gov/trac/ticket/725)
**          01/06/2011 mem - Added parameter _ignoreSignatureMismatch
**          07/31/2023 mem - Ported to PostgreSQL
**          09/08/2023 mem - Adjust capitalization of keywords
**
*****************************************************/
DECLARE
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Cross-check steps against parameter effects
    ---------------------------------------------------

    SELECT string_agg(
        CASE WHEN Not OJS.Shared_Result_Version IS DISTINCT FROM NJS.Shared_Result_Version THEN ''
             ELSE format(' step %s Shared_Result_Version (%s|%s);', OJS.Step, Coalesce(OJS.Shared_Result_Version::text, '<Null>'), Coalesce(NJS.Shared_Result_Version::text, '<Null>'))
        END ||

        CASE WHEN Not OJS.Tool IS DISTINCT FROM NJS.Tool THEN ''
             ELSE format(' step %s Tool (%s|%s);', OJS.Step, Coalesce(OJS.Tool, '<Null>'), Coalesce(NJS.Tool, '<Null>'))
        END ||

        CASE WHEN (Not OJS.Signature IS DISTINCT FROM NJS.Signature) OR _ignoreSignatureMismatch THEN ''
             ELSE format(' step %s Signature (%s|%s);', OJS.Step, Coalesce(OJS.Signature::text, '<Null>'), Coalesce(NJS.Signature::text, '<Null>'))
        END

        -- || CASE WHEN Not OJS.Output_Folder_Name IS DISTINCT FROM NJS.Output_Directory_Name THEN ''
        --         ELSE format(' step %s Output_Folder_Name (%s|%s);', OJS.Step, Coalesce(OJS.Output_Folder_Name, '<blank>'), Coalesce(NJS.Output_Directory_Name, '<blank>'))
        --    END

        , '; ' ORDER BY OJS.Step)     -- Use a semicolon as the delimiter for string_agg()

    INTO _message
    FROM sw.t_job_steps OJS
         INNER JOIN Tmp_Job_Steps NJS
           ON OJS.job = NJS.job AND
              OJS.step = NJS.step
    WHERE OJS.Job = _job AND
          ( Not OJS.signature Is Null OR
            Not NJS.signature Is Null
          );

    _message := Trim(Replace(Coalesce(_message, ''), ';;', ';'));

    If _message = '' Then
        _message := '';
    ElsIf _message = ';' Then
        _message := '';
    End If;

    If _message <> '' Then
        _message := format('Parameter mismatch for job %s: %s', _job, _message);
        _returnCode := 'U5499';
    End If;

END
$$;


ALTER PROCEDURE sw.cross_check_job_parameters(IN _job integer, INOUT _message text, INOUT _returncode text, IN _ignoresignaturemismatch boolean) OWNER TO d3l243;

--
-- Name: PROCEDURE cross_check_job_parameters(IN _job integer, INOUT _message text, INOUT _returncode text, IN _ignoresignaturemismatch boolean); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.cross_check_job_parameters(IN _job integer, INOUT _message text, INOUT _returncode text, IN _ignoresignaturemismatch boolean) IS 'CrossCheckJobParameters';

