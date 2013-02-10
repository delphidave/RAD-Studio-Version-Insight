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
{ The Original Code is delphisvn: Subversion plugin for CodeGear Delphi.       }
{                                                                              }
{ The Initial Developer of the Original Code is Embarcadero Technologies.      }
{ Portions created by Ondrej Kelle are Copyright Ondrej Kelle. All rights      }
{ reserved.                                                                    }
{                                                                              }
{ Portions created or modified by Embarcadero Technologies are                 }
{ Copyright � 2010 Embarcadero Technologies, Inc. All Rights Reserved          }
{ Modifications include a major re-write of delphisvn. New functionality for   }
{ diffing, international character support, asynchronous gathering of data,    }
{ check-out and import, usability, tighter integration into RAD Studio, and    }
{ other new features.  Most original source files not used or re-written.      }
{                                                                              }
{ Contributors:                                                                }
{ Ondrej Kelle (tondrej)                                                       }
{ Uwe Schuster (uschuster)                                                     }
{ Embarcadero Technologies                                                     }
{                                                                              }
{******************************************************************************}
unit HgClientCheckout;

{$WARN UNIT_PLATFORM OFF}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TCheckoutDialog = class(TForm)
    GroupBox1: TGroupBox;
    Label1: TLabel;
    URL: TComboBox;
    Label2: TLabel;
    Destination: TEdit;
    BrowseDestination: TButton;
    Options: TGroupBox;
    Uncompressed: TCheckBox;
    Pull: TCheckBox;
    GroupBox2: TGroupBox;
    CurrentRevision: TCheckBox;
    RevisionLabel: TLabel;
    SelectRevision: TEdit;
    Ok: TButton;
    Cancel: TButton;
    Help: TButton;
    BrowseURL: TButton;
    procedure URLKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure DestinationKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure CurrentRevisionClick(Sender: TObject);
    procedure BrowseDestinationClick(Sender: TObject);
    procedure HelpClick(Sender: TObject);
    procedure BrowseURLClick(Sender: TObject);
  protected
    FInitalDirectory: string;
    procedure EnableOk;
  end;

function GetCheckoutInformation(const URLHistory: TStringList;
  const InitalDirectory: string; var PathName, TargetDir: string;
  var Uncompressed, IgnoreExternals: Boolean; var Revision: string): Boolean;

implementation

uses
  FileCtrl, HgUIConst;

{$R *.dfm}

function GetCheckoutInformation(const URLHistory: TStringList;
  const InitalDirectory: string; var PathName, TargetDir: string;
  var Uncompressed, IgnoreExternals: Boolean; var Revision: string): Boolean;
var
  CheckoutDialog: TCheckoutDialog;
begin
  CheckoutDialog := TCheckoutDialog.Create(Application);
  CheckoutDialog.FInitalDirectory := InitalDirectory;
  CheckoutDialog.URL.Items.Assign(URLHistory);
  CheckoutDialog.URL.Text := PathName;
  if CheckoutDialog.ShowModal = mrOk then
  begin
    Result := True;
    PathName := CheckoutDialog.URL.Text;
    TargetDir := CheckoutDialog.Destination.Text;
    Uncompressed := CheckoutDialog.Uncompressed.Checked;
    //IgnoreExternals := not CheckoutDialog.IncludeExternals.Checked;
    if CheckoutDialog.CurrentRevision.Checked then
      Revision := ''
    else
      Revision := CheckoutDialog.SelectRevision.Text;
    if URLHistory.IndexOf(PathName) = -1 then
      URLHistory.Insert(0, PathName);
  end
  else
    Result := False;
end;

procedure TCheckoutDialog.BrowseDestinationClick(Sender: TObject);
var
  Path: string;
begin
  if Destination.Text <> '' then
    Path := Destination.Text
  else
    Path := FInitalDirectory;
  if SelectDirectory(sDestination, '', Path, [sdNewFolder, sdNewUI, sdValidateDir], Self) then
  begin
    Destination.Text := Path;
    EnableOk;
  end;
end;

procedure TCheckoutDialog.BrowseURLClick(Sender: TObject);
var
  Path: string;
begin
  Path := URL.Text;
  if SelectDirectory(sDestination, '', Path, [sdNewFolder, sdNewUI, sdValidateDir], Self) then
  begin
    URL.Text := Path;
    EnableOk;
  end;
end;

procedure TCheckoutDialog.CurrentRevisionClick(Sender: TObject);
begin
  RevisionLabel.Enabled := not CurrentRevision.Checked;
  SelectRevision.Enabled := not CurrentRevision.Checked;
end;

procedure TCheckoutDialog.DestinationKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  EnableOk;
end;

procedure TCheckoutDialog.EnableOk;
begin
  Ok.Enabled := (URL.Text <> '') and (Destination.Text <> '');
end;

procedure TCheckoutDialog.HelpClick(Sender: TObject);
begin
  Application.HelpContext(HelpContext);
end;

procedure TCheckoutDialog.URLKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  EnableOk;
end;

end.
