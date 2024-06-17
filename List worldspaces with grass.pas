{
  List Cells/Console Codes/Worlds for which grass is in the LAND record.
}
unit UserScript;


var
  filesneeded, consolecodes, worldsneeded: TStringList;
  fname, cname, wname, wrlds: string;
  generateFiles, skipTraverse: Boolean;

function Initialize: Integer;
begin
  generateFiles := 1;
  skipTraverse := 0;
  fname := ProgramPath + 'Edit Scripts\grasscache.txt';
  cname := ProgramPath + 'Edit Scripts\grasscacheconsole.txt';
  wname := ProgramPath + 'Edit Scripts\grasscacheworlds.txt';

  filesneeded := TStringList.Create;
  filesneeded.Sorted := true;
  filesneeded.Duplicates := dupIgnore;

  consolecodes := TStringList.Create;
  consolecodes.Sorted := true;
  consolecodes.Duplicates := dupIgnore;

  worldsneeded := TStringList.Create;
  worldsneeded.Sorted := true;
  worldsneeded.Duplicates := dupIgnore;
  worldsneeded.Delimiter := ';';

  if generateFiles then
    OptionForm;
  if not skipTraverse then
    TraverseWorldspaceCells;
end;

function ZeroPad(const S : string): string;
var
  i, numlen: integer;
  str1, str2: string;
begin
  str1 := S;
  str2 := StringReplace(S, '-', '', rfReplaceAll);
  if str1 = str2 then
    numlen := 4
  else
    numlen := 3;
  i := Length(str2);
  while i < numlen do
  begin
    str2 := '0' + str2;
    inc(i);
  end;
  if numlen = 3 then
    str2 := '-' + str2;
  Result := str2;
end;

function TraverseWorldspaceCells: integer;
var
  gltexes, parentworlds, wrldsusingparentlanddata: TStringList;
  doesithavegrass, modidx, wrldidx, blockidx, subblockidx, cellidx, cellchildidx, numberoflayers, layeridx, theumpteenthidx, lengthofthename, filesneededidx, parentworldsidx: integer;
  f, wrlds, wrld, wrldgrup, block, subblock, cell, cellchild, temprecord, layers, layerrecord, layertexture, ilosttrack, parentwrld: IInterface;
  wrldname, x, y, xxxx, yyyy, thename, newname, filenameneeded, cellmodcheck, therewasgrassinthiscellforthismod, parentwrldname: string;
