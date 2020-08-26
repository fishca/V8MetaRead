unit Parse_tree;

interface

uses System.Classes, System.IOUtils, System.SysUtils, Winapi.Windows, NodeTypes, MessageRegistration,
     System.RegularExpressions;

const
  exp_number     = '^-?\\d+$';
  exp_number_exp = '^-?\\d+(\\.?\\d*)?((e|E)-?\\d+)?$';
  exp_guid       = '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$';
  exp_binary     = '^#base64:[0-9a-zA-Z\\+=\\r\\n\\/]*$';
  exp_binary2    = '^[0-9a-zA-Z\\+=\\r\\n\\/]+$';
  exp_link       = '^[0-9]+:[0-9a-fA-F]{32}$';
  exp_binary_d   = '^#data:[0-9a-zA-Z\\+=\\r\\n\\/]*$';


type

_state = (
		s_value,              // ожидание начала значения
		s_delimitier,         // ожидание разделителя
		s_string,             // режим ввода строки
		s_quote_or_endstring, // режим ожидания конца строки или двойной кавычки
		s_nonstring           // режим ввода значения не строки
);

tree = class
private
  value: string;
  atype: node_type;
  num_subnode: Integer;
  parent : tree;
  next   : tree;
  prev   : tree;
  first  : tree;
  last   : tree;
  index : Integer;
public
  constructor Create(_value : string; _type: node_type; _parent: tree);
  destructor Destroy();

  function add_child(_value: String; _type: node_type): tree; overload;
  function add_child(): tree; overload;
  function add_node(): tree;
  function get_value(): string;
  function get_type(): node_type;
  function get_num_subnode(): Integer;
  function get_subnode(_index:Integer) : tree; overload;
  function get_subnode(node_name: string) : tree; overload;
  function get_next(): tree;
  function get_parent(): tree;
  function get_first(): tree;
  procedure set_value(v: string; t: node_type);
  procedure outtext(var text: string);
  function path():string;

end;

function parse_1Ctext(text: string; err: MessageRegistrator; path: string): tree;
function parse_1Cstream(str: TStream; err: MessageRegistrator; path: string): tree;
function test_parse_1Ctext(str: TStream; err: MessageRegistrator; path: string): Boolean;
function classification_value(value: string): node_type;
function outtext(t: tree): string;

implementation

function outtext(t: tree): string;
var
  text: string;
begin
  if t <> nil then
    if t.get_first <> nil then
      t.get_first.outtext(text);

   Result := text;
end;

function classification_value(value: string): node_type;
var
  RegEx: TRegEx;
begin
  if value.Length = 0 then
    Result := nd_empty;

  RegEx := TRegEx.Create(exp_number);
  if RegEx.IsMatch(value) then
    Result := nd_number;

  RegEx := TRegEx.Create(exp_number_exp);
  if RegEx.IsMatch(value) then
    Result := nd_number_exp;

  RegEx := TRegEx.Create(exp_guid);
  if RegEx.IsMatch(value) then
    Result := nd_guid;

  RegEx := TRegEx.Create(exp_binary);
  if RegEx.IsMatch(value) then
    Result := nd_binary;

  RegEx := TRegEx.Create(exp_link);
  if RegEx.IsMatch(value) then
    Result := nd_link;

  RegEx := TRegEx.Create(exp_binary2);
  if RegEx.IsMatch(value) then
    Result := nd_binary2;

  RegEx := TRegEx.Create(exp_binary_d);
  if RegEx.IsMatch(value) then
    Result := nd_binary_d;

end;

function parse_1Ctext(text: string; err: MessageRegistrator; path: string): tree;
var
  __curvalue__ : TStringBuilder;
  curvalue : string;
  ret: tree;
  t: tree;
  len: Integer;
  state: _state;
  i: Integer;
  sym: Char;
  nt: node_type;

