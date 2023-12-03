--
CREATE OR REPLACE PROCEDURE public.populate_instrument_filter_table
(
    _instrumentFilterList text = '',
    INOUT _message text default '',
    INOUT _returnCode text default ''
)
LANGUAGE plpgsql
AS $$
/****************************************************
**
**  Desc:
**      Populates temp table Tmp_InstrumentFilter based on the comma-separated instrument names in _instrumentFilterList
**
**      The calling procedure must create the temporary table:
**
**          CREATE TEMP TABLE Tmp_InstrumentFilter (
**              Instrument_ID int NOT NULL
**          );
**
**  Arguments:
**    _instrumentFilterList     Comma-separated list of instrument names; % and * wildcards are allowed ('*' is auto-changed to '%')
**    _message                  Output message
**    _returnCode               Return code
**
**  Auth:   mem
**  Date:   07/22/2019 mem - Initial version
**          12/15/2024 mem - Ported to PostgreSQL
**
*****************************************************/
DECLARE
    _msg text;
    _matchSpec text;
BEGIN
    _message := '';
    _returnCode := '';

    _instrumentFilterList := Trim(Coalesce(_instrumentFilterList, ''));

    If _instrumentFilterList <> '' Then

        CREATE TEMP TABLE Tmp_MatchSpec (
            Match_Spec_ID int PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
            Match_Spec text
        )

        INSERT INTO Tmp_MatchSpec (Match_Spec)
        SELECT DISTINCT Value
        FROM public.parse_delimited_list(_instrumentFilterList)
        ORDER BY Value

        FOR _matchSpec IN
            SELECT Match_Spec
            FROM Tmp_MatchSpec
            ORDER BY Match_Spec_ID
        LOOP

            _matchSpec := Replace(_matchSpec, '*', '%');

            If Position('%' In _matchSpec) > 0 Then
                INSERT INTO Tmp_InstrumentFilter( instrument_id )
                SELECT FilterQ.instrument_id
                FROM ( SELECT instrument_id
                       FROM t_instrument_name
                       WHERE instrument LIKE _matchSpec ) FilterQ
                     LEFT OUTER JOIN Tmp_InstrumentFilter Target
                       ON FilterQ.instrument_id = Target.instrument_id
                WHERE Target.instrument_id IS NULL;
            Else
                INSERT INTO Tmp_InstrumentFilter( instrument_id )
                SELECT FilterQ.instrument_id
                FROM ( SELECT instrument_id
                       FROM t_instrument_name
                       WHERE instrument = _matchSpec ) FilterQ
                     LEFT OUTER JOIN Tmp_InstrumentFilter Target
                       ON FilterQ.instrument_id = Target.instrument_id
                WHERE Target.instrument_id IS NULL;
            End If;

        END LOOP;

        DROP TABLE Tmp_MatchSpec;

    Else
        INSERT INTO Tmp_InstrumentFilter( instrument_id )
        SELECT DISTINCT instrument_id
        FROM t_instrument_name
    End If;
END
$$;

COMMENT ON PROCEDURE public.populate_instrument_filter_table IS 'PopulateInstrumentFilterTable';
