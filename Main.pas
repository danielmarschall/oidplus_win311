unit Main;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IniFiles, Grids, Outline, ExtCtrls;

type
  TForm1 = class(TForm)
    Outline1: TOutline;
    Notebook1: TNotebook;
    Memo1: TMemo;
    Label2: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Button8: TButton;
    Edit9: TEdit;
    Edit10: TEdit;
    Edit11: TEdit;
    Edit12: TEdit;
    Edit13: TEdit;
    Button9: TButton;
    Edit14: TEdit;
    Label13: TLabel;
    Button5: TButton;
    Edit2: TEdit;
    Label14: TLabel;
    Edit8: TEdit;
    Button7: TButton;
    Panel1: TPanel;
    Label1: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Edit3: TEdit;
    Edit4: TEdit;
    CheckBox1: TCheckBox;
    ComboBox1: TComboBox;
    Edit5: TEdit;
    Edit6: TEdit;
    ListBox1: TListBox;
    Edit7: TEdit;
    Button1: TButton;
    Button3: TButton;
    Panel2: TPanel;
    Button2: TButton;
    Button4: TButton;
    Edit1: TEdit;
    Button6: TButton;
    Label15: TLabel;
    procedure Outline1Change(Sender: TObject; Node: integer);
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure CheckBox1Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure Edit8KeyPress(Sender: TObject; var Key: Char);
    procedure Edit11Change(Sender: TObject);
    procedure ListBox1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Edit7KeyPress(Sender: TObject; var Key: Char);
    procedure Edit2KeyPress(Sender: TObject; var Key: Char);
    procedure Edit1KeyPress(Sender: TObject; var Key: Char);
    procedure Outline1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Outline1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    procedure ShowOID(oid: string; ini: TIniFile; nod: integer);
    procedure ShowRA(ini: TIniFile; nod: integer);
    function DBPath: string;
    function GetAsn1Ids(onlyfirst: boolean): string;
    procedure SaveChangesIfRequired;
    procedure ShowError(msg: string);
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

uses
  SortStr;

const
  TITLE_OID = 'Object Identifiers';
  TITLE_RA = 'Registration Authorities';

procedure Split(Delimiter: string; Str: string; ListOfStrings: TStrings) ;
var
  p: integer;
begin
  ListOfStrings.Clear;
  p := Pos(Delimiter, Str);
  while p > 0 do
  begin
    ListOfStrings.Add(Copy(Str, 1, p-1));
    Delete(Str, 1, p);
    p := Pos(Delimiter, Str);
  end;
  if Str <> '' then ListOfStrings.Add(Str);
end;

procedure ExpandNodeAndParents(nod: TOutlineNode);
begin
  if nod.Parent <> nil then ExpandNodeAndParents(nod.Parent);
  nod.Expand;
end;

{ Source: Delphi 4 }
function Trim(const S: string): string;
var
  I, L: Integer;
begin
  L := Length(S);
  I := 1;
  while (I <= L) and (S[I] <= ' ') do Inc(I);
  if I > L then Result := '' else
  begin
    while S[L] <= ' ' do Dec(L);
    Result := Copy(S, I, L - I + 1);
  end;
end;

type
  TWorkItem = class(TObject)
  public
    sectionName: string;
    ini: TIniFile;
    nod: integer;
  end;

procedure TForm1.ShowOID(oid: string; ini: TIniFile; nod: integer);
var
  i: integer;
  sectionName: string;
  asn1ids: string;
  l: TList;
  sl: TStringList;
  workItem: TWorkItem;
