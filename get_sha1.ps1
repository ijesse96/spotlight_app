# PowerShell script to get SHA-1 fingerprint for Firebase
# Run this script from the android directory

Write-Host "🔍 Getting SHA-1 fingerprint for Firebase..." -ForegroundColor Green

# Set Java environment
$env:JAVA_HOME = "C:\Program Files\Java\jdk-17.0.12"
$env:PATH += ";C:\Program Files\Java\jdk-17.0.12\bin"

# Check if Java is available
try {
    $javaVersion = java -version 2>&1
    Write-Host "✅ Java found: $javaVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Java not found. Please install Java JDK 17 or later." -ForegroundColor Red
    Write-Host "Download from: https://www.oracle.com/java/technologies/downloads/" -ForegroundColor Yellow
    exit 1
}

# Check if we're in the android directory
if (-not (Test-Path "build.gradle.kts")) {
    Write-Host "❌ Please run this script from the android directory" -ForegroundColor Red
    Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow
    exit 1
}

# Run gradlew signingReport
Write-Host "🔍 Running gradlew signingReport..." -ForegroundColor Yellow
try {
    $output = .\gradlew signingReport 2>&1
    Write-Host "✅ Gradle task completed successfully!" -ForegroundColor Green
    
    # Extract SHA-1 from output
    $sha1Match = $output | Select-String "SHA1: ([A-F0-9]{40})"
    if ($sha1Match) {
        $sha1 = $sha1Match.Matches[0].Groups[1].Value
        Write-Host "🔑 SHA-1 Fingerprint: $sha1" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "📋 Next steps:" -ForegroundColor Green
        Write-Host "1. Go to Firebase Console → Project Settings" -ForegroundColor White
        Write-Host "2. Select your Android app" -ForegroundColor White
        Write-Host "3. Add this SHA-1: $sha1" -ForegroundColor White
        Write-Host "4. Download the updated google-services.json" -ForegroundColor White
        Write-Host "5. Replace the file in android/app/" -ForegroundColor White
    } else {
        Write-Host "❌ SHA-1 not found in output" -ForegroundColor Red
        Write-Host "Full output:" -ForegroundColor Yellow
        $output
    }
} catch {
    Write-Host "❌ Error running gradlew: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔧 Alternative methods:" -ForegroundColor Yellow
    Write-Host "1. Use Android Studio: View → Tool Windows → Gradle → Tasks → android → signingReport" -ForegroundColor White
    Write-Host "2. Use keytool: keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android" -ForegroundColor White
} 