begin
  gltexes := TStringList.Create;
  parentworlds := TStringList.Create;
  wrldsusingparentlanddata := TStringList.Create;
  LandscapeTexturesWithGrass(gltexes);


  // traverse mods
  for modidx := 0 to FileCount - 1 do begin
    f := FileByIndex(modidx);
    wrlds := GroupBySignature(f, 'WRLD');
    AddMessage('Processing ' + IntToStr(modidx + 1) + ' of ' + IntToStr(FileCount) + '... please wait.');
    if not Assigned(wrlds) then Continue;

    // traverse Worldspaces
    for wrldidx := 0 to ElementCount(wrlds) - 1 do begin
      wrld := ElementByIndex(wrlds, wrldidx);
      wrldname: = EditorID(wrld);

      if (GetElementNativeValues(wrld, 'Parent\PNAM\Flags') and 1 = 1) then begin
        //parentwrld := GetElementEditValues(wrld, 'Parent\WNAM');
        //AddMessage(parentwrld);
        parentwrld := LinksTo(ElementByPath(wrld, 'Parent\WNAM'));
        parentwrldname := EditorID(parentwrld);
        parentworlds.add(parentwrldname);
        wrldsusingparentlanddata.add(wrldname);
      end;

      wrldgrup := ChildGroup(wrld);

      // traverse Blocks
      for blockidx := 0 to ElementCount(wrldgrup) - 1 do begin

        //test
        //if wrldname <> 'WhiterunWorld' then break;
        //end test

        block := ElementByIndex(wrldgrup, blockidx);
        if Signature(block) = 'CELL' then Continue;

        // traverse SubBlocks
        for subblockidx := 0 to ElementCount(block) - 1 do begin
          subblock := ElementByIndex(block, subblockidx);

          // traverse Cells
          for cellidx := 0 to ElementCount(subblock) - 1 do begin
            cell := ElementByIndex(subblock, cellidx);

            x := GetElementNativeValues(cell, 'XCLC\X');
            if x = '' then continue;
            y := GetElementNativeValues(cell, 'XCLC\Y');
            xxxx := ZeroPad(x);
            yyyy := ZeroPad(y);
            cellmodcheck := IntToStr(modidx) + ' of ' + IntToStr(FileCount) + ' has grass in ' + wrldname + ' ' + x + ' ' + y;
            filenameneeded := wrldname + 'x' + xxxx + 'y'+ yyyy + '.gid';
            therewasgrassinthiscellforthismod := '';

            cellchild := FindChildGroup(ChildGroup(cell),9,cell);
            for cellchildidx := 0 to ElementCount(cellchild) - 1 do begin
              temprecord := ElementByIndex(cellchild, cellchildidx);

              //traverse layers of landscape record
              if Signature(temprecord) = 'LAND' then begin
                layers := ElementByName(temprecord, 'Layers');
                numberoflayers := ElementCount(layers);
                if numberoflayers > 0 then begin
                  for layeridx := 0 to numberoflayers - 1 do begin
                    layerrecord := ElementByIndex(layers, layeridx);
                    //traverse the texture element name to find the landscape textures used
                    for theumpteenthidx := 0 to ElementCount(layerrecord) - 1 do begin
                      ilosttrack := ElementByIndex(layerrecord, theumpteenthidx);
                      thename := GetEditValue(ElementByName(ilosttrack, 'Texture'));
                      if thename = 'NULL - Null Reference [00000000]' then continue;
                      //AddMessage(thename);
                      //string is 16 chars too much
                      lengthofthename := Length(thename);
                      newname := LeftStr(thename, lengthofthename - 16);
                      //AddMessage(newname);
                      doesithavegrass := gltexes.indexOf(newname);
                      if doesithavegrass <> -1 then begin

                        //AddMessage(filenameneeded);
                        filesneeded.add(filenameneeded);
                        consolecodes.add('cow ' + wrldname + ' ' + x + ' ' + y);
                        worldsneeded.add(wrldname);
                        therewasgrassinthiscellforthismod := cellmodcheck;
                        //AddMessage(therewasgrassinthiscellforthismod)
                      end;
                      //
                      //filesneededidx := filesneeded.indexOf(filenameneeded);
                      //if (doesithavegrass = -1) and (filesneededidx <> -1) then
                      //  filesneeded.Delete(filesneededidx)
                    end;
                    if (therewasgrassinthiscellforthismod = cellmodcheck) then break;
                  end;
                end;
              end;
              //if we found the temprecord with landscape and it had grass, then we can break the loop of temp records
              if (therewasgrassinthiscellforthismod = cellmodcheck) then break;
            end;
            //if the cellidx for the modidx did not contain grass, but was in the list of cells that contain grass, remove it
            //this doesn't work -- need to rethink my logic
            (*if (therewasgrassinthiscellforthismod <> cellmodcheck) and (filesneeded.indexOf(filenameneeded) <> -1) then begin
              filesneeded.Delete(filesneeded.indexOf(filenameneeded));
              AddMessage('Mod id ' + IntToStr(modidx) + ' removed grass from ' + wrldname + ' ' + x + ' ' + y)
            end;*)
          end;
        end;
      end;
    end;
  end;
  //some manual rules for now until I can verify these
  (*if worldsneeded.indexOf('DLC2ApocryphaWorld') <> -1 then
    worldsneeded.Delete(worldsneeded.indexOf('DLC2ApocryphaWorld'));
  if worldsneeded.indexOf('DLC01Boneyard') <> -1 then
    worldsneeded.Delete(worldsneeded.indexOf('DLC01Boneyard'));
  if worldsneeded.indexOf('WindhelmPitWorldspace') <> -1 then
    worldsneeded.Delete(worldsneeded.indexOf('WindhelmPitWorldspace'));*)

  for parentworldsidx := 0 to parentworlds.Count - 1 do begin
  if worldsneeded.indexOf(parentworlds[parentworldsidx]) <> -1 then
    worldsneeded.add(wrldsusingparentlanddata[parentworldsidx]);
  end;

  gltexes.Free;
  parentworlds.Free;
  wrldsusingparentlanddata.Free;
