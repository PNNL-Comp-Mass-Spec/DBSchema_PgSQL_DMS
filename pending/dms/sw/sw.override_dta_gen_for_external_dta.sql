--
CREATE OR REPLACE PROCEDURE sw.override_dta_gen_for_external_dta
(
    _job int,
    _xmlParameters xml,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      If settings file contains parameter for externally-supplied DTA file,
**      override existing DTA_Gen step to point to it
**
**  Auth:   grk
**  Date:   01/28/2008 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/719)
**          01/30/2009 grk - Modified for extension jobs (http://prismtrac.pnl.gov/trac/ticket/720)
**          03/04/2009 grk - Modified to preset DTA_Gen step to 'complete' instead of skipped
**          04/14/2009 grk - Modified to apply to DTA_Import step tool also (Ticket #733, http://prismtrac.pnl.gov/trac/ticket/733)
**          04/15/2009 grk - Modified to maintain shared results for imported DTA (Ticket #733, http://prismtrac.pnl.gov/trac/ticket/733)
**          03/21/2011 mem - Rearranged logic to remove Goto
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _externalDTAFolderName text;
BEGIN
    _message := '';
    _returnCode:= '';

    ---------------------------------------------------
    -- Get parameter, if present
    ---------------------------------------------------

    SELECT unnest(xpath('//params/Param[@Name="ExternalDTAFolderName"]/@Value', rooted_xml))::text
    INTO _externalDTAFolderName
    FROM ( SELECT ('<params>' || _xmlParameters::text || '</params>')::xml as rooted_xml
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
            Output_Folder_Name = _externalDTAFolderName,
            Input_Folder_Name = 'External'
        WHERE Tool IN ('DTA_Gen', 'DTA_Import') AND
              Job = _job;

    End If;

END
$$;

COMMENT ON PROCEDURE sw.override_dta_gen_for_external_dta IS 'OverrideDTAGenForExternalDTA';