begin
  __curvalue__ := TStringBuilder.Create;
  state := s_value;
  len := text.Length;

  ret := tree.Create('', nd_list, nil);
  t := ret;
  for i := 1 to len do
  begin
    sym := text[i];
    if sym = #0 then
      Break;

    case state of
      s_value:
        begin
          case sym of
            ' ', #$9, #10, #13 :
                  begin

                  end;
            '"':
                  begin
						        __curvalue__.Clear();
						        state := s_string;
                  end;
            '{':
                  begin
         						t := tree.Create('', nd_list, t);
                  end;
            '}':
                  begin
                    if t.get_first <> nil then
                      t.add_child('', nd_empty);
                    t := t.get_parent;
                    if t = nil then
                      begin
                        if err <> nil then
                          err.AddError('Ошибка формата потока. Лишняя закрывающая скобка }.', 'Позиция', IntToStr(i), 'Путь', path);
                        ret.Free;
                        Result := nil;
                      end;

         						state := s_delimitier;
                  end;
            ',':
                  begin
                    t.add_child('', nd_empty);
                  end;
            else
                  begin
                    __curvalue__.Clear;
                    __curvalue__.Append(sym);
                    state := s_nonstring;
                  end;
          end;
        end;
      s_delimitier:
        begin
          case sym of
            ' ', #$9, #10, #13 :
                  begin

                  end;
            ',':
                  begin
						        state := s_value;
                  end;
            '}':
                  begin
                    t := t.get_parent;
                    if t = nil then
                      begin
                        if err <> nil then
                          err.AddError('Ошибка формата потока. Лишняя закрывающая скобка }.', 'Позиция', IntToStr(i), 'Путь', path);
                        ret.Free;
                        Result := nil;
                      end;
                  end;
            else
                  begin
                        if err <> nil then
                          err.AddError('Ошибка формата потока. Ошибочный символ в режиме ожидания разделителя.', 'Символ', sym, 'Код символа', IntToStr(Ord(sym)), 'Путь', path);
                        ret.Free;
                        Result := nil;
                  end;
          end;

        end;
      s_string:
        begin
          if sym = '"' then
            state := s_quote_or_endstring
          else
            __curvalue__.Append(sym);
        end;
      s_quote_or_endstring:
        begin
          if sym = '"' then
            begin
              __curvalue__.Append(sym);
              state := s_string;
            end
          else
            begin
              t.add_child(__curvalue__.ToString, nd_string);
              case sym of
                ' ', #$9, #10, #13 :
                  begin
                    state := s_delimitier;
                  end;
                ',':
                  begin
						        state := s_value;
                  end;
                '}':
                  begin
                    t := t.get_parent;
                    if t = nil then
                      begin
                        if err <> nil then
                          err.AddError('Ошибка формата потока. Лишняя закрывающая скобка }.', 'Позиция', IntToStr(i), 'Путь', path);
                        ret.Free;
                        Result := nil;
                      end;

						        state := s_delimitier;
                  end;
                else
                  begin
                    if err <> nil then
                      err.AddError('Ошибка формата потока. Ошибочный символ в режиме ожидания разделителя.', 'Символ', sym, 'Код символа',IntToStr(Ord(sym)), 'Путь', path);
                    ret.Free;
                    Result := nil;
                  end;
              end;
            end;

        end;
      s_nonstring:
        case sym of
          ',':
            begin
              curvalue := __curvalue__.ToString;
              nt := classification_value(curvalue);
              if nt = nd_unknown then
                if err <> nil then
                  err.AddError('Ошибка формата потока. Неизвестный тип значения.', 'Значение', curvalue, 'Путь', path);
              t.add_child(curvalue, nt);
              state := s_value;
            end;
          '}':
            begin
              curvalue := __curvalue__.ToString;
              nt := classification_value(curvalue);
              if nt = nd_unknown then
                if err <> nil then
                  err.AddError('Ошибка формата потока. Неизвестный тип значения.', 'Значение', curvalue, 'Путь', path);
              t.add_child(curvalue, nt);
              t := t.get_parent;
              if t = nil then
              begin
                if err <> nil then
                  err.AddError('Ошибка формата потока. Лишняя закрывающая скобка }.', 'Позиция', IntToStr(i), 'Путь', path);
                ret.Free;
                Result := nil;
              end;
              state := s_delimitier;
            end;
        else
          begin
            __curvalue__.Append(sym);
          end;
        end;
      else
        begin
          if err <> nil then
            err.AddError('Ошибка формата потока. Неизвестный режим разбора.', 'Режим разбора', IntToStr(Integer(state)), 'Путь', path);
          ret.Free;
          Result := nil;
        end;
    end;

  end;
  if state = s_nonstring then
    begin
      curvalue := __curvalue__.ToString;
      nt := classification_value(curvalue);
      if nt = nd_unknown then
        if err <> nil then
          err.AddError('Ошибка формата потока. Неизвестный тип значения.', 'Значение', curvalue, 'Путь', path);
      t.add_child(curvalue, nt);
    end
  else if state = s_quote_or_endstring then
    t.add_child(__curvalue__.ToString, nd_string)
  else if state <> s_delimitier then
    begin
      if err <> nil then
        err.AddError('Ошибка формата потока. Незавершенное значение.', 'Режим разбора', IntToStr(Integer(state)), 'Путь', path);
      ret.Free;
      Result := nil;
    end;

  if t <> ret then
  begin
      if err <> nil then
        err.AddError('Ошибка формата потока. Не хватает закрывающих скобок } в конце текста разбора.', 'Путь', path);
      ret.Free;
      Result := nil;

  end;

  Result := ret;
