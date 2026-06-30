#define SourcePath ".."

#ifndef DRIFTFIN_VERSION
  #define DRIFTFIN_VERSION "latest"
#endif

[Setup]
AppId={{D573EDD5-117A-47AD-88AC-62C8EBD11DC7}
AppName="Driftfin"
AppVersion={#DRIFTFIN_VERSION}
AppPublisher="Driftfin"
AppPublisherURL="https://github.com/HamadTheIronside/Driftfin"
AppSupportURL="https://github.com/HamadTheIronside/Driftfin"
AppUpdatesURL="https://github.com/HamadTheIronside/Driftfin"
DefaultDirName={localappdata}\Programs\Driftfin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
OutputBaseFilename=driftfin_setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern

SetupLogging=yes
UninstallLogging=yes
UninstallDisplayName="Driftfin"
UninstallDisplayIcon={app}\driftfin.exe
SetupIconFile="{#SourcePath}\icons\production\driftfin_icon.ico"
LicenseFile="{#SourcePath}\LICENSE"
WizardImageFile={#SourcePath}\assets\windows-installer\driftfin-installer-100.bmp,{#SourcePath}\assets\windows-installer\driftfin-installer-125.bmp,{#SourcePath}\assets\windows-installer\driftfin-installer-150.bmp

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#SourcePath}\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Driftfin"; Filename: "{app}\driftfin.exe"
Name: "{autodesktop}\Driftfin"; Filename: "{app}\driftfin.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\driftfin.exe"; Description: "{cm:LaunchProgram,Driftfin}"; Flags: nowait postinstall skipifsilent

[Code]
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  case CurUninstallStep of
    usUninstall:
      begin
        if MsgBox('Would you like to delete the application''s data? This action cannot be undone. Synced files will remain unaffected.', mbConfirmation, MB_YESNO) = IDYES then
        begin
            // path_provider derives the app support dir from the executable's
            // CompanyName version-info field (now "Driftfin"), so user data is
            // stored under {localappdata}\Driftfin.
            if DelTree(ExpandConstant('{localappdata}\Driftfin'), True, True, True) = False then
            begin
                Log(ExpandConstant('{localappdata}\Driftfin could not be deleted. Skipping...'));
            end;
        end;
      end;
  end;
end;
