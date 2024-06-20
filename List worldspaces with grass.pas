{
  List Cells/Console Codes/Worlds for which grass is in the LAND record.
}
unit UserScript;

var
  filesneeded, consolecodes, worldsneeded: TStringList;
  fname, cname, wname, wrlds: string;
  generateFiles: Boolean;

function Initialize: Integer;
{
    This function is called at the beginning.
}
var
  skipTraverse: Boolean;
begin
  generateFiles := 1;
  skipTraverse := 0;
  fname := ScriptsPath() + 'grasscache.txt';
  cname := ScriptsPath() + 'grasscacheconsole.txt';
  wname := ScriptsPath() + 'grasscacheworlds.txt';

  CreateObjects;

  if not OptionForm then begin
    AddMessage('Script was cancelled.');
    Result := 0;
    Exit;
  end;

  if not skipTraverse then TraverseWorldspaceCells;

  Result := 0;
end;

Procedure CreateObjects;
begin
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

  Result := 0;
end;

function ZeroPad(const S: string): string;
{
  Given a numeric string, adds zeros until the string is  4 characters long. The negative symbol is included in character count.
  Examples:
    1 --> 0001
    10 --> 0010
    -1 --> -001
    -33 --> -033
}
var
  i, numlen: integer;
  str1, str2: string;
begin
  str1 := S;
  // Strip the negative sign.
  str2 := StringReplace(S, '-', '', rfReplaceAll);

  // This allows us to track the negative sign. Length is 4 if it doesn't have negative sign. Length is 3 with negative sign, and then added onto the end.
  if str1 = str2 then numlen := 4 else numlen := 3;

  // Add zeros
  i := Length(str2);
  while i < numlen do begin
    str2 := '0' + str2;
    inc(i);
  end;

  //Add back the negative sign if it was used.
  if numlen = 3 then str2 := '-' + str2;

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

function BoolToStr(b: boolean): string;
{
    Given a boolean, return a string.
}
begin
    if b then Result := 'true' else Result := 'false';
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
  lbl1, lblMessage: TLabel;
  edWrlds: TEdit;
  btnOK: TButton;
  done: Boolean;
begin
  frm := TForm.Create(nil);
  try
    frm.Caption := 'Worldspaces with grass';
    frm.Width := 550;
    frm.Height := 180;
    frm.Position := poScreenCenter;
    frm.BorderStyle := bsDialog;

    lbl1 := TLabel.Create(frm);
    lbl1.Parent := frm;
    lbl1.Left := 8;
    lbl1.Top := 8;
    lbl1.Text := 'Worldspaces with grass:';

    edWrlds := TEdit.Create(frm);
    edWrlds.Parent := frm;
    edWrlds.Left := lbl1.Left + lbl1.Width + 16;
    edWrlds.Top := 6;
    edWrlds.Width := frm.Width - edWrlds.Left - 16;
    edWrlds.Height := 20;
    edWrlds.Text := wrldwithgrass;

    lblMessage := TLabel.Create(frm);
    lblMessage.Parent := frm;
    lblMessage.Left := edWrlds.Left;
    lblMessage.Width := 325;
    lblMessage.Top := edWrlds.Top + 36;
    lblMessage.Text := 'Copy and paste this output into the "OnlyPregenerateWorldSpaces"'+ #13#10 + 'setting within the No Grass In Objects GrassControl.config.txt.';

    btnOk := TButton.Create(frm);
    btnOk.Parent := frm;
    btnOk.Caption := 'OK';
    btnOk.ModalResult := mrOk;
    btnOk.Left := (frm.Width - btnOk.Width)/2;
    btnOk.Top := lblMessage.Top + 60;

    frm.ActiveControl := edWrlds;

    if frm.ShowModal = mrOk then done := 1 else done := 0;
  finally
    frm.Free;
  end;
end;

function CreateLabel(aParent: TControl; x, y: Integer; aCaption: string): TLabel;
{
  Create a label.
}
begin
  Result := TLabel.Create(aParent);
  Result.Parent := aParent;
  Result.Left := x;
  Result.Top := y;
  Result.Caption := aCaption;
end;

function OptionForm: Boolean;
var
  frm: TForm;
  btnOk, btnCancel: TButton;
  lbl1, lbl2, lbl3: TLabel;
  edFname, edCname, edWname: TEdit;
  gbOptions: TGroupBox;
  pnl: TPanel;
begin
  frm := TForm.Create(nil);
  try
    frm.Caption := 'List Cells/Console Codes/Worlds for which grass is in the LAND record';
    frm.Width := 600;
    frm.Height := 250;
    frm.Position := poScreenCenter;
    frm.BorderStyle := bsDialog;

    gbOptions := TGroupBox.Create(frm);
    gbOptions.Parent := frm;
    gbOptions.Left := 10;
    gbOptions.Top := 16;
    gbOptions.Width := frm.Width - 30;
    gbOptions.Caption := 'Output Paths';
    gbOptions.Height := 130;

    edFname := TLabeledEdit.Create(gbOptions);
    edFname.Parent := gbOptions;
    edFname.Name := 'edFname';
    edFname.Left := 104;
    edFname.Top := 30;
    edFname.Width := 400;
    edFname.Text := fname;
    CreateLabel(gbOptions, 16, edFname.Top + 4, 'List:');

    edCname := TLabeledEdit.Create(gbOptions);
    edCname.Parent := gbOptions;
    edCname.Name := 'edCname';
    edCname.Left := edFname.Left;
    edCname.Top := edFname.Top + 30;
    edCname.Width := edFname.Width;
    edCname.Text := cname;
    CreateLabel(gbOptions, 16, edCname.Top + 4, 'Console codes:');

    edWname := TLabeledEdit.Create(gbOptions);
    edWname.Parent := gbOptions;
    edWname.Name := 'edWname';
    edWname.Left := edCname.Left;
    edWname.Top := edCname.Top + 30;
    edWname.Width := edCname.Width;
    edWname.Text := wname;
    CreateLabel(gbOptions, 16, edWname.Top + 4, 'Worlds:');

    btnOk := TButton.Create(frm);
    btnOk.Parent := frm;
    btnOk.Caption := 'OK';
    btnOk.ModalResult := mrOk;
    btnOk.Top := gbOptions.Top + gbOptions.Height + 32;

    btnCancel := TButton.Create(frm);
    btnCancel.Parent := frm;
    btnCancel.Caption := 'Cancel';
    btnCancel.ModalResult := mrCancel;
    btnCancel.Top := btnOk.Top;

    btnOk.Left := gbOptions.Width - btnOk.Width - btnCancel.Width - 16;
    btnCancel.Left := btnOk.Left + btnOk.Width + 8;

    pnl := TPanel.Create(frm);
    pnl.Parent := frm;
    pnl.Left := 8;
    pnl.Top := btnOk.Top - 12;
    pnl.Width := frm.Width - 24;
    pnl.Height := 2;

    frm.ActiveControl := btnOk;

    if frm.ShowModal <> mrOk then begin
      Result := False;
      Exit;
    end
    else Result := True;


    if (Trim(edFname.Text) <> '') then
      fname := Trim(edFname.Text);
    if (Trim(edCname.Text) <> '') then
      cname := Trim(edCname.Text);
    if (Trim(edWname.Text) <> '') then
      wname := Trim(edWname.Text);
  finally
    frm.Free;
  end;
end;

end.