begin
  l := TList.Create;
  sl := TStringList.Create;

  workItem := TWorkItem.Create;
  workItem.sectionName := oid;
  workItem.ini := ini;
  workItem.nod := nod;
  l.Add(workItem);

  while l.Count > 0 do
  begin
    workItem := l.Items[l.Count-1];
    oid := workItem.sectionName;
    ini := workItem.ini;
    nod := workItem.nod;
    workItem.Free;
    l.Delete(l.Count-1);

    if oid = 'OID:' then
    begin
      nod := Outline1.AddChild(nod, TITLE_OID);
    end
    else
    begin
      asn1ids := ini.ReadString(oid, 'asn1id', '');
      if ini.ReadBool(oid, 'draft', false) then
        nod := Outline1.AddChild(nod, Trim(oid+' '+Copy(asn1ids,1,Pos(',',asn1ids+',')-1))+' [DRAFT]')
      else
        nod := Outline1.AddChild(nod, Trim(oid+' '+Copy(asn1ids,1,Pos(',',asn1ids+',')-1)));
    end;
    sl.Clear;
    for i := ini.ReadInteger(oid, 'delegates', 0) downto 1 do
    begin
      sectionName := ini.ReadString(oid, 'delegate'+IntToStr(i), '');
      if sectionName = '' then continue;
      sl.Add(sectionName);
    end;
    SortSL(sl);
    for i := sl.Count-1 downto 0 do
    begin
      sectionName := sl.Strings[i];

      workItem := TWorkItem.Create;
      workItem.sectionName := sectionName;
      workItem.ini := ini;
      workItem.nod := nod;
      l.Add(workItem);
    end;
    if (oid = 'OID:') or (sl.Count < 125) then
      ExpandNodeAndParents(Outline1.Items[nod]);
  end;

  sl.Free;
  l.Free;
end;

procedure TForm1.ShowRA(ini: TIniFile; nod: integer);
var
  i: integer;
  sectionName, personname: string;
  sl: TStringList;
begin
  nod := Outline1.AddChild(nod, TITLE_RA);
  sl := TStringList.Create;
  for i := 1 to ini.ReadInteger('RA:', 'count', 0) do
  begin
    sectionName := ini.ReadString('RA:', 'ra'+IntToStr(i), '');
    if sectionName = '' then continue;
    personname := ini.ReadString(sectionName, 'name', '');
    sl.Add(Trim(sectionName + ' ' + personname));
  end;
  SortSL(sl);
  for i := 0 to sl.Count-1 do
  begin
    sectionName := sl.Strings[i];
    Outline1.AddChild(nod, sectionName);
    ComboBox1.Items.Add(Copy(sectionName,1,Pos(' ',sectionName+' ')-1));
  end;
  sl.Free;
  ExpandNodeAndParents(Outline1.Items[nod]);
end;

procedure TForm1.Outline1Change(Sender: TObject; Node: integer);
var
  ini: TIniFile;
  txtFile: string;
begin
  SaveChangesIfRequired;

  if Copy(Outline1.Items[Outline1.SelectedItem].Text, 1, 4) = 'OID:' then
  begin
    Notebook1.PageIndex := 0;
    ini := TIniFile.Create(DBPath+'OID.INI');
    try
      Edit4.Text := Copy(Outline1.Items[Outline1.SelectedItem].Text, 1,
                         Pos(' ',Outline1.Items[Outline1.SelectedItem].Text+' ')-1);
      ListBox1.Items.Clear;
      Split(',', ini.ReadString(Edit4.Text, 'asn1id', ''), ListBox1.Items);
      Edit3.Text := ini.ReadString(Edit4.Text, 'description', '');
      CheckBox1.Checked := ini.ReadBool(Edit4.Text, 'draft', false);
      txtFile := DBPath+ini.ReadString(Edit4.Text, 'information', '');
      if FileExists(txtFile) then
        Memo1.Lines.LoadFromFile(txtFile)
      else
        Memo1.Lines.Clear;
      Memo1.Modified := false;
      ComboBox1.ItemIndex := ComboBox1.Items.IndexOf(ini.ReadString(Edit4.Text, 'ra', ''));
      Edit5.Text := ini.ReadString(Edit4.Text, 'createdate', '');
      Edit6.Text := ini.ReadString(Edit4.Text, 'updatedate', '');
      Edit7.Text := '';
    finally
      ini.Free;
    end;
    Edit1.Text := '';
  end;
  if Copy(Outline1.Items[Outline1.SelectedItem].Text, 1, 3) = 'RA:' then
  begin
    Notebook1.PageIndex := 1;
    ini := TIniFile.Create(DBPath+'RA.INI');
    try
      Edit9.Text := Copy(Outline1.Items[Outline1.SelectedItem].Text, 1,
                         Pos(' ',Outline1.Items[Outline1.SelectedItem].Text+' ')-1);
      Edit10.Text := ini.ReadString(Edit9.Text, 'createdate', '');
      Edit11.Text := ini.ReadString(Edit9.Text, 'name', '');
      Edit12.Text := ini.ReadString(Edit9.Text, 'email', '');
      Edit13.Text := ini.ReadString(Edit9.Text, 'phone', '');
      Edit14.Text := ini.ReadString(Edit9.Text, 'updatedate', '');
    finally
      ini.Free;
    end;
  end;
  if Outline1.Items[Outline1.SelectedItem].Text = TITLE_OID then
  begin
    Notebook1.PageIndex := 2;
    Edit2.Text := '';
  end;
  if Outline1.Items[Outline1.SelectedItem].Text = TITLE_RA then
  begin
    Notebook1.PageIndex := 3;
    Edit8.Text := '';
  end;
