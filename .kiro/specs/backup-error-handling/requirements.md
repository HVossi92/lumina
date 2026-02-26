# Requirements Document

## Introduction

This feature addresses a critical bug in the backup download functionality where the system crashes when the uploads directory doesn't exist. The backup feature currently works locally but fails on production servers that don't have an uploads directory, causing a MatchError that crashes the LiveView process. 

The root cause is that the backup code uses pattern matching that expects the tar command to succeed (`{_output, 0} = System.cmd(...)`), but when `priv/static/uploads` doesn't exist, tar exits with code 2, causing a MatchError. While the photo upload code creates the uploads directory on-demand when photos are uploaded, the backup code assumes it already exists.

This enhancement will add proper error handling to ensure backups can be created regardless of whether the uploads directory exists, and will ensure the directory structure is created during application startup to prevent 404 errors when serving uploaded files.

## Glossary

- **Backup_System**: The system component responsible for creating and serving backup archives
- **Uploads_Directory**: The directory at `priv/static/uploads` containing user-uploaded photos (with subdirectories `originals` and `thumbnails`)
- **Database_Files**: The SQLite database file and its associated WAL and SHM files
- **Tar_Command**: The system tar utility used to create compressed backup archives
- **Backup_Archive**: The compressed tar.gz file containing database files and optionally uploads
- **Application_Startup**: The initialization phase when the Phoenix application starts

## Requirements

### Requirement 1: Handle Missing Uploads Directory

**User Story:** As a system administrator, I want backups to work even when the uploads directory doesn't exist, so that I can always create database backups regardless of the server state.

#### Acceptance Criteria

1. WHEN the uploads directory does not exist, THE Backup_System SHALL create a backup containing only Database_Files
2. WHEN the uploads directory exists, THE Backup_System SHALL create a backup containing both Database_Files and uploaded photos
3. WHEN creating a backup, THE Backup_System SHALL check for the existence of the uploads directory before including it in the Tar_Command arguments
4. THE Backup_System SHALL NOT crash when the uploads directory is missing

### Requirement 2: Robust Tar Command Execution

**User Story:** As a system administrator, I want the backup process to handle tar command failures gracefully, so that I receive clear error messages instead of system crashes.

#### Acceptance Criteria

1. WHEN executing the Tar_Command, THE Backup_System SHALL capture both the exit code and output without pattern matching on success
2. IF the Tar_Command exits with a non-zero code, THEN THE Backup_System SHALL log the error details including exit code and output
3. IF the Tar_Command fails, THEN THE Backup_System SHALL display a user-friendly error message to the administrator
4. WHEN the Tar_Command fails, THE Backup_System SHALL NOT crash the LiveView process

### Requirement 3: User Feedback and Error Messages

**User Story:** As a system administrator, I want clear feedback about backup creation status, so that I know whether the backup succeeded or failed and why.

#### Acceptance Criteria

1. WHEN a backup is successfully created, THE Backup_System SHALL trigger the download as it currently does
2. IF backup creation fails, THEN THE Backup_System SHALL display an error flash message with details about the failure
3. WHEN the uploads directory is missing, THE Backup_System SHALL inform the user that the backup contains only database files
4. THE Backup_System SHALL maintain the loading state indicator during backup creation

### Requirement 4: Maintain Existing Functionality

**User Story:** As a system administrator, I want the backup feature to continue working exactly as before when all directories exist, so that existing workflows are not disrupted.

#### Acceptance Criteria

1. WHEN all required directories exist, THE Backup_System SHALL create backups with identical content to the current implementation
2. THE Backup_System SHALL preserve the existing backup filename format with timestamp
3. THE Backup_System SHALL continue to include Database_Files and their associated WAL and SHM files when they exist
4. THE Backup_System SHALL maintain the existing download mechanism via JavaScript push events

### Requirement 5: Backup Archive Integrity

**User Story:** As a system administrator, I want backup archives to be valid and extractable, so that I can restore data when needed.

#### Acceptance Criteria

1. WHEN a Backup_Archive is created, THE Backup_System SHALL verify the archive file exists before triggering download
2. THE Backup_Archive SHALL be a valid tar.gz file that can be extracted with standard tar utilities
3. WHEN extracted, THE Backup_Archive SHALL preserve the directory structure of included files
4. THE Backup_System SHALL clean up temporary backup files after a reasonable time period

### Requirement 6: Uploads Directory Initialization

**User Story:** As a system operator, I want the uploads directory structure to be created during application startup, so that uploaded files can be served without 404 errors.

#### Acceptance Criteria

1. WHEN the application starts, THE Application_Startup SHALL create the Uploads_Directory if it does not exist
2. WHEN the application starts, THE Application_Startup SHALL create the `originals` subdirectory within Uploads_Directory if it does not exist
3. WHEN the application starts, THE Application_Startup SHALL create the `thumbnails` subdirectory within Uploads_Directory if it does not exist
4. IF directory creation fails during startup, THEN THE Application_Startup SHALL log a warning but continue starting the application
5. THE Application_Startup SHALL ensure directory creation happens before the web server accepts requests