end;



function BoolToStr(Value : Boolean) : String;
begin
  if Value then
    result := 'true'
  else
    result := 'false';
end;

function GetLandscapeForCell(cell: IInterface): IInterface;
var
  cellchild, r: IInterface;
  i: integer;
begin
  cellchild := FindChildGroup(ChildGroup(cell), 9, cell); // get Temporary group of cell
  for i := 0 to Pred(ElementCount(cellchild)) do begin
    r := ElementByIndex(cellchild, i);
    if Signature(r) = 'LAND' then begin
      Result := r;
      Exit;
    end;
  end;
end;

procedure LandscapeTexturesWithGrass(gltexes: TStringList);
//prints a list of landscape texture (LTEX) records that contain grass (GNAM) in the current modlist.
//
//Original thought process:
//for LandscapeTexture in LandscapeTextures:
//	if LandscapeTexture contains Grasses:
//		append landscapeTexture to GrassList
var
  gltex: TStringList;
  i, modidx, ltexidx: Integer;
  f, ltexes, ltex: IInterface;
  edid: string;
begin
  //traverse mods
  gltex := TStringList.Create;
  gltex.Sorted := true;
  gltex.Duplicates := dupIgnore;
  for modidx := 0 to FileCount - 1 do begin
    f := FileByIndex(modidx);
    ltexes := GroupBySignature(f, 'LTEX');
    if not Assigned(ltexes) then Continue;

    // traverse Landscape Textures
    for ltexidx := 0 to ElementCount(ltexes) - 1 do begin
      ltex := ElementByIndex(ltexes, ltexidx);
      edid := GetElementEditValues(ltex, 'EDID');
      if ElementExists(ltex,'GNAM') then
        gltex.Add(edid)
      else if gltex.indexOf(edid) > -1 then
        gltex.Delete(gltex.indexOf(edid))
    end;
  end;
  i := 0;
  while i < gltex.Count do
    begin
      AddMessage(gltex.Strings[i]);
      inc(i);
    end;
  gltexes.AddStrings(gltex);
  gltex.Free;
end;

procedure MessageForm(wrldwithgrass: string);
var
  frm: TForm;
  lbl1, lblMessage, lblMessage2: TLabel;
  edWrlds: TEdit;
  btnOK: TButton;
  done: Boolean;
begin
  frm := TForm.Create(nil);
  try
    frm.Caption := 'Worldspaces with grass';
    frm.Width := 475;
    frm.Height := 128;
    frm.Position := poScreenCenter;
    frm.BorderStyle := bsDialog;

    lbl1 := TLabel.Create(frm);
    lbl1.Parent := frm;
    lbl1.Left := 8;
    lbl1.Width := 120;
    lbl1.Top := 8;
    lbl1.Text := 'Worldspaces with grass:';

    edWrlds := TEdit.Create(frm);
    edWrlds.Parent := frm;
    edWrlds.Left := 128;
    edWrlds.Top := 6;
    edWrlds.Width := 325;
    edWrlds.Height := 20;
    edWrlds.Text := wrldwithgrass;

    lblMessage := TLabel.Create(frm);
    lblMessage.Parent := frm;
    lblMessage.Left := 128;
    lblMessage.Width := 325;
    lblMessage.Top := edWrlds.Top + 24;
    lblMessage.Text := 'Copy and paste this output into the "OnlyPregenerateWorldSpaces"';

    lblMessage2 := TLabel.Create(frm);
    lblMessage2.Parent := frm;
    lblMessage2.Left := 128;
    lblMessage2.Width := 325;
    lblMessage2.Top := lblMessage.Top + 16;
    lblMessage2.Text := 'setting within the No Grass In Objects GrassControl.config.txt.';

    btnOk := TButton.Create(frm);
    btnOk.Parent := frm;
    btnOk.Caption := 'OK';
    btnOk.ModalResult := mrOk;
    btnOk.Left := 128;
    btnOk.Top := lblMessage2.Top + 24;

    frm.ActiveControl := edWrlds;

    if frm.ShowModal = mrOk then begin
      done := 1;
        end else
      done := 0;
  finally
    frm.Free;
  end;
