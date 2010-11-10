unit u_ContentConverterKml2Kmz;

interface

uses
  Classes,
  i_ContentTypeInfo,
  u_ContentConverterBase;

type
  TContentConverterKml2Kmz = class(TContentConverterBase)
  protected
    procedure ConvertStream(ASource, ATarget: TStream); override;
  end;

implementation

uses
  KAZip;

{ TContentConverterKmz2Kml }

procedure TContentConverterKml2Kmz.ConvertStream(ASource, ATarget: TStream);
var
  VZip:TKAZip;
begin
  inherited;
  VZip:=TKAZip.Create(nil);
  try
    VZip.CreateZip(ATarget);
    VZip.CompressionType := ctNormal;
    VZip.Active := true;
    VZip.AddStream('doc.kml', ASource);
  finally
    VZip.Free;
  end;
end;

end.
