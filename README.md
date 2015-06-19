# StringElementReplace


Here is the basic layout of StringElementReplace:

//---------File Selection ---------------

	    Files = ''; (leave blank for now - Placeholder for GUI later)

//---------Record Selection----------------

    RecordTypes = 'QUST';
   IgnOverrides = false;
  IgnModRecords = false;     

//------ Element/Comparison Selection ----------

       SearchIn = 'EDID,FULL';
       CheckFor = 'TS_,TSNAME_';
//------ Element Comparisons ----------

  LogicOperator = 'lAND';

//------ Element Modifications -------

    ModElements = 'FLTR, EDID';
       ModTypes = '[mtOv], Test';	
         ModEVs = 'Generic\Scenes, ReplacementTest'; 
      IgnModEVs = false;
    IgnEmptyEVs = false;




//------Record Selection---------------------------------------------------------------

RecordType: 
What type of record you want the script to search for.  It will check every record of that type in all of 
the files you provided.  Can only provide one record type at a time.

IgnOverrides: 
If true, will ignore all override records.

IgnModRecords: 
If true, will ignore any records which have had their elements modified in your current TES5Edit Session.

In the example above, it will look through yourmod.esp and grab all QWST records and look at each one.


//------ Element/Comparison Selection -------------------------------------------------------------------

SearchIn: 
Will Search inside of all elements you provide it. Separated by commas.

CheckFor: 
The phrases which you will check, each phrase is connected to an element in SearchIn.  So the first phrase will be used on the first element in SearchIn,  The 2nd phrase on the 2nd element in SearchIn etc.


In the example above the EditorID will be checked for the phrase "_TS" and the Full Name will be checked for the phrase "TSNAME_"


//------ Element Comparisons ------------------------------------------------------------------

LogicOperator: 
'Determines how the script will handle multiple comparisons.  Only one may be chosen.'
    lOR = 'Record will be modified if any comparison is true.'
    lAND = 'Record will be modified only if all comparisons are true'
    lNOTAND = 'Record will be modified only if all of the comparisons are false.'


In the example above, it will check if "TS_" is found in each quests EditorID (EDID). It will also check 
if "TSNAME_" is in its Display Name(NAME).  The EditorID and Display Name must contain "TS_" and "TSNAME_" 
respectively in order for the record to be modified.

//------ Element Modifications --------------------------------------------------------------
ModElements: 
List the Elements which you wish to be modified if the logical comparisons are true.  In the example 
above,the Object List Filter and Editor ID will be modified.


ModTypes: 
/*Each Modtype determines how the Edit Values of each element in ModElements will be modified.*/
    [mtOv] = 'completely replace ModEV.'
    [mtApp] = 'Append ModEV.'
    [mtPre] = 'Prepend ModEV.'
    UserDefined =   Replace the part defined by this variable with ModEV if this variable exists 
                    in the old EV. Leaving this blank (ex, 'mtAppend,,mtPrepend') or a false comparison 
                    will skip that element.
                    

In the example above,  it will completely replace the FLTR of any matching record with  "Generic\Scenes".  It will also look inside of the record's Editor ID for the phrase "Test".

ModEVs: 
This will contain the phrases which will either append, prepend or replace the current Edit Value of that 
element.  If [Empty] is provided, it will remove the element.

In the example above, all FLTR elements in all 'QUST' records will end up with a FLTR of "Generic\Scenes".  If FLTR element was empty, it will automatically add the element and apply the value.
For it's editor ID it will look for the phrase "Test" and, if found, it will replace the phrase "Test" with "replacementTest"
(Ex.  Before:  "TS_This is a TestEV"  After: "TS_This is a ReplacementTestEV")

IgnModEVs: 
Skip any EV that has already been modified during the current tes5edit session.

IgnEmptyEVs: 
Will skip any modifications to EVs which contain no data.  Useful for when we want to prepend EVs while 
keeping the ones we want empty to stay that way.
