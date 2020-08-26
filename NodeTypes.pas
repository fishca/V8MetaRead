unit NodeTypes;

interface

type
  node_type = (
    nd_empty      = 0, // пусто
    nd_string     = 1, // строка
    nd_number     = 2, // число
    nd_number_exp = 3, // число с показателем степени
    nd_guid       = 4, // уникальный идентификатор
    nd_list       = 5, // список
    nd_binary     = 6, // двоичные данные (с префиксом #base64:)
    nd_binary2    = 7, // двоичные данные формата 8.2 (без префикса)
    nd_link       = 8, // ссылка
    nd_binary_d   = 9, // двоичные данные (с префиксом #data:)
    nd_unknown         // неизвестный тип

  );


  function get_node_type_presentation( atype : node_type) : String;

implementation

function get_node_type_presentation( atype : node_type) : String;
begin
  case atype of
    nd_empty: Result := 'Пусто';
    nd_string: Result := 'Строка';
    nd_number: Result := 'Число';
    nd_number_exp: Result := 'Число с показателем степени';
    nd_guid: Result := 'Уникальный идентификатор';
    nd_list: Result := 'Список';
    nd_binary: Result := 'Двоичные данные';
    nd_binary2: Result := 'Двоичные данные 8.2';
    nd_link: Result := 'Ссылка';
    nd_binary_d: Result := 'Двоичные данные data';
    nd_unknown: Result := '<Неизвестный тип>';
  end;
end;









end.