end;

function parse_1Cstream(str: TStream; err: MessageRegistrator; path: string): tree;
var
  __curvalue__ : TStringBuilder;
  state: _state;
  curvalue: string;
  ret: tree;
  t: tree;
  i: Integer;
  sym: Char;
  _sym: Integer;
  nt: node_type;
  reader: TStreamReader;
begin
  state := s_value;
  __curvalue__ := TStringBuilder.Create;
  ret := tree.Create('', nd_list, nil);
  t := ret;
  reader := TStreamReader.Create(str, True);

  _sym := reader.Read;
  i := 1;

  while _sym > 0 do
  begin
    sym := Char(_sym);

    case state of
      s_value:
        begin
          case sym of
            ' ', #$9, #10, #13 :
                  begin

                  end;
            '"':
                  begin
						        __curvalue__.Clear();
						        state := s_string;
                  end;
            '{':
                  begin
         						t := tree.Create('', nd_list, t);
                  end;
            '}':
                  begin
                    if t.get_first <> nil then
                      t.add_child('', nd_empty);
                    t := t.get_parent;
                    if t = nil then
                      begin
                        if err <> nil then
                          err.AddError('Ошибка формата потока. Лишняя закрывающая скобка }.', 'Позиция', IntToStr(i), 'Путь', path);
                        ret.Free;
                        Result := nil;
                      end;

         						state := s_delimitier;
                  end;
            ',':
                  begin
                    t.add_child('', nd_empty);
                  end;
            else
                  begin
                    __curvalue__.Clear;
                    __curvalue__.Append(sym);
                    state := s_nonstring;
                  end;
          end;
        end;
      s_delimitier:
        begin
          case sym of
            ' ', #$9, #10, #13 :
                  begin

                  end;
            ',':
                  begin
						        state := s_value;
                  end;
            '}':
                  begin
                    t := t.get_parent;
                    if t = nil then
                      begin
                        if err <> nil then
                          err.AddError('Ошибка формата потока. Лишняя закрывающая скобка }.', 'Позиция', IntToStr(i), 'Путь', path);
                        ret.Free;
                        Result := nil;
                      end;
                  end;
            else
                  begin
                        if err <> nil then
                          err.AddError('Ошибка формата потока. Ошибочный символ в режиме ожидания разделителя.', 'Символ', sym, 'Код символа', IntToStr(Ord(sym)), 'Путь', path);
                        ret.Free;
                        Result := nil;
                  end;
          end;

        end;
      s_string:
        begin
          if sym = '"' then
            state := s_quote_or_endstring
          else
            __curvalue__.Append(sym);
        end;
      s_quote_or_endstring:
        begin
          if sym = '"' then
            begin
              __curvalue__.Append(sym);
              state := s_string;
            end
          else
            begin
              t.add_child(__curvalue__.ToString, nd_string);
              case sym of
                ' ', #$9, #10, #13 :
                  begin
                    state := s_delimitier;
                  end;
                ',':
                  begin
						        state := s_value;
                  end;
                '}':
                  begin
                    t := t.get_parent;
                    if t = nil then
                      begin
                        if err <> nil then
                          err.AddError('Ошибка формата потока. Лишняя закрывающая скобка }.', 'Позиция', IntToStr(i), 'Путь', path);
                        ret.Free;
                        Result := nil;
                      end;

						        state := s_delimitier;
                  end;
                else
                  begin
                    if err <> nil then
                      err.AddError('Ошибка формата потока. Ошибочный символ в режиме ожидания разделителя.', 'Символ', sym, 'Код символа',IntToStr(Ord(sym)), 'Путь', path);
                    ret.Free;
                    Result := nil;
                  end;
              end;
            end;

        end;
      s_nonstring:
        case sym of
          ',':
            begin
              curvalue := __curvalue__.ToString;
              nt := classification_value(curvalue);
              if nt = nd_unknown then
                if err <> nil then
                  err.AddError('Ошибка формата потока. Неизвестный тип значения.', 'Значение', curvalue, 'Путь', path);
              t.add_child(curvalue, nt);
              state := s_value;
            end;
          '}':
            begin
              curvalue := __curvalue__.ToString;
              nt := classification_value(curvalue);
              if nt = nd_unknown then
                if err <> nil then
                  err.AddError('Ошибка формата потока. Неизвестный тип значения.', 'Значение', curvalue, 'Путь', path);
              t.add_child(curvalue, nt);
              t := t.get_parent;
              if t = nil then
              begin
                if err <> nil then
                  err.AddError('Ошибка формата потока. Лишняя закрывающая скобка }.', 'Позиция', IntToStr(i), 'Путь', path);
                ret.Free;
                Result := nil;
              end;
              state := s_delimitier;
            end;
        else
          begin
            __curvalue__.Append(sym);
          end;
        end;
      else
        begin
          if err <> nil then
            err.AddError('Ошибка формата потока. Неизвестный режим разбора.', 'Режим разбора', IntToStr(Integer(state)), 'Путь', path);
          ret.Free;
          Result := nil;
        end;
    end;

    _sym := reader.Read;
    Inc(i);

  end;

  if state = s_nonstring then
    begin
      curvalue := __curvalue__.ToString;
      nt := classification_value(curvalue);
      if nt = nd_unknown then
        if err <> nil then
          err.AddError('Ошибка формата потока. Неизвестный тип значения.', 'Значение', curvalue, 'Путь', path);
      t.add_child(curvalue, nt);
    end
  else if state = s_quote_or_endstring then
    t.add_child(__curvalue__.ToString, nd_string)
  else if state <> s_delimitier then
    begin
      if err <> nil then
        err.AddError('Ошибка формата потока. Незавершенное значение.', 'Режим разбора', IntToStr(Integer(state)), 'Путь', path);
      ret.Free;
      Result := nil;
    end;

  if t <> ret then
  begin
      if err <> nil then
        err.AddError('Ошибка формата потока. Не хватает закрывающих скобок } в конце текста разбора.', 'Путь', path);
      ret.Free;
      Result := nil;

  end;

  Result := ret;
