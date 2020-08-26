unit NodeTypes;

interface

type
  node_type = (
    nd_empty      = 0, // �����
    nd_string     = 1, // ������
    nd_number     = 2, // �����
    nd_number_exp = 3, // ����� � ����������� �������
    nd_guid       = 4, // ���������� �������������
    nd_list       = 5, // ������
    nd_binary     = 6, // �������� ������ (� ��������� #base64:)
    nd_binary2    = 7, // �������� ������ ������� 8.2 (��� ��������)
    nd_link       = 8, // ������
    nd_binary_d   = 9, // �������� ������ (� ��������� #data:)
    nd_unknown         // ����������� ���

  );


  function get_node_type_presentation( atype : node_type) : String;

implementation

function get_node_type_presentation( atype : node_type) : String;
begin
  case atype of
    nd_empty: Result := '�����';
    nd_string: Result := '������';
    nd_number: Result := '�����';
    nd_number_exp: Result := '����� � ����������� �������';
    nd_guid: Result := '���������� �������������';
    nd_list: Result := '������';
    nd_binary: Result := '�������� ������';
    nd_binary2: Result := '�������� ������ 8.2';
    nd_link: Result := '������';
    nd_binary_d: Result := '�������� ������ data';
    nd_unknown: Result := '<����������� ���>';
  end;
end;









end.
