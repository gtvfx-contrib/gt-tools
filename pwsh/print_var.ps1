param(
	[Parameter(Mandatory = $true)]
	[string]$Value
)

$Value -split [IO.Path]::PathSeparator