end;

function test_parse_1Ctext(str: TStream; err: MessageRegistrator; path: string): Boolean;
var
  __curvalue__ : TStringBuilder;
  state: _state;
  curvalue: string;
  ret: Boolean;
  level: Integer;
  i: Integer;
  sym: Char;
  _sym: Integer;
  nt: node_type;
  reader: TStreamReader;
begin
  state := s_value;
  __curvalue__ := TStringBuilder.Create;
  ret := True;

  level := 0;

  reader := TStreamReader.Create(str, True);

  _sym := reader.Read;
  i := 1;

  while _sym > 0 do
  begin
    sym := Char(_sym);

    case state of
      s_value:
        begin
          case sym of
            ' ', #9, #10, #13 :
                  begin

                  end;
            '"':
                  begin
						        __curvalue__.Clear();
						        state := s_string;
                  end;
            '{':
                  begin
         						Inc(level);
                  end;
            '}':
                  begin
                    if level <= 0 then
                      begin
                        if err <> nil then
                          err.AddError('Ошибка формата потока. Лишняя закрывающая скобка }.', 'Позиция', IntToStr(i), 'Путь', path);
                        ret := False;
                      end;
         						state := s_delimitier;
                    Dec(level);
                  end;
            else
                  begin
                    __curvalue__.Clear;
                    __curvalue__.Append(sym);
                    state := s_nonstring;
                  end;
          end;
        end;
      s_delimitier:
        begin
          case sym of
            ' ', #9, #10, #13 :
                  begin

                  end;
            ',':
                  begin
						        state := s_value;
                  end;
            '}':
                  begin
                    if level <= 0 then
                      begin
                        if err <> nil then
                          err.AddError('Ошибка формата потока. Лишняя закрывающая скобка }.', 'Позиция', IntToStr(i), 'Путь', path);
                        ret := False;
                      end;
                    Dec(level);
                  end;
            else
                  begin
                    if err <> nil then
                      err.AddError('Ошибка формата потока. Ошибочный символ в режиме ожидания разделителя.', 'Символ', sym, 'Код символа', IntToStr(Ord(sym)), 'Путь', path);
                    reader.Free;
                    Result := ret;
                  end;
          end;

        end;
      s_string:
        begin
          if sym = '"' then
            state := s_quote_or_endstring
          else
            __curvalue__.Append(sym);
        end;
      s_quote_or_endstring:
        begin
          if sym = '"' then
            begin
              __curvalue__.Append(sym);
              state := s_string;
            end
          else
            begin

              case sym of
                ' ', #9, #10, #13 :
                  begin
                    state := s_delimitier;
                  end;
                ',':
                  begin
						        state := s_value;
                  end;
                '}':
                  begin
                    if level <= 0 then
                      begin
                        if err <> nil then
                          err.AddError('Ошибка формата потока. Лишняя закрывающая скобка }.', 'Позиция', IntToStr(i), 'Путь', path);
                        ret := False;
                      end;
                    Dec(level);

						        state := s_delimitier;
                  end;
                else
                  begin
                    if err <> nil then
                      err.AddError('Ошибка формата потока. Ошибочный символ в режиме ожидания разделителя.', 'Символ', sym, 'Код символа',IntToStr(Ord(sym)), 'Путь', path);
                    reader.Free;
                    Result := ret;
                  end;
              end;
            end;

        end;
      s_nonstring:
        case sym of
          ',':
            begin
              curvalue := __curvalue__.ToString;
              nt := classification_value(curvalue);
              if nt = nd_unknown then
              begin
                if err <> nil then
                  err.AddError('Ошибка формата потока. Неизвестный тип значения.', 'Значение', curvalue, 'Путь', path);
                ret := False;
              end;
              state := s_value;
            end;
          '}':
            begin
              curvalue := __curvalue__.ToString;
              nt := classification_value(curvalue);
              if nt = nd_unknown then
                begin
                  if err <> nil then
                    err.AddError('Ошибка формата потока. Неизвестный тип значения.', 'Значение', curvalue, 'Путь', path);
                  ret := False;
                end;

              if level <= 0 then
                begin
                  if err <> nil then
                    err.AddError('Ошибка формата потока. Лишняя закрывающая скобка }.', 'Позиция', IntToStr(i), 'Путь', path);
                  ret := False;
                end;
              Dec(level);
              state := s_delimitier;
            end;
        else
          begin
            __curvalue__.Append(sym);
          end;
        end;
      else
        begin
          if err <> nil then
            err.AddError('Ошибка формата потока. Неизвестный режим разбора.', 'Режим разбора', IntToStr(Integer(state)), 'Путь', path);
          ret := False;
        end;
    end;

    _sym := reader.Read;
    Inc(i);
  end;

  if state = s_nonstring then
    begin
      curvalue := __curvalue__.ToString;
      nt := classification_value(curvalue);
      if nt = nd_unknown then
      begin
        if err <> nil then
          err.AddError('Ошибка формата потока. Неизвестный тип значения.', 'Значение', curvalue, 'Путь', path);
        ret := False;
      end;
    end
  else if state = s_quote_or_endstring then

  else if state <> s_delimitier then
    begin
      if err <> nil then
        err.AddError('Ошибка формата потока. Незавершенное значение.', 'Режим разбора', IntToStr(Integer(state)), 'Путь', path);
      ret := False;
    end;


  if level > 0 then
  begin
      if err <> nil then
        err.AddError('Ошибка формата потока. Не хватает закрывающих скобок } в конце текста разбора.', 'Путь', path);
      ret := False;
  end;

  reader.Free;
  Result := ret;
