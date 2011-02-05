{******************************************************************************}
{                                                                              }
{ RAD Studio Version Insight                                                   }
{                                                                              }
{ The contents of this file are subject to the Mozilla Public License          }
{ Version 1.1 (the "License"); you may not use this file except in compliance  }
{ with the License. You may obtain a copy of the License at                    }
{ http://www.mozilla.org/MPL/                                                  }
{                                                                              }
{ Software distributed under the License is distributed on an "AS IS" basis,   }
{ WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for }
{ the specific language governing rights and limitations under the License.    }
{                                                                              }
{ The Original Code is GitIDEHistory.pas.                                      }
{                                                                              }
{ The Initial Developer of the Original Code is Uwe Schuster.                  }
{ Portions created by Uwe Schuster are Copyright � 2010 Uwe Schuster. All      }
{ Rights Reserved.                                                             }
{                                                                              }
{ Contributors:                                                                }
{ Uwe Schuster (uschuster)                                                     }
{                                                                              }
{******************************************************************************}

unit GitIDEHistory;

interface

uses
  Classes, FileHistoryAPI, GitClient, GitIDEClient;

type
  TDispInterfacedObject = class(TInterfacedObject, IDispatch)
  protected
    { IDispatch }
    function GetTypeInfoCount(out Count: Integer): HResult; stdcall;
    function GetTypeInfo(Index, LocaleID: Integer; out TypeInfo): HResult; stdcall;
    function GetIDsOfNames(const IID: TGUID; Names: Pointer;
      NameCount, LocaleID: Integer; DispIDs: Pointer): HResult; stdcall;
    function Invoke(DispID: Integer; const IID: TGUID; LocaleID: Integer;
      Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult; stdcall;
  end;

  TGitFileHistoryProvider = class(TDispInterfacedObject, IOTAFileHistoryProvider,
    IOTAAsynchronousHistoryProvider)
  private
    FClient: TGitClient;
    FItems: TStringList;
    FGitIDEClient: TGitIDEClient;

    procedure ClearItems;
    function CheckGitInitalize: Boolean;

    { IOTAFileHistoryProvider }
    function Get_Ident: WideString; safecall;
    function Get_Name: WideString; safecall;
    function GetFileHistory(const AFileName: WideString): IOTAFileHistory; safecall;

    { IOTAAsynchronousHistoryProvider }
    procedure StartAsynchronousUpdate(const AFileName: WideString;
      const AsynchronousHistoryUpdater: IOTAAsynchronousHistoryUpdater);
  public
    constructor Create(GitIDEClient: TGitIDEClient);
    destructor Destroy; override;

    function SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HResult; override;
  end;

  IGitFileHistory = interface(IOTAFileHistory)
    ['{A29A1732-DA67-4B36-BF86-41978F8967D3}']
    function GetItem: TGitItem; safecall;
    property Item: TGitItem read GetItem;
  end;

implementation

uses
  ComObj, ActiveX, SysUtils, Forms, Windows, ExtCtrls;

const
  GitFileHistoryProvider = 'VersionInsight.GitFileHistoryProvider';  //Do not internationalize

type
  TGitFileHistory = class(TDispInterfacedObject, IOTAFileHistory, IGitFileHistory,
    IOTAFileHistoryHint)
  private
    FItem: TGitItem;

    { IOTAFileHistory }
    function Get_Count: Integer; safecall;
    function GetAuthor(Index: Integer): WideString; safecall;
    function GetComment(Index: Integer): WideString; safecall;
    function GetContent(Index: Integer): IStream; safecall;
    function GetDate(Index: Integer): TDateTime; safecall;
    function GetIdent(Index: Integer): WideString; safecall;
    function GetHistoryStyle(Index: Integer): TOTAHistoryStyle; safecall;
    function GetLabelCount(Index: Integer): Integer; safecall;
    function GetLabels(Index, LabelIndex: Integer): WideString; safecall;

    { IGitFileHistory }
    function GetItem: TGitItem; safecall;

    { IOTAFileHistoryHint }
    function GetHintStr(Index: Integer): string;
  public
    constructor Create(AItem: TGitItem);
    destructor Destroy; override;

    function SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HResult; override;
  end;

{ TDispInterfacedObject }

function TDispInterfacedObject.GetIDsOfNames(const IID: TGUID; Names: Pointer;
  NameCount, LocaleID: Integer; DispIDs: Pointer): HResult;
begin
  Result := E_NOTIMPL;
end;

function TDispInterfacedObject.GetTypeInfo(Index, LocaleID: Integer;
  out TypeInfo): HResult;
begin
  Result := E_NOTIMPL;
end;

function TDispInterfacedObject.GetTypeInfoCount(out Count: Integer): HResult;
begin
  Result := S_OK;
  Count := 0;
end;

function TDispInterfacedObject.Invoke(DispID: Integer; const IID: TGUID;
  LocaleID: Integer; Flags: Word; var Params; VarResult, ExcepInfo,
  ArgErr: Pointer): HResult;
begin
  Result := E_NOTIMPL;
end;

{ TGitFileHistoryProvider }

function TGitFileHistoryProvider.CheckGitInitalize: Boolean;
begin
  try
    Result := FGitIDEClient.GitInitialize;
    if Result then
      FClient := FGitIDEClient.GitClient;
  except
    Result := False;
  end;
end;

procedure TGitFileHistoryProvider.ClearItems;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    FItems.Objects[I].Free;
  FItems.Clear;
end;

constructor TGitFileHistoryProvider.Create(GitIDEClient: TGitIDEClient);
begin
  inherited Create;
  FClient := nil;
  FGitIDEClient := GitIDEClient;
  FItems := TStringList.Create;
  FItems.CaseSensitive := False;
  FItems.Duplicates := dupError;
  FItems.Sorted := True;
end;

destructor TGitFileHistoryProvider.Destroy;
begin
  ClearItems;
  FItems.Free;
  FClient := nil;
  inherited;
end;

function TGitFileHistoryProvider.GetFileHistory(
  const AFileName: WideString): IOTAFileHistory;
var
  Index: Integer;
  Item: TGitItem;
begin
  Result := nil;
  if not CheckGitInitalize then
    Exit;

  if not FClient.IsVersioned(AFileName) then
    Exit;

  if FItems.Find(AFileName, Index) then
  begin
    Item := TGitItem(FItems.Objects[Index]);
  end
  else
  begin
    Item := TGitItem.Create(FClient, AFileName);
    try
      Item.LoadHistory;
      FItems.AddObject({Item.PathName}AFileName, Item);
    except
      Item.Free;
      raise;
    end;
  end;
  Result := TGitFileHistory.Create(Item);
end;

function TGitFileHistoryProvider.Get_Ident: WideString;
begin
  Result := GitFileHistoryProvider;
end;

function TGitFileHistoryProvider.Get_Name: WideString;
begin
  Result := 'Git history provider'; // Do not internationalize
end;

function TGitFileHistoryProvider.SafeCallException(ExceptObject: TObject;
  ExceptAddr: Pointer): HResult;
begin
  Result := HandleSafeCallException(ExceptObject, ExceptAddr, IOTAFileHistoryProvider, '', '');
end;

type
  TGitHistoryThread = class(TThread)
  private
    FAsynchronousHistoryUpdater: IOTAAsynchronousHistoryUpdater;
    FGitItem: TGitItem;
    FFileHistory: IOTAFileHistory;
    procedure Completed(Sender: TObject);
  protected
    procedure Execute; override;
  public
    constructor Create(AGitItem: TGitItem; AFileHistory: IOTAFileHistory; AsynchronousHistoryUpdater: IOTAAsynchronousHistoryUpdater);
  end;

{ TGitHistoryThread }

procedure TGitHistoryThread.Completed(Sender: TObject);
begin
  FAsynchronousHistoryUpdater.UpdateHistoryItems(FFileHistory, 0, FGitItem.HistoryCount - 1);
  FAsynchronousHistoryUpdater.Completed;
end;

constructor TGitHistoryThread.Create(AGitItem: TGitItem; AFileHistory: IOTAFileHistory; AsynchronousHistoryUpdater: IOTAAsynchronousHistoryUpdater);
begin
  FGitItem := AGitItem;
  FFileHistory := AFileHistory;
  FAsynchronousHistoryUpdater := AsynchronousHistoryUpdater;
  FreeOnTerminate := True;
  inherited Create;
  OnTerminate := Completed;
end;

procedure TGitHistoryThread.Execute;
begin
  NameThreadForDebugging('VerIns Git History Updater');
  FGitItem.LoadHistory;
end;

procedure TGitFileHistoryProvider.StartAsynchronousUpdate(
  const AFileName: WideString;
  const AsynchronousHistoryUpdater: IOTAAsynchronousHistoryUpdater);
var
  Index: Integer;
  Item: TGitItem;
begin
  if (not CheckGitInitalize) or (not FClient.IsVersioned(AFileName)) then
  begin
    AsynchronousHistoryUpdater.Completed;
    Exit;
  end;

  if FItems.Find(AFileName, Index) then
  begin
    Item := TGitItem(FItems.Objects[Index]);
    TGitHistoryThread.Create(Item, TGitFileHistory.Create(Item), AsynchronousHistoryUpdater);
  end
  else
  begin
    Item := TGitItem.Create(FClient, AFileName);
    try
      FItems.AddObject({Item.PathName}AFileName, Item);
      TGitHistoryThread.Create(Item, TGitFileHistory.Create(Item), AsynchronousHistoryUpdater);
    except
      Item.Free;
      raise;
    end;
  end;
end;

{ TGitFileHistory }

constructor TGitFileHistory.Create(AItem: TGitItem);
begin
  inherited Create;
  FItem := AItem;
end;

destructor TGitFileHistory.Destroy;
begin
//  FItem.Tag := 1;
  inherited;
end;

function TGitFileHistory.GetAuthor(Index: Integer): WideString;
begin
  Result := TGitHistoryItem(FItem.HistoryItems[Index]).Author;
end;

function TGitFileHistory.GetComment(Index: Integer): WideString;
begin
  Result := TGitHistoryItem(FItem.HistoryItems[Index]).Subject + #13#10 +
    TGitHistoryItem(FItem.HistoryItems[Index]).Body;
end;

function TGitFileHistory.GetContent(Index: Integer): IStream;
var
  Item: TGitHistoryItem;
begin
  Item := FItem.HistoryItems[Index];
  Result := TStreamAdapter.Create(TStringStream.Create(Item.GetFile), soOwned);
end;

function TGitFileHistory.GetDate(Index: Integer): TDateTime;
begin
  Result := TGitHistoryItem(FItem.HistoryItems[Index]).Date;
end;

function TGitFileHistory.GetHintStr(Index: Integer): string;
begin
  Result := '';//FItem.HintStrings[Index];
end;

function TGitFileHistory.GetHistoryStyle(Index: Integer): TOTAHistoryStyle;
{
var
  Item: TGitHistoryItem;
}
begin
  {
  Item := FItem.HistoryItems[Index];

  if Item.Revision = Item.Owner.CommittedRevision then
    Result := hsActiveRevision
  else
  }
    Result := hsRemoteRevision;
end;

function TGitFileHistory.GetIdent(Index: Integer): WideString;
begin
  Result := Copy(FItem.HistoryItems[Index].Hash, 1, 7);
end;

function TGitFileHistory.GetItem: TGitItem;
begin
  Result := FItem;
end;

function TGitFileHistory.GetLabelCount(Index: Integer): Integer;
begin
  Result := 1;
end;

function TGitFileHistory.GetLabels(Index, LabelIndex: Integer): WideString;
begin
  case LabelIndex of
    0: Result := FItem.HistoryItems[Index].Hash;
  else
    Result := '';
  end;
end;

function TGitFileHistory.Get_Count: Integer;
begin
  Result := FItem.HistoryCount;
end;

function TGitFileHistory.SafeCallException(ExceptObject: TObject;
  ExceptAddr: Pointer): HResult;
begin
  Result := HandleSafeCallException(ExceptObject, ExceptAddr, IOTAFileHistory, '', '');
end;

initialization

end.
