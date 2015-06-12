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
   IgnOverrides = true;
  IgnModRecords = false;     

//------ Element/Comparison Selection ----------
       SearchIn = 'EDID,FULL';
       CheckFor = 'Quest,Quest';
//------ Element Comparisons ----------
  LogicOperator = 'lAND';

//------ Element Modifications -------
    ModElements = 'FLTR';
       ModTypes = '[mtApp]';	
         ModEVs = 'Generic\Scenes'; 
      IgnModEVs = false;
    IgnEmptyEVs = false;
       TestMode = true;

//----- Reference --------
{
Note: Theses are case sensative
ModTypes:
[mtOv]
[mtApp]
[mtPre]

ModEVs:
[Empty]

}

var
	slFiles,slSearchIn,slCheckFor,slModElements,slModTypes,slModEVs,slQueue: TStringList;


function Initialize: integer;
	begin
		slFiles := TStringList.Create; 		 slFiles.StrictDelimiter := true; 		slFiles.DelimitedText := Files;
		slSearchIn := TStringList.Create; 	 slSearchIn.StrictDelimiter := true; 	slSearchIn.DelimitedText := SearchIn;	
		slCheckFor := TStringList.Create; 	 slCheckFor.StrictDelimiter := true; 	slCheckFor.DelimitedText := CheckFor;	
		slModElements := TStringList.Create; slModElements.StrictDelimiter := true; slModElements.DelimitedText := ModElements;		
		slModTypes := TStringList.Create; 	 slModTypes.StrictDelimiter := true; 	slModTypes.DelimitedText := ModTypes;	
		slModEVs := TStringList.Create; 	 slModEVs.StrictDelimiter := true; 		slModEVs.DelimitedText := ModEVs;
		slQueue := TStringList.Create;		 slQueue.StrictDelimiter := true;
		ScriptProcessElements := [etFile];
	  Result := 0;
	end;

function Process(e: IInterface): integer;
	begin
		slFiles.AddObject(GetFileName(e),TObject(e));
		Result := 0;
		BuildRef(e);
	end;

function Finalize: integer;
	var
		i,z: Integer;
		iFile, iRecord: IInterface;
		slTemp: TStringList;
	begin
		slTemp := TStringList.Create;
		Result := 0;
		ReadOutSl('slFiles:',slFiles);
		ReadOutSl('slSearchIn:',slSearchIn);
		ReadOutSl('slCheckFor:', slCheckFor);
		ReadOutSl('slModElements:', slModElements);
		ReadOutSl('slModTypes:', slModTypes);
		ReadOutSl('slModEVs:', slModEVs);
		for i:=0 to Pred(slFiles.Count) do begin
			iFile := ObjectToElement(slFiles.Objects[i]);
			GrabRecordsInFile(iFile,RecordType,IgnOverrides,slQueue);
		end;
		AddMessage(slQueue.DelimitedText);
		FilterByComparisons(slSearchIn,slCheckFor,slQueue, LogicOperator);
		AddMessage(slQueue.DelimitedText);
		for z := Pred(slQueue.Count) downto 0 do begin;
			iRecord := ObjectToElement(slQueue.Objects[z]);
			if not Assigned(iRecord) then continue;
			ModifyRecord(iRecord,slModElements,slModTypes,slModEVs);
		end;
		slTemp.free;
		ClearGlobals()
	end;

Procedure ClearGlobals();
	begin
		slFiles.free;
		slSearchIn.free;
		slCheckFor.free;
		slModElements.free;
		slModTypes.free;
		slModEVs.free;
	end;

procedure ReadOutSl(prepend: String; sl:TStringList);
	var
		i: Integer;
	begin
		for i := 0 to Pred(sl.Count) do begin
			AddMessage(prepend+' '+sl[i]);
		end;
	end;


Procedure GrabRecordsInFile(iFile:IInterface;sGRUP:String;bOverrides:Boolean;slQ:TStringList);
	var
		i:Integer;
		sFormID:String;
		iGRUP,iRecord: IInterface;
	begin
		if not Assigned(iFile) then exit;
		if not HasGroup(iFile,sGRUP) then exit;
		iGRUP := GroupBySignature(iFile,sGRUP);
		for i := 0 to Pred(ElementCount(iGRUP)) do begin
			iRecord := ElementByIndex(iGRUP,i);
			AddMessage(Name(iRecord));
			if (bOverrides = false) then begin
				if (not IsMaster(iRecord)) or (not IsInjected(iRecord)) then exit;
			end;
			sFormID := IntToStr(GetLoadOrderFormID(iRecord));
			if slQ.IndexOf(sFormID) > (-1) then continue;
			slQ.AddObject(HexFormID(iRecord),TObject(iRecord));
		end;

	end;

Procedure FilterByComparisons(slSI,slCF,slQ:TStringList; sOperator:String);
	var
		i,z:Integer;
		iElement: IInterface;
		slBool: TStringList;
		bComparison:Boolean;
	begin
		slBool := TStringList.Create;
		bComparison := true;
		for i := Pred(slQ.Count) downto 0 do begin
			if (i < 0) then exit;
			while (i > Pred(slQ.Count)) do begin
				Pred(i);
			end;
			iElement := ObjectToElement(slQ.Objects[i]);
			for z := 0 to Pred(slSI.Count) do begin
				bComparison := CompareElement(iElement,slSI[z],slCF[z]);
				slBool.Append(BoolToStr(bComparison));
			end;
			if SameText(sOperator,'lAND') then begin
				if slBool.IndexOf('False') > -1 then slQ.Delete(i);
			end else
			if SameText(sOperator,'lOR') then begin
				if slBool.IndexOf('True') > -1 then continue else slQ.Delete(i);
			end else
			if SameText(sOperator,'lNOTAND') then begin
				if slBool.IndexOf('True') > -1 then slQ.Delete(i);
			end else
			if SameText(sOperator,'lNOTOR') then begin
				if slBool.IndexOf('False') > -1 then continue else slQ.Delete(i);
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
		iElement: IInterface;
	begin
		If TestMode then AddMessage('Modifying Record: '+ShortName(iRecord));
		for i := 0 to Pred(slMEs.Count) do begin
			iElement := ElementByPath(iRecord,slMEs[i]);
			if Assigned(iElement) then begin
				if TestMode then AddMessage('Modifying Element: '+Name(iElement));
				ModifyElement(iElement,slMTs[i],slMEVs[i]);
			end else
			if (IgnEmptyEVs = false) then begin
				if TestMode then AddMessage('Modifying Element: '+Name(iElement));
				iElement := Add(iRecord, slMEs[i], false);
				ModifyElement(iElement,slMTs[i],slMEVs[i]);
			end;
		end; 
	end;

Procedure ModifyElement(iElement: IInterface; sMT,sMEV:String);
	var
		sEV,sEVReplace: String;
	begin
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
		end else begin
			sEVReplace := StringReplace(sEV,sMT,sMEV,[rfReplaceAll, rfIgnoreCase]);
		end;
		if DoTestMode(sEV,sEVReplace) then exit;
		if SameText(sEVReplace,'[Empty]') then RemoveNode(iElement) else
			SetEditValue(iElement,sEVReplace);
	end;
	
Function DoTestMode(sBefore,sAfter):Boolean;
	begin
		Result := false;
		if (TestMode = false) then exit;
		Result := true;
		AddMessage('     Before: '+ sBefore);
		AddMessage('      After: '+ sAfter);
	end;
end.
