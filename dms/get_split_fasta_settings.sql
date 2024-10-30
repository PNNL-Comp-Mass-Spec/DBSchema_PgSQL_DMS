--
-- Name: get_split_fasta_settings(text); Type: FUNCTION; Schema: public; Owner: d3l243
--

CREATE OR REPLACE FUNCTION public.get_split_fasta_settings(_settingsfilename text) RETURNS TABLE(split_fasta_enabled boolean, number_of_cloned_steps integer, message text)
    LANGUAGE plpgsql
    AS $$
/****************************************************
**
**  Desc:
**      Extracts the values for 'SplitFasta' and 'NumberOfClonedSteps' from the XML for the given settings file, returning the results as a table
**
**      If the settings file does not exist, no rows will be returned
**      If 'SplitFasta' is not defined in the settings file, split_fasta_enabled will be false and number_of_cloned_steps will be 0
**      If 'SplitFasta' is defined in the settings file, but is false, split_fasta_enabled will be false and number_of_cloned_steps will be 0
**      If 'SplitFasta' is defined in the settings file and is true, split_fasta_enabled will be true and the number_of_cloned_steps will be shown
**      (a warning message will be shown if NumberOfClonedSteps is not defined or is not numeric)
**
**  Arguments:
**    _settingsFileName     Settings file name
**
**  Auth:   mem
**  Date:   10/29/2024 mem - Initial version
**
*****************************************************/
DECLARE
    _message text;
    _splitFasta text;
    _splitFastaEnabled boolean;
    _numberOfClonedSteps text;
    _numberOfClonedStepsValue int;
BEGIN
    If Not Exists (SELECT settings_file_id FROM t_settings_files WHERE file_name = _settingsFileName::citext) Then
        _message := format('Settings file not found: %s', _settingsFileName);
        RAISE WARNING '%', _message;
        RETURN;
    End If;

    SELECT XmlQ.value
    INTO _splitFasta
    FROM (
        SELECT Trim(xmltable.section) AS section,
               Trim(xmltable.name)    AS name,
               Trim(xmltable.value)   AS value
        FROM (SELECT contents AS settings
              FROM t_settings_files
              WHERE file_name = _settingsFileName::citext
             ) Src,
             XMLTABLE('//sections/section/item'
                      PASSING Src.settings
                      COLUMNS section text PATH '../@name',
                              name    text PATH '@key',
                              value   text PATH '@value'
                              )
         ) XmlQ
    WHERE name::citext = 'SplitFasta';

    If Not FOUND Then
        _message := format('"SplitFasta" is not defined for settings file %s', _settingsFileName);

        RETURN QUERY
        SELECT false AS split_fasta_enabled,
               0 AS number_of_cloned_steps,
               _message;

        RETURN;
    End If;

    _splitFastaEnabled := public.try_cast(_splitFasta, false);

    If Not _splitFastaEnabled Then
        _message := format('"SplitFasta" is not "true" for settings file %s', _settingsFileName);

        RETURN QUERY
        SELECT false AS split_fasta_enabled,
               0 AS number_of_cloned_steps,
               _message;

        RETURN;
    End If;

    SELECT XmlQ.value
    INTO _numberOfClonedSteps
    FROM (
        SELECT Trim(xmltable.section) AS section,
               Trim(xmltable.name)    AS name,
               Trim(xmltable.value)   AS value
        FROM (SELECT contents AS settings
              FROM t_settings_files
              WHERE file_name = _settingsFileName::citext
             ) Src,
             XMLTABLE('//sections/section/item'
                      PASSING Src.settings
                      COLUMNS section text PATH '../@name',
                              name    text PATH '@key',
                              value   text PATH '@value'
                              )
         ) XmlQ
    WHERE name::citext = 'NumberOfClonedSteps';

    If Not FOUND Then
        _message := format('"NumberOfClonedSteps" is not defined for settings file %s', _settingsFileName);
        RAISE INFO '%', _message;

        RETURN QUERY
        SELECT true AS split_fasta_enabled,
               1 AS number_of_cloned_steps,
               _message;

        RETURN;
    End If;

    If public.try_cast(_numberOfClonedSteps, null::int) Is Null Then
        _message := format('"NumberOfClonedSteps" is not an integer for settings file %s', _settingsFileName);
        RAISE WARNING '%', _message;

        RETURN QUERY
        SELECT true AS split_fasta_enabled,
               1 AS number_of_cloned_steps,
               _message;

        RETURN;
    End If;

    _numberOfClonedStepsValue := public.try_cast(_numberOfClonedSteps, 0);

    If _numberOfClonedStepsValue < 1 Then
        _message := format('"NumberOfClonedSteps" is less than 1 for settings file %s', _settingsFileName);
        RAISE INFO '%', _message;

        RETURN QUERY
        SELECT true AS split_fasta_enabled,
               _numberOfClonedStepsValue AS number_of_cloned_steps,
               _message;

        RETURN;
    End If;

    RETURN QUERY
    SELECT true AS split_fasta_enabled,
           _numberOfClonedStepsValue AS number_of_cloned_steps,
           Coalesce(_message, '') AS message;
END
$$;


ALTER FUNCTION public.get_split_fasta_settings(_settingsfilename text) OWNER TO d3l243;