end;

procedure TForm1.FormShow(Sender: TObject);
var
  nod, raroot: integer;
  ini: TIniFile;
begin
  ComboBox1.Clear;
  Outline1.Clear;
  nod := 0;

  ini := TIniFile.Create(DBPath+'OID.INI');
  try
    ShowOID('OID:', ini, nod);
  finally
    ini.Free;
  end;

  ini := TIniFile.Create(DBPath+'RA.INI');
  try
    ShowRa(ini, nod);
  finally
    ini.Free;
  end;

  Outline1Click(Outline1);
end;

function Asn1IdValid(asn1id: string): boolean;
var
  i: integer;
begin
  if asn1id = '' then
  begin
    result := false;
    exit;
  end;

  if not (asn1id[1] in ['a'..'z']) then
  begin
    result := false;
    exit;
  end;

  for i := 2 to Length(asn1id) do
  begin
    if not (asn1id[1] in ['a'..'z', 'A'..'Z', '0'..'9', '-']) then
    begin
      result := false;
      exit;
    end;
  end;

  result := true;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  asn1id: string;
  i: integer;
begin
  asn1id := Edit7.Text;
  if asn1id = '' then exit;
  for i := 0 to ListBox1.Items.Count-1 do
  begin
    if ListBox1.Items.Strings[i] = asn1id then ShowError('Item already exists');
  end;
  if not Asn1IdValid(asn1id) then ShowError('Invalid alphanumeric identifier');
  ListBox1.Items.Add(asn1id);
  Outline1.Items[Outline1.SelectedItem].Text := Trim(Edit4.Text + ' ' + GetAsn1Ids(true));
  Edit7.Text := '';
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  if (ListBox1.Items.Count > 0) and ListBox1.Selected[ListBox1.ItemIndex] then
  begin
    ListBox1.Items.Delete(ListBox1.ItemIndex);
  end;
  Outline1.Items[Outline1.SelectedItem].Text := Trim(Edit4.Text + ' ' + GetAsn1Ids(true));
end;

function IsPositiveNumber(str: string): boolean;
var
  i: integer;
begin
  if (str = '') then
  begin
    result := false;
    exit;
  end;

  result := true;
  for i := 1 to Length(str) do
  begin
    if not (str[i] in ['0'..'9']) then
    begin
      result := false;
      exit;
    end;
  end;

  if (str[1] = '0') and (str <> '0') then
  begin
    result := false;
    exit;
  end;
end;

procedure TForm1.Button4Click(Sender: TObject);
var
  ini: TIniFile;
  i, di: integer;
  oid, parent_oid, new_value: string;
  nod: integer;
  candidate: string;
