# Using the analyzers during command line builds

The following notes are useful if you're building not from within and IDE but from the command line, like in a CI environment. For CI builds we recommend using [Lombiq GitHub Actions](https://github.com/Lombiq/GitHub-Actions).

**Note** the instructions for non-SDK-style .NET Framework projects at the bottom; those projects can't use `dotnet build`!

## Showing analyzer warnings during `dotnet build`

Analyzer warnings will show up in the build output of `dotnet build` regardless of the `RunAnalyzersDuringBuild` config in _Build.props_. Note though, that this will only happen if it's a fresh, clean build; otherwise if you're building an already built solution use the `--no-incremental` switch to make analyzer warnings appear:

```ps
dotnet build MySolution.sln --no-incremental
```

If you want analyzer violations to fail the build (recommended) then also use `TreatWarningsAsErrors`:

```ps
dotnet build MySolution.sln --no-incremental /p:TreatWarningsAsErrors=true
```

## .NET code style analysis

If you want code style analysis configured in _.globalconfig_ (i.e. IDE\* rules, this is not applicable to the others) to be checked during build too (it's already checked during editing) then you'll need to run the build with `RunAnalyzersDuringBuild=true`. **Don't** enable `EnforceCodeStyleInBuild` as explained in [the docs](https://docs.microsoft.com/en-us/dotnet/fundamentals/code-analysis/overview#code-style-analysis) because that always uses the analyzers from the .NET SDK, not the explicitly referenced packages, and violations won't show up (see [this comment](https://github.com/dotnet/roslyn/issues/50785#issuecomment-768606882)).

```ps
dotnet build MySolution.sln --no-incremental /p:RunAnalyzersDuringBuild=true
```

Our recommendation is to use it together with `TreatWarningsAsErrors` but do note that for code style analysis warnings you also have to specify `-warnaserror` (this is not needed for the other analyzers):

```ps
dotnet build MySolution.sln --no-incremental -warnaserror /p:TreatWarningsAsErrors=true /p:RunAnalyzersDuringBuild=true
```

Or if you only want to see the errors and not the full build output (including e.g. NuGet restores, build messages):

```ps
dotnet build MySolution.sln --no-incremental -warnaserror /p:TreatWarningsAsErrors=true /p:RunAnalyzersDuringBuild=true -nologo -consoleLoggerParameters:NoSummary -verbosity:quiet
```

> ⚠ If you are using the NuGet package, run `dotnet msbuild "-t:Restore;LombiqNetAnalyzers" MySolution.sln` first to ensure the _.editorconfig_ file is deployed. This is especially important for CI usage. For local development, you can simply rebuild the solution.

## Non-SDK-style .NET Framework projects

Non-SDK-style .NET Framework projects can't use `dotnet build` for analyzer warnings to show during build, not just in Visual Studio, because it won't resolve `<PackageReference>` elements (see [this issue](https://github.com/dotnet/msbuild/issues/5250)). You'll need to use the following command to achieve what's elaborated above for `dotnet build` (change the MSBuild path to a suitable one):

```ps
& "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\MSBuild.exe" MySolution.sln /p:TreatWarningsAsErrors=true /p:RunAnalyzersDuringBuild=true /t:Rebuild /restore
```
