{
  New script template, only shows processed records
  Assigning any nonzero value to Result will terminate script
}
unit ModElementByForm;
uses mteFunctions;
const
//---------File Selection ---------------
	    Files = '';

//---------Record Selection----------------
     RecordType = 'QUST';
   IgnOverrides = false;
  IgnModRecords = false;     

//------ Element/Comparison Selection ----------
       SearchIn = 'EDID';
       CheckFor = 'Bruma';
//------ Element Comparisons ----------
  LogicOperator = 'lOR';

//------ Element Modifications -------
    ModElements = 'FULL';
       ModTypes = '[mtApp]';	
         ModEVs = ': This is A Test'; 
      IgnModEVs = false;
    IgnEmptyEVs = false;
       TestMode = false;
     DebugLevel = 3;

//----- Reference --------
{
Note: Theses are case sensative
ModTypes:
[mtOv]
[mtApp]
[mtPre]
[Empty]

ModEVs:
[Empty]
}
Dash = '----------------:';
var
	slFiles,slSearchIn,slCheckFor,slModElements,slModTypes,slModEVs,slQueue, slNextQueue: TStringList;


function Initialize: integer;
	begin
		slFiles := TStringList.Create; 		 slFiles.StrictDelimiter := true; 		slFiles.DelimitedText := Files;
		slSearchIn := TStringList.Create; 	 slSearchIn.StrictDelimiter := true; 	slSearchIn.DelimitedText := SearchIn;	
		slCheckFor := TStringList.Create; 	 slCheckFor.StrictDelimiter := true; 	slCheckFor.DelimitedText := CheckFor;	
		slModElements := TStringList.Create; slModElements.StrictDelimiter := true; slModElements.DelimitedText := ModElements;		
		slModTypes := TStringList.Create; 	 slModTypes.StrictDelimiter := true; 	slModTypes.DelimitedText := ModTypes;	
		slModEVs := TStringList.Create; 	 slModEVs.StrictDelimiter := true; 		slModEVs.DelimitedText := ModEVs;
		slQueue := TStringList.Create;		 slQueue.StrictDelimiter := true;
		slNextQueue := TStringList.Create;	 slNextQueue.StrictDelimiter := true;
		ScriptProcessElements := [etFile];
	  Result := 0;
	end;

function Process(e: IInterface): integer;
	begin
		slFiles.Append(GetFileName(e));
		Result := 0;
		BuildRef(e);
	end;

function Finalize: integer;
	var
		i,z: Integer;
		iFile, iRecordTemp, iRecord: IInterface;
		slTemp: TStringList;
	begin
		slTemp := TStringList.Create;
		Result := 0;
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
			iFile := FileByName(slFiles[i]);
			GrabRecordsInFileAndModify(iFile,RecordType,IgnOverrides,IgnModRecords,slQueue);
		end;
		slTemp.free;
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
		slNextQueue.free;
	end;

Procedure GrabRecordsInFileAndModify(iFile:IInterface;sGRUP:String;bIgnOverrides,bIgnModified:Boolean;slQ:TStringList);
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
					continue;
				end; 
			end;
			if bIgnModified then begin
																					DBOut('Inside Modified Check',2);
				if GetElementState(iRecord, esModified) <> 0 then begin
																					DBOut('Skipping: Record Is Flagged Modified',2);					
				continue;
				end;
			end;
			sFormID := IntToStr(GetLoadOrderFormID(iRecord));
			if (slQ.IndexOf(sFormID) > (-1)) then continue;
			if Matches(iRecord,slSearchIn,slCheckFor,LogicOperator) then begin
				slQ.Append(sFormID);
				ModifyRecord(iRecord,slModElements,slModTypes,slModEVs);
			end;
		end;
	end;

Function Matches(iElement: IInterface; slSI,slCF:TStringList; sOperator:String):Boolean;
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

