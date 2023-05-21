--
CREATE OR REPLACE PROCEDURE cap.update_dms_prep_state
(
    _job int,
    _script text,
    _jobInfo.NewState int,
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Update prep LC state in DMS
**
**  Auth:   grk
**  Date:   05/08/2010 grk - Initial Veresion
**          12/15/2023 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _prepLCID int;
    _storagePathID int;
BEGIN
    _message := '';
    _returnCode := '';

    If _script = 'HPLCSequenceCapture' Then
        --
        SELECT
            _prepLCID = CONVERT(int, xmlNode.value('_value', 'text'))
        FROM
            cap.t_task_parameters cross apply parameters.nodes('//Param') AS R(xmlNode)
        WHERE
            cap.t_task_parameters.Job = _job AND
            xmlNode.value('_name', 'text') = 'ID';

        --
        SELECT
            _storagePathID = CONVERT(int, xmlNode.value('_value', 'text'))
        FROM
            cap.t_task_parameters cross apply parameters.nodes('//Param') AS R(xmlNode)
        WHERE
            cap.t_task_parameters.Job = _job AND
            xmlNode.value('_name', 'text') = 'Storage_Path_ID';

        If _jobInfo.NewState = 3 Then
            CALL public.set_prep_lc_task_complete (_prepLCID, _storagePathID, 0, _message => _message);
        End If;

        If _jobInfo.NewState = 5 Then
            CALL public.set_prep_lc_task_complete (_prepLCID, 0, 1, _message => _message);
        End If;

    End If;

END
$$;

COMMENT ON PROCEDURE cap.update_dms_prep_state IS 'UpdateDMSPrepState';