end;

procedure OptionForm;
var
  frm: TForm;
  btnOk, btnCancel: TButton;
  lbl1, lbl2, lbl3: TLabel;
  edFname, edCname, edWname: TLabeledEdit;
begin
  frm := TForm.Create(nil);
  try
    frm.Caption := 'List Cells/Console Codes/Worlds for which grass is in the LAND record';
    frm.Width := 600;
    frm.Height := 150;
    frm.Position := poScreenCenter;
    frm.BorderStyle := bsDialog;

    edFname := TLabeledEdit.Create(frm);
    edFname.Parent := frm;
    edFname.LabelPosition := lpLeft;
    edFname.EditLabel.Caption := 'Path to output list:';
    edFname.Left := 150;
    edFname.Top := 8;
    edFname.Width := 400;
    edFname.Text := fname;

    edCname := TLabeledEdit.Create(frm);
    edCname.Parent := frm;
    edCname.LabelPosition := lpLeft;
    edCname.EditLabel.Caption := 'Path to output console codes:';
    edCname.Left := 150;
    edCname.Top := edFname.Top + 24;
    edCname.Width := edFname.Width;
    edCname.Text := cname;

    edWname := TLabeledEdit.Create(frm);
    edWname.Parent := frm;
    edWname.LabelPosition := lpLeft;
    edWname.EditLabel.Caption := 'Path to output worlds:';
    edWname.Left := 150;
    edWname.Top := edCname.Top + 24;
    edWname.Width := edCname.Width;
    edWname.Text := wname;

    btnOk := TButton.Create(frm);
    btnOk.Parent := frm;
    btnOk.Caption := 'OK';
    btnOk.ModalResult := mrOk;
    btnOk.Left := 150;
    btnOk.Top := edWname.Top + 32;

    btnCancel := TButton.Create(frm);
    btnCancel.Parent := frm;
    btnCancel.Caption := 'Cancel';
    btnCancel.ModalResult := mrCancel;
    btnCancel.Left := btnOk.Left + btnOk.Width + 16;
    btnCancel.Top := btnOk.Top;

    frm.ActiveControl := btnOk;

    if frm.ShowModal = mrOk then begin
      if (Trim(edFname.Text) <> '') then
        fname := Trim(edFname.Text);
      if (Trim(edCname.Text) <> '') then
        cname := Trim(edCname.Text);
      if (Trim(edWname.Text) <> '') then
        wname := Trim(edWname.Text);
        end;
  finally
    frm.Free;
  end;
end;

function Finalize: integer;
var
  wrldts: TStringList;
begin
  wrlds := worldsneeded.DelimitedText;
  worldsneeded.Free;
  wrldts := TStringList.Create;
  wrldts.add(wrlds);

  AddMessage(wrldts.Text);
  MessageForm(wrldts.Text);

  if generateFiles then begin
    AddMessage('Saving grasscacheworlds.txt to ' + wname);
    wrldts.SaveToFile(wname);

    AddMessage('Saving grasscache.txt to ' + fname);
    filesneeded.SaveToFile(fname);
    filesneeded.Free;

    AddMessage('Saving grasscacheconsole.txt to ' + cname);
    consolecodes.SaveToFile(cname);
    consolecodes.Free;
  end;
  wrldts.Free;

  Result := 1;
end;

end.