begin
  if Notebook1.PageIndex = 0 then new_value := Edit1.Text;
  if Notebook1.PageIndex = 2 then new_value := Edit2.Text;

  new_value := Trim(new_value);
  if new_value = '' then exit;

  if not IsPositiveNumber(new_value) then ShowError('Not a valid number');

  if Notebook1.PageIndex = 0 then
  begin
    oid := Edit4.Text + '.' + new_value;
    parent_oid := Edit4.Text;
  end
  else
  begin
    oid := 'OID:' + new_value;
    parent_oid := 'OID:';
  end;

  if Outline1.Items[Outline1.SelectedItem].HasItems then
  for i := Outline1.Items[Outline1.SelectedItem].GetFirstChild to Outline1.Items[Outline1.SelectedItem].GetLastChild do
  begin
    candidate := Copy(Trim(Outline1.Lines[i-1]), 1, Pos(' ',Trim(Outline1.Lines[i-1])+' ')-1);
    if oid = candidate then ShowError('Item already exists');
  end;

  if (parent_oid = 'OID:') and (StrToInt(new_value) > 2) then ShowError('Number must not exceed 2');
  if (parent_oid = 'OID:0') and (StrToInt(new_value) > 39) then ShowError('Number must not exceed 39');
  if (parent_oid = 'OID:1') and (StrToInt(new_value) > 39) then ShowError('Number must not exceed 39');

  ini := TIniFile.Create(DBPath+'OID.INI');
  try
    nod := Outline1.AddChild(Outline1.SelectedItem, oid);
    ComboBox1.Text := ini.ReadString(parent_oid, 'ra', '');

    di := ini.ReadInteger(parent_oid, 'delegates', 0);
    ini.WriteInteger(parent_oid, 'delegates', di+1);
    ini.WriteString(parent_oid, 'delegate'+IntToStr(di+1), oid);

    ini.WriteString(oid, 'createdate', DateToStr(date));
    ini.WriteString(oid, 'ra', ComboBox1.Text);

    if Notebook1.PageIndex = 0 then Edit1.Text := '';
    if Notebook1.PageIndex = 2 then Edit2.Text := '';

    Outline1.SelectedItem := nod;

    { ini.UpdateFile; }
  finally
    ini.Free;
  end;

  ShowMessage('Created: ' + oid);
end;

procedure TForm1.Button7Click(Sender: TObject);
var
  ini: TIniFile;
  di: integer;
  nod: integer;
  sectionName, new_value, candidate: string;
  i: integer;
begin
  ini := TIniFile.Create(DBPath+'RA.INI');
  try
    new_value := Edit8.Text;
    new_value := Trim(new_value);
    if new_value = '' then exit;

    sectionName := 'RA:'+new_value;

    if Outline1.Items[Outline1.SelectedItem].HasItems then
    for i := Outline1.Items[Outline1.SelectedItem].GetFirstChild to Outline1.Items[Outline1.SelectedItem].GetLastChild do
    begin
      candidate := Trim(Outline1.Lines[i-1]);
      if sectionName = candidate then ShowError('Item already exists');
    end;

    di := ini.ReadInteger('RA:', 'count', 0);
    ini.WriteInteger('RA:', 'count', di+1);
    ini.WriteString('RA:', 'ra'+IntToStr(di+1), sectionName);

    nod := Outline1.AddChild(Outline1.SelectedItem, sectionName);

    ini.WriteString(sectionName, 'createdate', DateToStr(date));

    Edit8.Text := '';

    Outline1.SelectedItem := nod;

    ini.WriteString(sectionName, 'createdate', DateToStr(date));

    { ini.UpdateFile; }
  finally
    ini.Free;
  end;

  ComboBox1.Items.Add(sectionName);

  ShowMessage('Created: ' + sectionName);
end;

procedure IniReadSections(ini: TIniFile; Strings: TStrings);
const
  BufSize = 16384;
