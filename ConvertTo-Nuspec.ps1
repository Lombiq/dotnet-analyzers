﻿param($Version)

$packages = @(
    "Lombiq.Analyzers",
    "Lombiq.Analyzers.OrchardCore",
    "Lombiq.Analyzers.Orchard1",
    "Lombiq.Analyzers.VisualStudioExtension"
)

# Iterate through the packages to replace
foreach ($package in $packages)
{
    $projectPath = Join-Path $PWD $package
    function Read-Xml([string]$File) { [xml](Get-Content (Join-Path $projectPath $File)) }
    
    $nuspec = Read-Xml "$package.nuspec.template"
    $dependencies = $nuspec.package.metadata.dependencies
    
    $nuspec.package.metadata.GetElementsByTagName('version')[0].InnerXml = $Version
    
    # AnalyzerPackages.props is optional.
    $analyzerPackagesPropsFile = Join-Path $projectPath "AnalyzerPackages.props"
    if (Test-Path $analyzerPackagesPropsFile)
    {
        foreach ($dependency in (Read-Xml $analyzerPackagesPropsFile).Project.ItemGroup.AnalyzerPackage)
        {
            $id = $dependency.Include
            if (-not $id) { continue }
        
            $node = $nuspec.CreateElement('dependency')
            $node.SetAttribute('id', $id)
            $node.SetAttribute('version', $dependency.Version)
        
            $dependencies.AppendChild($node)
        }
    }
    
    $outputPath = Join-Path $projectPath "$package.nuspec"
    $nuspec.Save($outputPath)
}
