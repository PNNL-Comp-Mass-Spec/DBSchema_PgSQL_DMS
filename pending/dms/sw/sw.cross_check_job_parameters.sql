--
CREATE OR REPLACE PROCEDURE sw.cross_check_job_parameters
(
    _job int,
    INOUT _message text default '',
    INOUT _returnCode text default '',
    _ignoreSignatureMismatch boolean = false
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Compares the data in Tmp_Job_Steps to existing data in T_Job_Steps
**      to look for incompatibilities
**
**  Auth:   grk
**  Date:   02/03/2009 grk - Initial release  (http://prismtrac.pnl.gov/trac/ticket/720)
**          03/11/2009 mem - Now including Old/New step tool and Old/New Signatures if differences are found (Ticket #725, http://prismtrac.pnl.gov/trac/ticket/725)
**          01/06/2011 mem - Added parameter _ignoreSignatureMismatch
**          12/15/2023 mem - Ported to PostgreSQL
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
        CASE WHEN Not OJS.Shared_Result_Version Is Distinct From NJS.Shared_Result_Version THEN ''
             ELSE format(' step %s Shared_Result_Version (%s|%s);', OJS.Step, OJS.Shared_Result_Version, NJS.Shared_Result_Version)
        END ||

        CASE WHEN Not OJS.Tool Is Distinct From NJS.Tool THEN ''
             ELSE format(' step %s Tool (%s|%s);', OJS.Step, OJS.Tool, NJS.Tool)
        END ||

        CASE WHEN (Not OJS.Signature Is Distinct From NJS.Signature) OR _ignoreSignatureMismatch THEN ''
             ELSE format(' step %s Signature (%s|%s);', OJS.Step, OJS.Signature, NJS.Signature)
        END

        -- || CASE WHEN Not OJS.Output_Folder_Name Is Distinct From NJS.Output_Folder_Name THEN ''
        --         ELSE format(' step %s Output_Folder_Name (%s|%s);', OJS.Step, OJS.Output_Folder_Name, NJS.Output_Folder_Name)
        --    END

        , '; ')     -- Delimiter for string_agg()

    INTO _message
    FROM sw.t_job_steps OJS
         INNER JOIN Tmp_Job_Steps NJS
           ON OJS.job = NJS.job AND
              OJS.step = NJS.step
    WHERE OJS.Job = _job AND
          ( Not OJS.signature Is Null OR
            Not NJS.signature Is Null
          );

    If _message <> '' Then
        _message := format('Parameter mismatch: %s', _message);
        _returnCode := 'U5499';
    End If;

END
$$;

COMMENT ON PROCEDURE sw.cross_check_job_parameters IS 'CrossCheckJobParameters';