var
  Buffer, P: PChar;
  FFileName: string;
begin
  GetMem(Buffer, BufSize);
  try
    Strings.BeginUpdate;
    try
      Strings.Clear;
      FFileName := ini.FileName;
      if GetPrivateProfileString(nil, nil, nil, Buffer, BufSize,
        @FFileName[1]) <> 0 then
      begin
        P := Buffer;
        while P^ <> #0 do
        begin
          Strings.Add(StrPas(P));
          Inc(P, StrLen(P) + 1);
        end;
      end;
    finally
      Strings.EndUpdate;
    end;
  finally
    FreeMem(Buffer, BufSize);
  end;
end;

procedure TForm1.Button6Click(Sender: TObject);
var
  ini: TIniFile;
  nod: TOutlineNode;
  parent_oid, this_oid: string;
  i: integer;
  sl: TStringList;
begin
  if MessageDlg('Are you sure?', mtConfirmation, mbYesNoCancel, 0) <> mrYes then exit;

  ini := TIniFile.Create(DBPath+'OID.INI');
  try
    this_oid := Edit4.Text;

    if Outline1.Items[Outline1.SelectedItem].Parent.Text = TITLE_OID then
      parent_oid := 'OID:'
    else
      parent_oid := Copy(Outline1.Items[Outline1.SelectedItem].Parent.Text, 1,
                         Pos(' ', Outline1.Items[Outline1.SelectedItem].Parent.Text+' ')-1);

    nod := Outline1.Items[Outline1.SelectedItem];
    Outline1.SelectedItem := nod.Parent.Index;
    Outline1.Delete(nod.Index);

    ini.EraseSection(this_oid);

    sl := TStringList.Create;
    IniReadSections(ini, sl);
    for i := 0 to sl.Count-1 do
    begin
      if Copy(sl.Strings[i], 1, Length(this_oid)+1) = this_oid+'.' then
      begin
        ini.EraseSection(sl.Strings[i]);
      end;
    end;
    sl.Free;

    for i := 1 to ini.ReadInteger(parent_oid, 'delegates', 0) do
    begin
      if ini.ReadString(parent_oid, 'delegate'+IntToStr(i), '') = this_oid then
      begin
        ini.WriteString(parent_oid, 'delegate'+IntToStr(i), '');
      end;
    end;

    { ini.UpdateFile; }
  finally
    ini.Free;
  end;
end;

procedure TForm1.Button8Click(Sender: TObject);
var
  ini: TIniFile;
  nod: TOutlineNode;
  parent_ra, this_ra: string;
  i: integer;
begin
  if MessageDlg('Are you sure?', mtConfirmation, mbYesNoCancel, 0) <> mrYes then exit;

  ini := TIniFile.Create(DBPath+'RA.INI');
  try
    this_ra := Copy(Outline1.Items[Outline1.SelectedItem].Text, 1, Pos(' ',Outline1.Items[Outline1.SelectedItem].Text+' ')-1);
    if Outline1.Items[Outline1.SelectedItem].Parent.Text = TITLE_RA then
      parent_ra := 'RA:'
    else
      parent_ra := Copy(Outline1.Items[Outline1.SelectedItem].Parent.Text, 1,
                        Pos(' ', Outline1.Items[Outline1.SelectedItem].Parent.Text+' ')-1);

    nod := Outline1.Items[Outline1.SelectedItem];
    Outline1.SelectedItem := nod.Parent.Index;
    Outline1.Delete(nod.Index);

    ini.EraseSection(this_ra);

    for i := 1 to ini.ReadInteger(parent_ra, 'count', 0) do
    begin
      if ini.ReadString(parent_ra, 'ra'+IntToStr(i), '') = this_ra then
      begin
        ini.WriteString(parent_ra, 'ra'+IntToStr(i), '');
      end;
    end;

    ComboBox1.Items.Delete(ComboBox1.Items.IndexOf(this_ra));

    { ini.UpdateFile; }
  finally
    ini.Free;
  end;
