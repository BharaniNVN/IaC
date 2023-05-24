# Download and install latest lts Node.js binary
$NodejsVersionsJson = "https://nodejs.org/dist/index.json"
$PrefixPath = 'C:\npm\prefix'
$CachePath = 'C:\npm\cache'

New-Item -Path $PrefixPath -Force -ItemType Directory
New-Item -Path $CachePath -Force -ItemType Directory

$NodejsLatestLtsVersion = (Invoke-RestMethod -Uri $NodejsVersionsJson -TimeoutSec 15).Where({$_.lts})[0].version
$NodejsInstallerFile = "node-${NodejsLatestLtsVersion}-x64.msi"
$NodejsInstallerUrl = "https://nodejs.org/dist/${NodejsLatestLtsVersion}/${NodejsInstallerFile}"
Install-Binary -Url $NodejsInstallerUrl -Name $NodejsInstallerFile

Add-MachinePathItem $PrefixPath
$env:Path = Get-MachinePath

setx npm_config_prefix $PrefixPath /M
$env:npm_config_prefix = $PrefixPath

npm config set cache $CachePath --global
npm config set registry https://registry.npmjs.org/

npm install -g cordova
npm install -g grunt-cli
npm install -g gulp-cli
npm install -g parcel-bundler
npm install -g --save-dev webpack webpack-cli
npm install -g yarn
npm install -g lerna
npm install -g node-sass
npm install -g newman
