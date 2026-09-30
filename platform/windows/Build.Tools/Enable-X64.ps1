param()

$ErrorActionPreference = 'Stop'
$windowsDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$solutionPath = Join-Path $windowsDir 'Corona.Simulator.sln'
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Convert-ConfigurationNode {
    param([System.Xml.XmlNode]$Node)

    if ($Node.NodeType -ne [System.Xml.XmlNodeType]::Element) {
        return
    }

    foreach ($attribute in $Node.Attributes) {
        $attribute.Value = $attribute.Value.Replace('|Win32', '|x64')
    }
    if ($Node.LocalName -eq 'Platform' -and $Node.InnerText -eq 'Win32') {
        $Node.InnerText = 'x64'
    }
    foreach ($child in $Node.ChildNodes) {
        Convert-ConfigurationNode $child
    }
}

function Add-ConfigurationNodes {
    param(
        [System.Xml.XmlNode]$Parent,
        [string]$Configuration
    )

    foreach ($child in @($Parent.ChildNodes)) {
        if ($child.NodeType -ne [System.Xml.XmlNodeType]::Element) {
            continue
        }

        $condition = $child.Attributes['Condition']
        $include = $child.Attributes['Include']
        $isConfiguration = $child.LocalName -eq 'ProjectConfiguration' -and
            $null -ne $include -and $include.Value -eq "$Configuration|Win32"
        $isConditional = $null -ne $condition -and
            $condition.Value.Contains("'$Configuration|Win32'")

        if ($isConfiguration -or $isConditional) {
            $clone = $child.CloneNode($true)
            Convert-ConfigurationNode $clone
            $separator = $child.PreviousSibling
            if ($null -ne $separator -and
                $separator.NodeType -eq [System.Xml.XmlNodeType]::Whitespace) {
                $space = $Parent.OwnerDocument.CreateWhitespace($separator.Value)
                [void]$Parent.InsertAfter($space, $child)
                [void]$Parent.InsertAfter($clone, $space)
            } else {
                [void]$Parent.InsertAfter($clone, $child)
            }
        } else {
            Add-ConfigurationNodes $child $Configuration
        }
    }
}

$solution = [System.IO.File]::ReadAllText($solutionPath)
if ($solution.Contains('Release|x64')) {
    throw 'Release|x64 already exists in the solution.'
}

$projectPaths = [regex]::Matches($solution, '(?m)^Project\([^\r\n]+"([^"]+\.vcxproj)"') |
    ForEach-Object { $_.Groups[1].Value }

foreach ($relativePath in $projectPaths) {
    $projectPath = Join-Path $windowsDir $relativePath
    $document = New-Object System.Xml.XmlDocument
    $document.PreserveWhitespace = $true
    $document.Load($projectPath)

    $configuration = if ($relativePath -like 'Corona.Rtt.Library\*' -or
        $relativePath -like 'Corona.Native.Library.Win32\*') {
        'Release.Simulator'
    } else {
        'Release'
    }

    if ($document.OuterXml.Contains("$configuration|x64")) {
        throw "x64 configuration already exists in $relativePath"
    }
    Add-ConfigurationNodes $document $configuration
    $document.Save($projectPath)
    Write-Output "Added $configuration|x64 to $relativePath"
}

$lineEnding = if ($solution.Contains("`r`n")) { "`r`n" } else { "`n" }
$updatedSolution = [regex]::Replace(
    $solution,
    '(?m)^([^\r\n]*Release\|Win32[^\r\n]*)(\r?\n)',
    { param($match)
        $match.Groups[1].Value + $lineEnding +
            $match.Groups[1].Value.Replace('|Win32', '|x64') + $match.Groups[2].Value
    }
)
[System.IO.File]::WriteAllText($solutionPath, $updatedSolution, $utf8)
Write-Output 'Added Release|x64 to Corona.Simulator.sln'