end;

function RandomStr(len: integer): string;
var
  i: integer;
begin
  result := '';
  for i := 1 to len do
  begin
    result := result + Chr(ord('A') + Random(26));
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  ini: TIniFile;
  txtFile, asn1s: string;
  modified: boolean;
begin
  { Attention: Do not rely on Outline1.Items[Outline1.SelectedItem].Text, because Button2.Click
    will be called in Outline1OnChange()! }

  ini := TIniFile.Create(DBPath+'OID.INI');
  try
    modified := false;

    if ini.ReadString(Edit4.Text, 'ra', '') <> ComboBox1.Text then
    begin
      modified := true;
      ini.WriteString(Edit4.Text, 'ra', ComboBox1.Text);
    end;

    if ini.ReadString(Edit4.Text, 'description', '') <> Edit3.Text then
    begin
      modified := true;
      ini.WriteString(Edit4.Text, 'description', Edit3.Text);
    end;

    if ini.ReadBool(Edit4.Text, 'draft', false) <> CheckBox1.Checked then
    begin
      modified := true;
      ini.WriteBool(Edit4.Text, 'draft', CheckBox1.Checked);
    end;

    if Memo1.Modified then
    begin
      modified := true;
      if Trim(Memo1.Text) = '' then
      begin
        txtFile := ini.ReadString(Edit4.Text, 'information', '');
        if FileExists(DBPath+txtFile) then
        begin
          SysUtils.DeleteFile(DBPath+txtFile);
        end;
        if txtFile <> '' then
        begin
          ini.WriteString(Edit4.Text, 'information', '')
        end;
      end
      else
      begin
        txtFile := ini.ReadString(Edit4.Text, 'information', '');
        if txtFile = '' then
        begin
          repeat
            txtFile := RandomStr(8) + '.TXT';
          until not FileExists(DBPath+txtFile);
          ini.WriteString(Edit4.Text, 'information', txtFile);
        end;

        Memo1.Lines.SaveToFile(DBPath+txtFile);
        Memo1.Modified := false;
      end;
    end;

    asn1s := GetAsn1Ids(false);
    if ini.ReadString(Edit4.Text, 'asn1id', '') <> asn1s then
    begin
      modified := true;
      ini.WriteString(Edit4.Text, 'asn1id', asn1s);
    end;

    if modified then
    begin
      ini.WriteString(Edit4.Text, 'updatedate', DateToStr(Date));
      { ini.Updatefile; }
    end;
  finally
    ini.Free;
  end;
end;

function TForm1.GetAsn1Ids(onlyfirst: boolean): string;
var
  i: integer;
begin
  result := '';
  for i := 0 to ListBox1.Items.Count-1 do
  begin
    if result = '' then
      result := ListBox1.Items.Strings[i]
    else if not onlyfirst then
      result := result + ',' + ListBox1.Items.Strings[i];
  end;
end;

function IniValueExists(ini: TIniFile; const Section, Ident: string): Boolean;
var
  S: TStrings;
begin
  S := TStringList.Create;
  try
    ini.ReadSection(Section, S);
    Result := S.IndexOf(Ident) > -1;
  finally
    S.Free;
  end;
end;

var
  MkDirTriedOnce: boolean; { Avoid that the debugger always shows the exception }
procedure MakeDirIfRequired(dirname: string);
begin
  if dirname[Length(dirname)] = '\' then dirname := Copy(dirname, 1, Length(dirname)-1);

  if not MkDirTriedOnce then
  begin
    try
      MkDir(dirname);
    except
    end;
    MkDirTriedOnce := true;
  end;
end;

function TForm1.DBPath: string;
var
  ini: TIniFile;
