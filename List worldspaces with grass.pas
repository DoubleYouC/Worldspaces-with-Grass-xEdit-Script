{
  List Cells/Console Codes/Worlds for which grass is in the LAND record.
}
unit UserScript;

var
  filesneeded, consolecodes, worldsneeded: TStringList;
  fname, cname, wname, wrlds: string;
  bGenerateFiles: Boolean;
  chkGenerateFiles: TCheckBox;
  edFname, edCname, edWname: TEdit;
  tlLand, tlWrld: TList;

function Initialize: Integer;
{
    This function is called at the beginning.
}
var
  wrldts: TStringList;
begin
  bGenerateFiles := 0;
  fname := ScriptsPath() + 'grasscache.txt';
  cname := ScriptsPath() + 'grasscacheconsole.txt';
  wname := ScriptsPath() + 'grasscacheworlds.txt';

  CreateObjects;

  if not OptionForm then begin
    AddMessage('Script was cancelled.');
    Result := 0;
    Exit;
  end;

  Grass;
  Land;
  ListStringsInStringList(filesneeded);
  Worlds;

  wrlds := worldsneeded.DelimitedText;
  worldsneeded.Free;
  wrldts := TStringList.Create;
  wrldts.add(wrlds);

  AddMessage(wrldts.Text);
  MessageForm(wrldts.Text);

  if bGenerateFiles then begin
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

  tlLand := TList.Create;
  tlWrld := TList.Create;
end;

function Finalize: integer;
begin
  tlLand.Free;
  tlWrld.Free;
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

procedure Grass;
var
  i, j, idx: integer;
  recordId: string;
  f, g, r: IInterface;
  slLtex, slLand, slWrld: TStringList;
  tlLtex: TList;
begin
  tlLtex := TList.Create;
  slLtex := TStringList.Create;
  slWrld := TStringList.Create;
  slLand := TStringList.Create;
  for i := 0 to Pred(FileCount) do begin
    f := FileByIndex(i);

    //STAT
    g := GroupBySignature(f, 'LTEX');
    for j := 0 to Pred(ElementCount(g)) do begin
      r := WinningOverride(ElementByIndex(g, j));
      recordId := GetFileName(r) + #9 + ShortName(r);
      idx := slLtex.IndexOf(recordId);
      if idx > -1 then continue
      slLtex.Add(recordId);
      if not ElementExists(r, 'GNAM') then continue;
      tlLtex.Add(r);
      AddMessage(ShortName(r));
    end;

    g := GroupBySignature(f, 'WRLD');
    for j := 0 to Pred(ElementCount(g)) do begin
      r := WinningOverride(ElementByIndex(g, j));
      recordId := GetFileName(r) + #9 + ShortName(r);
      idx := slWrld.IndexOf(recordId);
      if idx > -1 then continue
      slWrld.Add(recordId);
      tlWrld.Add(r);
    end;
  end;

  for i := 0 to Pred(tlLtex.Count) do begin
    g := ObjectToElement(tlLtex[i]);
    for j := 0 to Pred(ReferencedByCount(g)) do begin
      r := ReferencedByIndex(g, j);
      if Signature(r) <> 'LAND' then continue;
      if not IsWinningOverride(r) then continue;
      recordId := GetFileName(r) + #9 + ShortName(r);
      idx := slLand.IndexOf(recordId);
      if idx > -1 then continue;
      slLand.Add(recordId);
      tlLand.Add(r);
    end;
  end;
  slLtex.Free;
  slLand.Free;
  tlLtex.Free;
  slWrld.Free;
end;

procedure Land;
var
  i: integer;
  land, rCell, rWrld: IInterface;
  x, y, xxxx, yyyy, wrldname, filenameneeded: string;
begin
  for i := 0 to Pred(tlLand.Count) do begin
    land := ObjectToElement(tlLand[i]);
    rCell := WinningOverride(LinksTo(ElementByIndex(land, 0)));
    x := GetElementEditValues(rCell, 'XCLC\X');
    y := GetElementEditValues(rCell, 'XCLC\Y');
    xxxx := ZeroPad(x);
    yyyy := ZeroPad(y);
    rWrld := WinningOverride(LinksTo(ElementByIndex(rCell, 0)));
    if GetElementEditValues(rWrld, 'DATA - Flags\No Grass') = '1' then continue;
    wrldname := EditorID(rWrld);
    filenameneeded := wrldname + 'x' + xxxx + 'y'+ yyyy + '.gid';
    filesneeded.add(filenameneeded);
    consolecodes.add('cow ' + wrldname + ' ' + x + ' ' + y);
    worldsneeded.add(wrldname);
  end;
end;

procedure Worlds;
var
  i: integer;
  wrld, parentwrld: IInterface;
begin
  for i := 0 to Pred(tlWrld.Count) do begin
    wrld := ObjectToElement(tlWrld[i]);
    if GetElementEditValues(wrld, 'Parent\PNAM\Flags\Use Land Data') <> '1' then continue;
    parentwrld := LinksTo(ElementByPath(wrld, 'Parent\WNAM'));
    if worldsneeded.IndexOf(EditorID(parentwrld)) > -1 then worldsneeded.Add(EditorID(wrld));
  end;
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

procedure checkboxHandler(Sender: TObject);
begin
  edFname.Enabled := chkGenerateFiles.Checked;
  edCname.Enabled := chkGenerateFiles.Checked;
  edWname.Enabled := chkGenerateFiles.Checked;
end;

function OptionForm: Boolean;
var
  frm: TForm;
  btnOk, btnCancel: TButton;
  lbl1, lbl2, lbl3: TLabel;
  gbOptions: TGroupBox;
  pnl: TPanel;
begin
  frm := TForm.Create(nil);
  try
    frm.Caption := 'List Cells/Console Codes/Worlds for which grass is in the LAND record';
    frm.Width := 600;
    frm.Height := 300;
    frm.Position := poScreenCenter;
    frm.BorderStyle := bsDialog;

    gbOptions := TGroupBox.Create(frm);
    gbOptions.Parent := frm;
    gbOptions.Left := 10;
    gbOptions.Top := 16;
    gbOptions.Width := frm.Width - 30;
    gbOptions.Caption := 'Debug files';
    gbOptions.Height := 160;

    chkGenerateFiles := TCheckBox.Create(gbOptions);
    chkGenerateFiles.Parent := gbOptions;
    chkGenerateFiles.Name := 'chkGenerateFiles';
    chkGenerateFiles.Left := 104;
    chkGenerateFiles.Top := 30;
    chkGenerateFiles.Width := 200;
    chkGenerateFiles.Caption := 'Create debug files';
    chkGenerateFiles.OnClick := checkboxHandler;

    edFname := TLabeledEdit.Create(gbOptions);
    edFname.Parent := gbOptions;
    edFname.Name := 'edFname';
    edFname.Left := 104;
    edFname.Top := chkGenerateFiles.Top + 30;
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
    chkGenerateFiles.Checked := bGenerateFiles;
    edFname.Enabled := chkGenerateFiles.Checked;
    edCname.Enabled := chkGenerateFiles.Checked;
    edWname.Enabled := chkGenerateFiles.Checked;

    if frm.ShowModal <> mrOk then begin
      Result := False;
      Exit;
    end
    else Result := True;

    bGenerateFiles := chkGenerateFiles.Checked;
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

procedure ListStringsInStringList(sl: TStringList);
{
    Given a TStringList, add a message for all items in the list.
}
var
    i: integer;
begin
    for i := 0 to Pred(sl.Count) do AddMessage(sl[i]);
end;

end.