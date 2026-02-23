param(
    [Parameter(Mandatory=$true)]
    [string]$PomPath,

    [Parameter(Mandatory=$true)]
    [string]$Recipe
)

if (!(Test-Path $PomPath)) {
    Write-Error "pom.xml not found at $PomPath"
    exit 1
}

# Load XML safely
[xml]$xml = Get-Content $PomPath

$project = $xml.project

if (-not $project) {
    Write-Error "Invalid pom.xml structure"
    exit 1
}

# Ensure <build> exists
if (-not $project.build) {
    $build = $xml.CreateElement("build")
    $project.AppendChild($build) | Out-Null
} else {
    $build = $project.build
}

# Ensure <plugins> exists
if (-not $build.plugins) {
    $plugins = $xml.CreateElement("plugins")
    $build.AppendChild($plugins) | Out-Null
} else {
    $plugins = $build.plugins
}

# Check if rewrite plugin already exists
$rewritePlugin = $null

foreach ($plugin in $plugins.plugin) {
    if ($plugin.groupId -eq "org.openrewrite.maven" -and
        $plugin.artifactId -eq "rewrite-maven-plugin") {
        $rewritePlugin = $plugin
        break
    }
}

if (-not $rewritePlugin) {
    Write-Host "Adding rewrite-maven-plugin..."

    $rewritePlugin = $xml.CreateElement("plugin")

    $groupId = $xml.CreateElement("groupId")
    $groupId.InnerText = "org.openrewrite.maven"

    $artifactId = $xml.CreateElement("artifactId")
    $artifactId.InnerText = "rewrite-maven-plugin"

    $version = $xml.CreateElement("version")
    $version.InnerText = "5.38.0"

    $rewritePlugin.AppendChild($groupId) | Out-Null
    $rewritePlugin.AppendChild($artifactId) | Out-Null
    $rewritePlugin.AppendChild($version) | Out-Null

    $plugins.AppendChild($rewritePlugin) | Out-Null
}

# Ensure <configuration> exists
if (-not $rewritePlugin.configuration) {
    $configuration = $xml.CreateElement("configuration")
    $rewritePlugin.AppendChild($configuration) | Out-Null
} else {
    $configuration = $rewritePlugin.configuration
}

# Ensure <activeRecipes> exists
if (-not $configuration.activeRecipes) {
    $activeRecipes = $xml.CreateElement("activeRecipes")
    $configuration.AppendChild($activeRecipes) | Out-Null
} else {
    $activeRecipes = $configuration.activeRecipes
}

# Check if recipe already exists
$exists = $false
foreach ($recipeNode in $activeRecipes.recipe) {
    if ($recipeNode.InnerText -eq $Recipe) {
        $exists = $true
        break
    }
}

if (-not $exists) {
    Write-Host "Injecting recipe: $Recipe"

    $recipeElement = $xml.CreateElement("recipe")
    $recipeElement.InnerText = $Recipe
    $activeRecipes.AppendChild($recipeElement) | Out-Null
} else {
    Write-Host "Recipe already exists."
}

# Save with indentation
$settings = New-Object System.Xml.XmlWriterSettings
$settings.Indent = $true
$settings.OmitXmlDeclaration = $false

$writer = [System.Xml.XmlWriter]::Create($PomPath, $settings)
$xml.Save($writer)
$writer.Close()

Write-Host "pom.xml updated successfully."