begin
  ini := TIniFile.Create('.\OIDPLUS.INI');
  try
    if not IniValueExists(ini, 'SETTINGS', 'DATA') then
    begin
      result := 'DB\';
      ini.WriteString('SETTINGS', 'DATA', result);
      { ini.UpdateFile; }
    end
    else
    begin
      result := ini.ReadString('SETTINGS', 'DATA', 'DB\');
    end;
    MakeDirIfRequired(result);
  finally
    ini.Free;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Notebook1.PageIndex := 2;
  Randomize;
end;

procedure TForm1.SaveChangesIfRequired;
begin
  if Notebook1.PageIndex = 0 then Button2.Click; { Save changes }
  if Notebook1.PageIndex = 1 then Button9.Click; { Save changes }
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  SaveChangesIfRequired;
  CanClose := true;
end;

procedure TForm1.CheckBox1Click(Sender: TObject);
begin
  if CheckBox1.Checked then
    Outline1.Items[Outline1.SelectedItem].Text := Trim(Edit4.Text+' '+GetAsn1Ids(true))+' [DRAFT]'
  else
    Outline1.Items[Outline1.SelectedItem].Text := Trim(Edit4.Text+' '+GetAsn1Ids(true));
end;

procedure TForm1.ShowError(msg: string);
begin
  MessageDlg(msg, mtError, [mbOk], 0);
  Abort;
end;

procedure TForm1.Button9Click(Sender: TObject);
var
  ini: TIniFile;
  txtFile, asn1s: string;
  modified: boolean;
begin
  { Attention: Do not rely on Outline1.Items[Outline1.SelectedItem].Text, because Button9.Click
   will be called in Outline1OnChange()! }

  ini := TIniFile.Create(DBPath+'RA.INI');
  try
    modified := false;
    if ini.ReadString(Edit9.Text, 'name', '') <> Edit11.Text then
    begin
      modified := true;
      ini.WriteString(Edit9.Text, 'name', Edit11.Text);
    end;
    if ini.ReadString(Edit9.Text, 'email', '') <> Edit12.Text then
    begin
      modified := true;
      ini.WriteString(Edit9.Text, 'email', Edit12.Text);
    end;
    if ini.ReadString(Edit9.Text, 'phone', '') <> Edit13.Text then
    begin
      modified := true;
      ini.WriteString(Edit9.Text, 'phone', Edit13.Text);
    end;
    if modified then
    begin
      ini.WriteString(Edit9.Text, 'updatedate', DateToStr(Date));
      { ini.Updatefile; }
    end;
  finally
    ini.Free;
  end;
end;

procedure TForm1.Edit8KeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Button7.Click;
    Key := #0;
    Exit;
  end;
  if Key = #8(*backspace*) then exit;
  if Key in ['a'..'z'] then Key := UpCase(Key);
  if not (Key in ['A'..'Z', '-']) then
  begin
    MessageBeep(0);
    Key := #0;
  end;
end;

procedure TForm1.Edit11Change(Sender: TObject);
begin
  Outline1.Items[Outline1.SelectedItem].Text := Trim(Edit9.Text + ' ' + Edit11.Text);
end;

procedure TForm1.ListBox1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  If Key = 46(*DEL*) then
  begin
    Button3.Click;
    Key := 0;
  end;
end;

procedure TForm1.Edit7KeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Button1.Click;
    Key := #0;
  end;
end;

procedure TForm1.Edit2KeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Button5.Click;
    Key := #0;
  end;
end;

procedure TForm1.Edit1KeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Button4.Click;
    Key := #0;
  end;
end;

procedure TForm1.Outline1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = 46(*DEL*) then
  begin
    if Copy(Outline1.Items[Outline1.SelectedItem].Text, 1, 4) = 'OID:' then
    begin
      Button6.Click;
    end
    else if Copy(Outline1.Items[Outline1.SelectedItem].Text, 1, 3) = 'RA:' then
    begin
      Button8.Click;
    end
    else
    begin
      MessageBeep(0);
    end;

    Key := 0;
  end;
end;

procedure TForm1.Outline1Click(Sender: TObject);
begin
  Outline1Change(Sender, Outline1.SelectedItem);
end;

end.
