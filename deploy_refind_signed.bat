@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: =====================================================================
:: deploy_refind_signed.bat
:: Sobe o rEFInd ASSINADO pela MOK para a ESP, junto com o certificado
:: (.cer) da MOK, e aponta o bootmanager para ele.
::
:: REQUISITOS:
::   - Executar COMO ADMINISTRADOR (mountvol /s e bcdedit exigem elevacao)
::   - O arquivo refind_x64-quitto-signed.efi ja deve existir (gerado no WSL)
::
:: O que este script NAO faz:
::   - NAO faz enrollment da MOK (mokutil --import) -> faca a parte manual
::   - NAO mexe em PK / KEK / db / dbx / BIOS
::   - NAO sobrescreve o refind_x64.efi original na ESP (instala ao lado)
:: =====================================================================

:: ----------------------- CONFIGURACAO --------------------------------
set "ESP_LETTER=B:"
set "REPO=D:\Tools\UEFI\Bootloader\dualboot_rEFIind"

:: Binario assinado pela MOK (gerado no Fedora/WSL via sbsign)
set "SIGNED_EFI=%REPO%\refind\refind_x64-quitto-signed.efi"

:: Certificado DER para enrollment (fica disponivel na ESP tambem)
set "MOK_CER=D:\Tools\UEFI\SecureBoot\quitto-mok.cer"

:: Destino na ESP
set "REFIND_DIR_ON_ESP=%ESP_LETTER%\EFI\refind"
set "REFIND_TARGET_NAME=refind_x64-quitto-signed.efi"
:: --------------------------------------------------------------------

echo.
echo ================================================================
echo  Deploy do rEFInd assinado (MOK) + certificado para a ESP
echo ================================================================
echo.

:: Verifica administrador
net session >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Execute este script COMO ADMINISTRADOR.
    echo         Clique direito -> "Executar como administrador".
    pause
    exit /b 1
)

:: 1) Monta a particao EFI (ESP) em B:
echo [1/5] Montando a particao EFI (ESP) em %ESP_LETTER% ...
mountvol %ESP_LETTER% /s
if errorlevel 1 (
    echo [ERRO] Falha ao montar a ESP em %ESP_LETTER%.
    echo        Ja esta montada? Desmonte primeiro: mountvol %ESP_LETTER% /d
    pause
    exit /b 1
)
echo       ESP montada em %ESP_LETTER%
echo.

:: 2) Cria a estrutura de pastas na ESP
echo [2/5] Criando estrutura em %REFIND_DIR_ON_ESP% ...
if not exist "%REFIND_DIR_ON_ESP%" mkdir "%REFIND_DIR_ON_ESP%"
if not exist "%REFIND_DIR_ON_ESP%\keys" mkdir "%REFIND_DIR_ON_ESP%\keys"
echo.

:: 3) Copia o rEFInd ASSINADO (ao lado do original refind_x64.efi)
echo [3/5] Copiando o rEFInd ASSINADO para a ESP (ao lado do original) ...
if not exist "%SIGNED_EFI%" (
    echo [ERRO] Binario assinado nao encontrado: %SIGNED_EFI%
    echo        Gere ele primeiro no WSL (sbsign com quitto-mok.key/.crt).
    goto :fail
)
copy /Y "%SIGNED_EFI%" "%REFIND_DIR_ON_ESP%\%REFIND_TARGET_NAME%"
if errorlevel 1 goto :fail
echo       -> %REFIND_DIR_ON_ESP%\%REFIND_TARGET_NAME%
echo.

:: 4) Copia o CERTIFICADO (.cer) da MOK para a ESP (meio do fluxo)
echo [4/5] Copiando o certificado MOK (.cer) para a ESP ...
if not exist "%MOK_CER%" (
    echo [ERRO] Certificado nao encontrado: %MOK_CER%
    goto :fail
)
copy /Y "%MOK_CER%" "%REFIND_DIR_ON_ESP%\keys\quitto-mok.cer"
if errorlevel 1 goto :fail
echo       -> %REFIND_DIR_ON_ESP%\keys\quitto-mok.cer
echo.

:: 5) Define o rEFInd como boot manager padrao (bcdedit)
echo [5/5] Definindo o rEFInd como boot manager padrao (bcdedit) ...
bcdedit /set "{bootmgr}" path \EFI\refind\%REFIND_TARGET_NAME%
if errorlevel 1 (
    echo [AVISO] bcdedit falhou. Execute manualmente como admin:
    echo         bcdedit /set "{bootmgr}" path \EFI\refind\%REFIND_TARGET_NAME%
    goto :done
)
echo       bootmgr -> \EFI\refind\%REFIND_TARGET_NAME%
echo.

:done
echo.
echo ================================================================
echo  CONCLUIDO.
echo ================================================================
echo.
echo  Proximos passos MANUAIS (o script NAO faz isso):
echo.
echo  1) Enrollment da MOK (no Linux/WSL ou Live USB):
echo       mokutil --import D:\Tools\UEFI\SecureBoot\quitto-mok.cer
echo     e confirme no MokManager na primeira inicializacao.
echo.
echo  2) Desmonte a ESP quando terminar:
echo       mountvol %ESP_LETTER% /d
echo.
echo  Arquivos na ESP:
echo    %REFIND_DIR_ON_ESP%\%REFIND_TARGET_NAME%   (rEFInd assinado)
echo    %REFIND_DIR_ON_ESP%\keys\quitto-mok.cer    (cert da MOK)
echo.
pause
exit /b 0

:fail
echo.
echo [FALHA] Processo interrompido. Verifique os erros acima.
echo           Lembre-se de desmontar a ESP: mountvol %ESP_LETTER% /d
pause
exit /b 1
