$port = 8080
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
try {
    $listener.Start()
} catch {
    $port = 8081
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:$port/")
    $listener.Start()
}

Write-Output "HTTP Server started at http://localhost:$port/"

$mime = @{
    '.html' = 'text/html; charset=utf-8'
    '.js'   = 'application/javascript; charset=utf-8'
    '.glb'  = 'model/gltf-binary'
    '.gltf' = 'model/gltf+json'
    '.css'  = 'text/css; charset=utf-8'
    '.png'  = 'image/png'
    '.jpg'  = 'image/jpeg'
}

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $req = $context.Request
    $res = $context.Response
    
    $res.Headers.Add("Access-Control-Allow-Origin", "*")
    $res.Headers.Add("Access-Control-Allow-Methods", "GET, OPTIONS")
    
    if ($req.HttpMethod -eq 'OPTIONS') {
        $res.StatusCode = 200
        $res.Close()
        continue
    }

    $localPath = $req.Url.LocalPath.TrimStart('/')
    if ([string]::IsNullOrEmpty($localPath)) { $localPath = 'index.html' }
    $localPath = [System.Uri]::UnescapeDataString($localPath)
    
    if (Test-Path $localPath) {
        $ext = [System.IO.Path]::GetExtension($localPath).ToLower()
        if ($mime.ContainsKey($ext)) {
            $res.ContentType = $mime[$ext]
        } else {
            $res.ContentType = 'application/octet-stream'
        }
        try {
            $fileStream = [System.IO.File]::OpenRead($localPath)
            $res.ContentLength64 = $fileStream.Length
            $fileStream.CopyTo($res.OutputStream)
            $fileStream.Close()
        } catch {
            $res.StatusCode = 500
        }
    } else {
        $res.StatusCode = 404
    }
    try {
        $res.OutputStream.Close()
    } catch {}
}
