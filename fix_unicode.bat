@echo off
powershell -Command "$content = Get-Content 'lib\screens\pet_owner\adoption_form_screen.dart' -Raw; $content = $content -replace [char]0x00A0, ' '; Set-Content 'lib\screens\pet_owner\adoption_form_screen.dart' -Value $content"
echo Fixed non-ASCII characters
