# Only adds displayMimic on the host dump if missing. Do not rewrite LilithCustoms or AvatarMenuView.
$ErrorActionPreference = "Continue"
. "$PSScriptRoot\config.ps1"

$hwm = Join-Path $SrcScripts "com\sulake\habbo\window\HabboWindowManagerComponent.as"
if (Test-Path $hwm) {
    $raw = Get-Content -Path $hwm -Raw -Encoding UTF8
    if ($raw -notmatch "function displayMimic") {
        $method = @"
      public function displayMimic(userName:String = "") : void
      {
         var mimic:BobbaMimicController = BobbaMimicController.install(this);
         var name:String = userName;
         if((name == null || name.length == 0) && mimic != null)
         {
            name = mimic.targetName;
         }
         if(mimic != null)
         {
            mimic.openForName(name);
         }
      }

"@
        $anchor = $null
        foreach ($fn in @("public function displayBobbaHelper", "public function displayPresets", "public function displayTraxMachine")) {
            if ($raw.Contains($fn)) { $anchor = $fn; break }
        }
        if ($anchor) {
            $raw = $raw.Replace($anchor, $method + "      " + $anchor.TrimStart())
            Set-Content -Path $hwm -Value $raw -Encoding UTF8
            Write-Host "Patched displayMimic into HabboWindowManagerComponent.as"
        }
        else {
            Write-Warning "No display* insertion point in HabboWindowManagerComponent.as"
        }
    }
    else {
        Write-Host "displayMimic already present"
    }
}
else {
    Write-Warning "HabboWindowManagerComponent.as missing"
}

exit 0