end;

{ tree }

function tree.add_child(_value: String; _type: node_type): tree;
begin
  Result := tree.Create(_value, _type, Self);
end;

function tree.add_child: tree;
begin
  Result := tree.Create('', nd_empty, Self);
end;

function tree.add_node: tree;
begin
  Result := tree.Create('', nd_empty, Self.parent);
end;

constructor tree.Create(_value: string; _type: node_type; _parent: tree);
begin
  value  := _value;
  atype  := _type;
  parent := _parent;

  num_subnode := 0;
  index := 0;

  if parent <> nil then
    begin
      Inc(parent.num_subnode);
      prev := parent.last;
      if prev <> nil then
      begin
        prev.next := Self;
        index := prev.index + 1;
      end
      else
      begin
        parent.first := Self;
      end;

      parent.last := Self;
    end
  else
    begin
      prev := nil;
    end;

  next  := nil;
  first := nil;
  last  := nil;

end;

destructor tree.Destroy;
begin
  while last <> nil do
    last := nil;

  if prev <> nil then
    prev.next := next;

  if next <> nil then
    next.prev := prev;

  if parent <> nil then
  begin
    if parent.first = Self then
      parent.first := next;
    if parent.last = Self then
      parent.last := prev;
    Dec(parent.num_subnode);
  end;
  inherited Destroy;