Procedure FilterByComparisons(slSI,slCF,slQ,slNQ:TStringList; sOperator:String);
	var
		i,z:Integer;
		iElement: IInterface;
		slBool: TStringList;
		bComparison:Boolean;
	begin
																					DBOut(Dash+'Inside FilterByComparisons',1);
		slBool := TStringList.Create;
		bComparison := true;
		for i := Pred(slQ.Count) downto 0 do begin
			if (i < 0) then exit;
			while (i > Pred(slQ.Count)) do begin
				Pred(i);
			end;
			for z := 0 to Pred(slSI.Count) do begin
				bComparison := CompareElement(iElement,slSI[z],slCF[z]);
				slBool.Append(BoolToStr(bComparison));
			end;
			if SameText(sOperator,'lAND') then begin
				if slBool.IndexOf('False') > -1 then slNQ.AddObject();
			end else
			if SameText(sOperator,'lOR') then begin
				if slBool.IndexOf('True') = -1 then slQ.Delete(i);
			end else
			if SameText(sOperator,'lNOTAND') then begin
				if slBool.IndexOf('True') > -1 then slQ.Delete(i);
			end else
			if SameText(sOperator,'lNOTOR') then begin
				if slBool.IndexOf('False') = -1 then slQ.Delete(i);
			end;
			slBool.Clear;
		end;
		slBool.Free;
	end;

Function CompareElement(iElement:IInterface; sElePath, sContains:String): Boolean;
	var
		sEV: String;
	begin
		Result := false;
		sEV := geev(iElement,sElePath);
		if SameText(sEV, '') then exit;
		if Pos(Lowercase(sContains),Lowercase(sEV)) > 0 then Result := true;
	end;

Procedure ModifyRecord(iRecord: IInterface;slMEs,slMTs,slMEVs:TStringList);
	var
		i,z: Integer;
		iElement, iNewRecord: IInterface;
	begin
		If TestMode then AddMessage('Modifying Record: '+ShortName(iRecord));
		for i := 0 to Pred(slMEs.Count) do begin
			iElement := ElementByIP(iRecord,slMEs[i]);
			if Assigned(iElement) then begin
																					DBOut('Assigned Element: '+Name(iElement),2);
				if TestMode then AddMessage('Modifying Element: '+Name(iElement));
				ModifyElement(iRecord,iElement,slMTs[i],slMEs[i],slMEVs[i]);
			end else
			if (IgnEmptyEVs = false) then begin
				if TestMode then AddMessage('Modifying Element: '+Name(iElement));
				iElement := Add(iRecord,slMEs[i],true);
				Add(iRecord, Name(iElement), true);
				iElement := ElementByIP(iRecord, slMEs[i]);
																					DBOut('Added Element: '+Name(iElement),2);
				ModifyElement(iRecord,iElement,slMTs[i],slMEs[i],slMEVs[i]);
			end;
		end; 
	end;

Procedure ModifyElement(var iRecord:IInterface;var iElement:IInterface;sMT,sME,sMEV:String);
	var
		sEV,sEVReplace: String;
		iNewElement: IInterface;
	begin
																					DBOut(Dash+'Inside ModifyElement',1);
																					DBOut(Format('sMT: %s  sME: %s  sMEV: %s',[sMT,sME,sMEV]),1);
		sEV := GetEditValue(iElement);
		if IgnModEVs then begin
			if GetElementState(iElement, esModified) <> 0 then begin
			  if TestMode then AddMessage('     Already Modified: Skipping');
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
			if SameText(sEV,'') then sEVReplace := sMEV
			else Exit;
		end else begin
			sEVReplace := StringReplace(sEV,sMT,sMEV,[rfReplaceAll, rfIgnoreCase]);
		end;
		if DoTestMode(sEV,sEVReplace) then exit;
		if SameText(sEVReplace,'[Empty]') then RemoveNode(iElement) else begin
			RemoveNode(iElement);
			iNewElement := Add(iRecord, sME, false);
			SetEditValue(iNewElement,sEVReplace);
		end;
	end;
	
Function DoTestMode(sBefore,sAfter:String):Boolean;
	begin
		Result := TestMode;
		if (Result = false) then exit;
		AddMessage('     Before: '+ sBefore);
		AddMessage('     After:	'+ sAfter);
	end;
	
Procedure ReadOutSl(prepend: String; sl:TStringList);
	var
		i: Integer;
	begin
		for i := 0 to Pred(sl.Count) do begin
			AddMessage(prepend+' '+sl[i]);
		end;
	end;

Procedure DBOut(s:String; lvl:integer);
	begin
		if DebugLevel > (-1) then
			if lvl > DebugLevel then 
				AddMessage(s);
	end;
end.
