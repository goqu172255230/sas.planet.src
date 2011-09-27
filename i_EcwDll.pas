{******************************************************************************}
{* SAS.������� (SAS.Planet)                                                   *}
{* Copyright (C) 2007-2011, ������ ��������� SAS.������� (SAS.Planet).        *}
{* ��� ��������� �������� ��������� ����������� ������������. �� ������       *}
{* �������������� �/��� �������������� � �������� �������� �����������       *}
{* ������������ �������� GNU, �������������� ������ ���������� ������������   *}
{* �����������, ������ 3. ��� ��������� ���������������� � �������, ��� ���   *}
{* ����� ��������, �� ��� ������ ��������, � ��� ����� ���������������        *}
{* �������� ��������� ��������� ��� ������� � �������� ��� ������˨�����      *}
{* ����������. �������� ����������� ������������ �������� GNU ������ 3, ���   *}
{* ��������� �������������� ����������. �� ������ ���� �������� �����         *}
{* ����������� ������������ �������� GNU ������ � ����������. � ������ �     *}
{* ����������, ���������� http://www.gnu.org/licenses/.                       *}
{*                                                                            *}
{* http://sasgis.ru/sasplanet                                                 *}
{* az@sasgis.ru                                                               *}
{******************************************************************************}

unit i_EcwDll;

interface

uses
  ECWWriter;

type
  IEcwDll = interface
  ['{B5E36492-CA31-4114-A65F-4EC6E0B76DCC}']
    function GetCompressAllocClient: NCSEcwCompressAllocClient;
    property CompressAllocClient: NCSEcwCompressAllocClient read GetCompressAllocClient;

    function GetCompressOpen: NCSEcwCompressOpen;
    property CompressOpen: NCSEcwCompressOpen read GetCompressOpen;

    function GetCompress: NCSEcwCompress;
    property Compress: NCSEcwCompress read GetCompress;

    function GetCompressClose: NCSEcwCompressClose;
    property CompressClose: NCSEcwCompressClose read GetCompressClose;

    function GetCompressFreeClient: NCSEcwCompressFreeClient;
    property CompressFreeClient: NCSEcwCompressFreeClient read GetCompressFreeClient;
  end;

implementation

end.
