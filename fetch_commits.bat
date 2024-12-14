@echo off
setlocal enabledelayedexpansion

:: Check if both arguments are provided
if "%~1"=="" (
    echo Usage: %~nx0 ^<repository-path^> ^<backup-root-folder^>
    exit /b 1
)

if "%~2"=="" (
    echo Usage: %~nx0 ^<repository-path^> ^<backup-root-folder^>
    exit /b 1
)

:: Set the repository path and validate it
set REPO_PATH=%~1
if not exist "%REPO_PATH%\.git" (
    echo Error: The specified folder is not a Git repository: %REPO_PATH%
    exit /b 1
)

:: Set the backup root directory and validate it
set BACKUP_DIRECTORY=%~2
if not exist "%BACKUP_DIRECTORY%" (
    echo The specified backup folder does not exist. Creating: %BACKUP_DIRECTORY%
    mkdir "%BACKUP_DIRECTORY%"
)

:: Change to the repository directory
pushd "%REPO_PATH%"

:: Iterate over all commits
for /f "delims=" %%c in ('git rev-list --all') do (
    set COMMIT_HASH=%%c
    set BACKUP_FOLDER=_%%c
    set BACKUP_ZIP="%BACKUP_DIRECTORY%\%%c.zip"

    :: Check if the backup already exists
    if exist !BACKUP_ZIP! (
        echo Backup for commit %%c already exists. Skipping...
    ) else (
        echo Creating backup for commit %%c...

        :: Create a temporary folder for this commit's files
        if not exist "!BACKUP_FOLDER!" (
            mkdir "!BACKUP_FOLDER!"
        )

        :: Get the list of changed files in the commit
        for /f "delims=" %%f in ('git diff-tree --no-commit-id --name-only -r %%c') do (
            echo Fetching content of %%f from commit %%c
            git show %%c:%%f > "!BACKUP_FOLDER!\%%~nxf"
            if errorlevel 1 (
                echo Failed to fetch content for %%f
            ) else (
                echo Saved content of %%f in !BACKUP_FOLDER!\%%~nxf
            )
        )

        :: Create the ZIP archive
        powershell Compress-Archive -Path "!BACKUP_FOLDER!" -DestinationPath !BACKUP_ZIP!
        if errorlevel 1 (
            echo Failed to create archive for commit %%c
        ) else (
            echo Backup for commit %%c saved to !BACKUP_ZIP!
        )

        :: Clean up the temporary folder
        rmdir /s /q "!BACKUP_FOLDER!"
    )
)

:: Return to the original directory
popd

echo All commits have been processed.
:: pause

