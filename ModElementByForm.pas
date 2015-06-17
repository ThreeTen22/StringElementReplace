{
  New script template, only shows processed records
  Assigning any nonzero value to Result will terminate script
}
unit ModElementByForm;
uses mteFunctions;
const
//-------- File Selection ---------------
	    Files = '';

//-------- Record Selection ---------------
     RecordType = 'ACTI';
   IgnOverrides = false;
  IgnModRecords = false;     

//------ Element/Comparison Selection ----------
       SearchIn = 'FULL';
       CheckFor = 'T';
//------ Element Comparisons ----------
  LogicOperator = 'lOR';

//------ Element Modifications -------
    ModElements = 'EDID,EDID,FULL';
       ModTypes = '[mtPre],[mtApp],T';	
         ModEVs = 'MY ,_Modified,Test12'; 
      IgnModEVs = true;
    IgnEmptyEVs = true;

//------- Testing & Debuging ----------
       TestMode = true;
     DebugLevel = 3;

//----- Reference --------
{
Note: Theses are case sensative
ModTypes:
[mtOv]
[mtApp]
[mtPre]
[Empty]
User Defined (ex. T or ACR_ )

ModEVs:
[Empty]
}
Dash = '----------------:';
LongDash = '--------------------------------------------------------';
TMBefore = 'TM:                    Before: ';
TMAfter = 'TM:                    After:	';
var
	slFiles,slSearchIn,slCheckFor,slModElements,slModTypes,slModEVs,slQueue,slTest: TStringList;
	bDoubleEle: Boolean;

