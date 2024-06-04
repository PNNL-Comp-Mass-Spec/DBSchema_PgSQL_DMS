--
-- Name: override_dta_gen_for_external_dta(integer, xml, text, text); Type: PROCEDURE; Schema: sw; Owner: d3l243
--

CREATE OR REPLACE PROCEDURE sw.override_dta_gen_for_external_dta(IN _job integer, IN _xmlparameters xml, INOUT _message text DEFAULT ''::text, INOUT _returncode text DEFAULT ''::text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      If settings file contains parameter for externally-supplied DTA file,
**      override existing DTA_Gen step to point to it
**
**      The calling procedure must create and populate temporary table Tmp_Job_Steps,
**      which must include these columns:
**
**      CREATE TEMP TABLE Tmp_Job_Steps (
**          Job int NOT NULL,
**          Step int NOT NULL,
**          Tool citext NOT NULL,
**          State int NULL,
**          Input_Directory_Name citext NULL,
**          Output_Directory_Name citext NULL,
**          Processor citext NULL
**      );
**
**  Arguments:
**    _job              Analysis job number
**    _xmlparameters    XML parameters
**    _message          Status message
**    _returnCode       Return code
**
**  Auth:   grk
**  Date:   01/28/2008 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/719)
**          01/30/2009 grk - Modified for extension jobs (http://prismtrac.pnl.gov/trac/ticket/720)
**          03/04/2009 grk - Modified to preset DTA_Gen step to 'complete' instead of skipped
**          04/14/2009 grk - Modified to apply to DTA_Import step tool also (Ticket #733, http://prismtrac.pnl.gov/trac/ticket/733)
**          04/15/2009 grk - Modified to maintain shared results for imported DTA (Ticket #733, http://prismtrac.pnl.gov/trac/ticket/733)
**          03/21/2011 mem - Rearranged logic to remove Goto
**          07/31/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _externalDTAFolderName text;
BEGIN
    _message := '';
    _returnCode := '';

    ---------------------------------------------------
    -- Get parameter, if present
    ---------------------------------------------------

    SELECT unnest(xpath('//params/Param[@Name="ExternalDTAFolderName"]/@Value', rooted_xml))::text
    INTO _externalDTAFolderName
    FROM (SELECT ('<params>' || _xmlParameters::text || '</params>')::xml AS rooted_xml
         ) Src
    LIMIT 1;

    If Coalesce(_externalDTAFolderName, '') <> '' Then

        ---------------------------------------------------
        -- Override DTA_Gen step
        ---------------------------------------------------

        UPDATE Tmp_Job_Steps
        SET State = CASE WHEN Tool = 'DTA_Gen'
                         THEN 5
                         ELSE State
                    END,
            Processor = 'Internal',
            Input_Directory_Name = 'External',
            Output_Directory_Name = _externalDTAFolderName
        WHERE Tool IN ('DTA_Gen', 'DTA_Import') AND
              Job = _job;

    End If;

END
$$;


ALTER PROCEDURE sw.override_dta_gen_for_external_dta(IN _job integer, IN _xmlparameters xml, INOUT _message text, INOUT _returncode text) OWNER TO d3l243;

--
-- Name: PROCEDURE override_dta_gen_for_external_dta(IN _job integer, IN _xmlparameters xml, INOUT _message text, INOUT _returncode text); Type: COMMENT; Schema: sw; Owner: d3l243
--

COMMENT ON PROCEDURE sw.override_dta_gen_for_external_dta(IN _job integer, IN _xmlparameters xml, INOUT _message text, INOUT _returncode text) IS 'OverrideDTAGenForExternalDTA';