end;

function tree.get_first: tree;
begin
  Result := first;
end;

function tree.get_next: tree;
begin
  Result := next;
end;

function tree.get_num_subnode: Integer;
begin
  Result := num_subnode;
end;

function tree.get_parent: tree;
begin
  Result := parent;
end;

function tree.get_subnode(node_name: string): tree;
var
  t: tree;
begin
  t := first;
  while t <> nil do
  begin
    if (t.value = node_name) then
    begin
      Result := t;
      Exit;
    end;
    t := t.next;
  end;
  Result := nil;
end;

function tree.get_subnode(_index: Integer): tree;
var
  t : tree;
begin
  if _index >= num_subnode then
    Result := nil;
  t := first;
  while _index <> 0 do
  begin
    t := t.next;
    Dec(_index);
  end;
  Result := t;
end;

function tree.get_type: node_type;
begin
  Result := atype;
end;

function tree.get_value: string;
begin
  Result := value;
end;

procedure tree.outtext(var text: string);
var
  lt: node_type;
  _ReplaceAll: TReplaceFlags;
  t : tree;
begin
  lt := nd_empty;
  if num_subnode <> 0 then
    begin
      if text.Length <> 0 then
        text := text + #$0D#$0A;
      text := text + '{';
      t := first;
      while t <> nil do
      begin
        t.outtext(text);
        lt := t.atype;
        t := t.next;
        if t <> nil then
          text := text + ',';
      end;
      if lt = nd_list then
        text := text + #$0D#$0A;
      text := text + '}';
    end
  else
    begin
      case atype of
        nd_string:
          begin
            text := text + '"';
            _ReplaceAll := [rfReplaceAll];
            text := text + StringReplace(value, '"', '""', _ReplaceAll);
            text := text + '"';
          end;
        nd_number, nd_number_exp, nd_guid, nd_list, nd_binary, nd_binary2, nd_link, nd_binary_d:
          begin
            text := text + value;
          end;
      end;
    end;
end;

function tree.path: string;
var
  p : string;
  t : tree;
  I: Integer;
begin
  p := '';
  if Self = nil then
    Result := ':??';

  t := Self;
  while t.parent <> nil do
  begin
    p := ':' + IntToStr(t.index) + p;
    t := t.parent;
  end;
end;

procedure tree.set_value(v: string; t: node_type);
begin
  value := v;
  atype := t;
end;

end.