function Initialize: integer;
	begin
	bDoubleEle := false;
	AddMessage(#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10);
	AddMessage(#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10);
	AddMessage(#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10#13#10);
		slFiles := TStringList.Create; 		 slFiles.StrictDelimiter := true; 		slFiles.DelimitedText := Files;
		slSearchIn := TStringList.Create; 	 slSearchIn.StrictDelimiter := true; 	slSearchIn.DelimitedText := SearchIn;	
		slCheckFor := TStringList.Create; 	 slCheckFor.StrictDelimiter := true; 	slCheckFor.DelimitedText := CheckFor;	
		slModElements := TStringList.Create; slModElements.StrictDelimiter := true; slModElements.DelimitedText := ModElements;		
		slModTypes := TStringList.Create; 	 slModTypes.StrictDelimiter := true; 	slModTypes.DelimitedText := ModTypes;	
		slModEVs := TStringList.Create; 	 slModEVs.StrictDelimiter := true; 		slModEVs.DelimitedText := ModEVs;
		slQueue := TStringList.Create;		 slQueue.StrictDelimiter := true;
		slTest := TStringList.Create;		 slTest.StrictDelimiter := true;		slTest.Delimiter := #13#10;
		ScriptProcessElements := [etFile];
	If TestMode then begin
		bDoubleEle := HasDuplicates(slModElements);
		if bDoubleEle then ShowMessage('Note:  '#13'You are running this script in Test Mode and are modifying the same element more than once.  The shown result will not be accurate as I do not keep track of more than one change per element, but all modifications WILL be applied, in inputted order, when actually running the script.'#13#13
			                                             'Ex.  I have an element with EDID of "Awesome" and have it setup so I first prepend "My " then second append " Test".  When running the test it will show:'#13#13
			                                             'Before: Awesome'#13'After: My Awesome'#13#13
			                                             'Then for the next modification:'#13#13
			                                             'Before: Awesome'#13
			                                             'After: Awesome Test'#13#13
			                                             'If actually running the script the EDID will correctly end up as:'#13
			                                             '"My Awesome Test"');
	end;
	  Result := 0;
	end;

function Process(e: IInterface): integer;
	begin
		slFiles.AddObject(GetFileName(e), TObject(e));
		Result := 0;
	end;

function Finalize: integer;
	var
		i,z: Integer;
		iFile, iRecordTemp, iRecord: IInterface;
	begin
		ReadOutSl('slFiles:',slFiles);
		AddMessage('Record: '+ RecordType);
		AddMessage('IgnOverrides: '+BoolToStr(IgnOverrides));
		AddMessage('IgnModRecords: '+BoolToStr(IgnModRecords));
		ReadOutSl('slSearchIn:',slSearchIn);
		ReadOutSl('slCheckFor:', slCheckFor);
		ReadOutSl('slModElements:', slModElements);
		ReadOutSl('slModTypes:', slModTypes);
		ReadOutSl('slModEVs:', slModEVs);
		AddMessage('IgnModEVs: '+BoolToStr(IgnModEVs));
		AddMessage('IgnEmptyEVs: '+BoolToStr(IgnEmptyEVs));
		AddMessage('TestMode: '+BoolToStr(TestMode));
		for i:=Pred(slFiles.Count) downto 0 do begin
			iFile := ObjectToElement(slFiles.Objects[i]);
			GrabRecordsInFileAndModify(iFile,RecordType,IgnOverrides,IgnModRecords,slQueue);
		end;
		ClearGlobals();
		RemoveFilter();
	end;

Procedure ClearGlobals();
	begin
		slFiles.free;
		slSearchIn.free;
		slCheckFor.free;
		slModElements.free;
		slModTypes.free;
		slModEVs.free;
		slQueue.free;
		slTest.free;
	end;

Procedure GrabRecordsInFileAndModify(iFile:IInterface;const sGRUP:String;bIgnOverrides,bIgnModified:Boolean;slQ:TStringList);
	var
		i:Integer;
		sFormID:String;
		iGRUP,iRecord: IInterface;
	begin
																					DBOut(Dash+'Inside GrabRecordsInFile',1);
		if not Assigned(iFile) then exit;
																					DBOut('Passed File Assiged check',2);
		if not HasGroup(iFile,sGRUP) then exit;
																					DBOut('Passed GRUP Assiged check',2);
		iGRUP := GroupBySignature(iFile,sGRUP);
																					DBOut('Group ElementCount: '+IntToStr(Pred(ElementCount(iGRUP))),2);
		for i := 0 to Pred(ElementCount(iGRUP)) do begin
			
			iRecord := ElementByIndex(iGRUP,i);
																					DBOut('Element: '+Name(iRecord),2);
			if bIgnOverrides then begin
																					DBOut('Inside Override Check',2);
				if not IsMaster(iRecord) then begin
																					DBOut('Skipping: Record Is Override',2);
				if TestMode then AddMessage('TM: Skipping Record: '+Name(iRecord));
					continue;
				end; 
			end;
			if bIgnModified then begin
																					DBOut('Inside Modified Check',2);
				if GetElementState(iRecord, esModified) <> 0 then begin
																					DBOut('Skipping: Record Is Flagged Modified',2);
				if TestMode then AddMessage('TM: Skipping Record: '+Name(iRecord));				
				continue;
				end;
			end;
			sFormID := IntToStr(GetLoadOrderFormID(iRecord));
			if (slQ.IndexOf(sFormID) > (-1)) then continue;
			if Matches(iRecord,slSearchIn,slCheckFor,LogicOperator) then begin
				slQ.Append(sFormID);
				ModifyRecord(iRecord,slModElements,slModTypes,slModEVs);
				if TestMode then begin
					AddMessage(slTest.Text);
					slTest.clear;
				end;
			end else begin
				DoTestString('TM: Skipping Record: '+Name(iRecord));
			end;
		end;
	end;

Function Matches(iElement: IInterface; slSI,slCF:TStringList; const sOperator:String):Boolean;
	var
	i,z:Integer;
	slBool: TStringList;
	bComparison: Boolean;
	begin
																			DBOut(Dash+'Inside Matches',1);
		Result := false;
		slBool := TStringList.Create;
		for z := 0 to Pred(slSI.Count) do begin
			bComparison := CompareElement(iElement,slSI[z],slCF[z]);
			slBool.Append(BoolToStr(bComparison));
		end;
		if SameText(sOperator,'lAND') then begin
			if slBool.IndexOf('False') = -1 then Result := true;
		end else
		if SameText(sOperator,'lOR') then begin
			if slBool.IndexOf('True') > -1 then Result := true;
		end else
		if SameText(sOperator,'lNOTAND') then begin
			if slBool.IndexOf('True') = -1 then Result := true;
		end else
		if SameText(sOperator,'lNOTOR') then begin
			if slBool.IndexOf('False') > -1 then Result := true;
		end;
		slBool.Free;
	end;


Function CompareElement(iElement:IInterface;const sElePath:String;const sContains:String): Boolean;
	var
		sEV: String;
	begin
		Result := true;
		sEV := geev(iElement,sElePath);
		if SameText(sEV, '') then begin
			if SameText(sContains, '[Empty]') then begin
				exit;
			end;
			Result := false;
			Exit;
		end;
		if Pos(Lowercase(sContains),Lowercase(sEV)) = (0) then begin
		 Result := false;
		 Exit;	
		end;
	end;

Procedure ModifyRecord(iRecord: IInterface;slMEs,slMTs,slMEVs:TStringList);
	var
		i,z: Integer;
		iElement, iNewRecord: IInterface;
	begin
		DoTestString(#13#10'TM: Modifying Record: '+ShortName(iRecord));
		for i := 0 to Pred(slMEs.Count) do begin
			iElement := ElementByIP(iRecord,slMEs[i]);
			if Assigned(iElement) then begin
																					DBOut('Assigned Element: '+Name(iElement),2);
				DoTestString('TM:     Modifying Element: '+Name(iElement));
				ModifyElement(iRecord,iElement,slMTs[i],slMEs[i],slMEVs[i]);
			end else
			if (IgnEmptyEVs = false) then begin
				if DoTestString('TM:     Modifying Element: '+Name(iElement)) then begin
					ModifyElement(iRecord,iElement,slMTs[i],slMEs[i],slMEVs[i]);
					exit;
				end; 
				iElement := Add(iRecord,slMEs[i],true);
				Add(iRecord, Name(iElement), true);
				iElement := ElementByIP(iRecord, slMEs[i]);
																					DBOut('Added Element: '+Name(iElement),2);
				ModifyElement(iRecord,iElement,slMTs[i],slMEs[i],slMEVs[i]);
			end else begin
				DoTestString('TM:     Skipping Element: '+slMEs[i]+' - IgnEmptyEVs is true');
			end;
		end; 
		DoTestString(LongDash);
	end;

Procedure ModifyElement(iRecord:IInterface;iElement:IInterface;const sMT:String;const sME:String;const sMEV:String);
	var
		sEV,sEVReplace: String;
		iNewElement: IInterface;
	begin
																					DBOut(Dash+'Inside ModifyElement',1);
																					DBOut(Format('sMT: %s  sME: %s  sMEV: %s',[sMT,sME,sMEV]),1);
		sEV := GetEditValue(iElement);
		if IgnModEVs then begin
			if Assigned(iElement) then
				if GetElementState(iElement, esModified) <> 0 then begin
				  if DoTestString('TM:          Already Modified: Skipping') then exit;
				exit;	
				end; 
		end;
		if SameText(sMT,'[mtOv]') then begin
			sEVReplace := sMEV;
		end else
		if SameText(sMT,'[mtApp]') then begin
			sEVReplace := sEV+sMEV;
		end else
		if SameText(sMT,'[mtPre]') then begin
			sEVReplace := sMEV+sEV;
		end else
		if SameText(sMT,'[Empty]') then begin
			if SameText(sEV,'') then sEVReplace := sMEV else Exit;
		end else begin
			sEVReplace := StringReplace(sEV,sMT,sMEV,[rfReplaceAll, rfIgnoreCase]);
		end;
	
		if SameText(sEVReplace,'[Empty]') then begin
			if DoTestString('TM:                    Clearing EV: '+ sEV) then exit;
			RemoveNode(iElement);
		end else begin
			if DoTestMode(sEV,sEVReplace) then exit;
			SetEditValue(iElement,sEVReplace);
		end;
	end;

Function FindEquiv(const sEV: String; sl:TStringList): String;
	var 
	i,z,x: Integer;
	begin
		if sEv = '' then Exit;
		for i := Pred(sl.Count) downto 0 do begin
			AddMessage('Results: '+ sEV);
			if SameText(TMBefore+sEV,sl[i]) then begin
				if Pos(TMAfter, sl[i-1]) = 0 then begin
					Result := sEV;
					Exit;
				end;
				x := Length(TMAfter);
				z := Length(sl[i-1]);
				Result := Copy(sl[i-1],x,5);
				Exit;
			end;
		end;
	end;

Function DoTestString(const s:String):Boolean;
begin
	Result := TestMode;
	if not result then exit;
	slTest.Add(s);
end;
	
Function DoTestMode(const sBefore: String; const sAfter:String):Boolean;
	begin
		Result := TestMode;
		if not Result then exit;
		slTest.Add(TMBefore+ sBefore);
		slTest.Add(TMAfter+ sAfter);
	end;
	
Procedure ReadOutSl(const prepend: String; sl:TStringList);
	var
		i: Integer;
	begin
		for i := 0 to Pred(sl.Count) do begin
			AddMessage(prepend+' '+sl[i]);
		end;
	end;

Procedure DBOut(const s:String; lvl:integer);
	begin
		if DebugLevel > (-1) then
			if lvl > DebugLevel then 
				AddMessage(s);
	end;

Function HasDuplicates(sl:TStringList):Boolean;
	var
	  i, j: integer;
	begin
	  Result := false;
	  for i := Pred(sl.Count) downto 0 do begin
	    j := sl.IndexOf(sl[i]);
	    if (j <> -1) and (j <> i) then begin
	    	Result := true;
	    	Exit;  
	    end;
	  end;
	end;
end.
