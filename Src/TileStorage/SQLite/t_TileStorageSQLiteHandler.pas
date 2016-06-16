unit t_TileStorageSQLiteHandler;

interface

uses
  t_TileStorageSQLite,
  t_NotifierOperationRec,
  i_MapVersionInfo,
  i_InterfaceListSimple;

type
  TVersionColMode = (
    vcm_None = 0,
    vcm_Int,
    vcm_Text
  );

  TTBColInfo = record
    // 5..7: x, y, [v], [c], s, d, b
    ColCount: Integer;

    // 0 - no field 'v' for Version
    // 1 - has field 'v' of type INT (actually Int64)
    // 2 - has field 'v' of type TEXT
    ModeV: TVersionColMode;

    // if true - has field 'c' for contenttype as TEXT
    HasC: Boolean;
  end;
  PTBColInfo = ^TTBColInfo;

  TSelectTileInfoComplex = record
    TileResult: PGetTileResult;
    RequestedVersionInfo: IMapVersionInfo; // ����������� ������ (��� ��������� ��� ��������� �����)
    RequestedVersionAsInt: Int64;          // ��������� �����������  ��������� ������ � Int64
    RequestedVersionIsInt: Boolean;        // �������, ��� ��������� ������ �������������
    RequestedVersionIsSet: Boolean;        // �������, ��� ��������� ������ ����������� (�� ������)
    RequestedVersionToDB: AnsiString;      // ������ ��� ������� � ��
    SelectMode: TGetTileInfoModeSQLite;
  end;
  PSelectTileInfoComplex = ^TSelectTileInfoComplex;

implementation


end.
