# Implementation Plan: Backup Error Handling

## Overview

This implementation plan addresses the backup system crash by adding proper error handling and directory initialization. The work is organized into three main areas: directory initialization during app startup, backup LiveView modifications for robust error handling, and comprehensive testing to ensure correctness.

## Tasks

- [ ] 1. Create directory initialization module
  - [x] 1.1 Create `lib/lumina/application/ensure_directories.ex` module
    - Implement `init/0` function that creates required directories
    - Create `priv/static/uploads` directory
    - Create `priv/static/uploads/originals` subdirectory
    - Create `priv/static/uploads/thumbnails` subdirectory
    - Use `File.mkdir_p/1` for idempotent directory creation
    - Log success/failure for each directory with appropriate severity
    - Always return `:ok` to prevent app startup failure
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

  - [ ]* 1.2 Write property test for directory initialization
    - **Property 11: Directory Initialization Completeness**
    - **Validates: Requirements 6.1, 6.2, 6.3**
    - Test that all three directories exist after init
    - Use temporary directory for testing
    - Clean up test directories in `on_exit` callback

  - [ ]* 1.3 Write property test for startup error handling
    - **Property 12: Startup Error Handling Resilience**
    - **Validates: Requirements 6.4**
    - Test that init returns :ok even when directory creation fails
    - Verify warning is logged on failure
    - Use read-only parent directory to trigger failure

- [ ] 2. Integrate directory initialization into application startup
  - [x] 2.1 Modify `lib/lumina/application.ex` to call `EnsureDirectories.init/0`
    - Add call before Phoenix endpoint starts in `start/2` function
    - Ensure it runs before the supervision tree starts
    - _Requirements: 6.5_

  - [ ]* 2.2 Write unit test for application startup integration
    - Verify `EnsureDirectories.init/0` is called during app start
    - Test that app starts successfully even if directory creation fails

- [ ] 3. Checkpoint - Verify directory initialization
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 4. Modify backup LiveView for robust error handling
  - [x] 4.1 Add directory existence check in `mount/3`
    - Check if `priv/static/uploads` exists
    - Assign `uploads_exist?` to socket
    - _Requirements: 1.3_

  - [x] 4.2 Update `handle_event("download_backup", ...)` to check directory existence
    - Check if uploads directory exists before building tar args
    - Conditionally include uploads directory in tar arguments
    - Build tar args list based on directory existence
    - _Requirements: 1.1, 1.2, 1.3_

  - [x] 4.3 Replace pattern matching with case statement for tar command
    - Change from `{_output, 0} = System.cmd(...)` to `case System.cmd(...)`
    - Handle success case (exit code 0): trigger download as before
    - Handle failure case (non-zero exit code): log error and show flash message
    - Log error with exit code and tar output for debugging
    - Show user-friendly error message via `put_flash`
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [x] 4.4 Add file existence verification before triggering download
    - Check that backup file exists before pushing download event
    - Handle case where file doesn't exist (log error, show message)
    - _Requirements: 5.1_

  - [ ]* 4.5 Write property test for backup contents without uploads
    - **Property 1: Backup Contents Without Uploads Directory**
    - **Validates: Requirements 1.1**
    - Delete uploads directory before test
    - Create backup and extract it
    - Verify archive contains only database files
    - Verify archive does not contain uploads directory

  - [ ]* 4.6 Write property test for backup contents with uploads
    - **Property 2: Backup Contents With Uploads Directory**
    - **Validates: Requirements 1.2**
    - Ensure uploads directory exists with test files
    - Create backup and extract it
    - Verify archive contains database files and uploads directory

  - [ ]* 4.7 Write property test for no crash on failures
    - **Property 3: No Crash on Backup Failures**
    - **Validates: Requirements 1.4, 2.4**
    - Test with missing uploads directory
    - Test with invalid tar arguments
    - Verify LiveView process remains alive after each failure
    - Use `Process.alive?/1` to check process status

  - [ ]* 4.8 Write property test for error logging
    - **Property 4: Error Logging on Tar Failure**
    - **Validates: Requirements 2.2**
    - Force tar to fail with invalid arguments
    - Capture log output
    - Verify log contains exit code and tar output

  - [ ]* 4.9 Write property test for error message display
    - **Property 5: Error Message Display on Failure**
    - **Validates: Requirements 2.3**
    - Force backup to fail
    - Verify flash error message is set
    - Check message is user-friendly (no technical details)

  - [ ]* 4.10 Write property test for download trigger
    - **Property 6: Download Trigger on Success**
    - **Validates: Requirements 3.1**
    - Create successful backup
    - Verify push_event is called with correct parameters
    - Check URL and filename are correct

  - [ ]* 4.11 Write property test for backward compatibility
    - **Property 7: Backward Compatibility**
    - **Validates: Requirements 4.1**
    - Set up environment with all directories and files
    - Create backup
    - Verify contents match original implementation

  - [ ]* 4.12 Write property test for filename format
    - **Property 8: Filename Format Preservation**
    - **Validates: Requirements 4.2**
    - Create backup
    - Verify filename matches pattern `lumina_backup_YYYYMMDD_HHMMSS.tar.gz`
    - Verify timestamp is valid UTC time

  - [ ]* 4.13 Write property test for file existence check
    - **Property 9: File Existence Check Before Download**
    - **Validates: Requirements 5.1**
    - Create backup successfully
    - Verify file exists before download event is pushed
    - Test case where file is deleted between creation and check

  - [ ]* 4.14 Write property test for archive validity
    - **Property 10: Archive Validity**
    - **Validates: Requirements 5.2**
    - Create backup
    - Extract archive using tar command
    - Verify extraction succeeds without errors
    - Verify extracted files are readable

- [ ] 5. Update backup LiveView template for user feedback
  - [x] 5.1 Add conditional alert message based on `@uploads_exist?`
    - Show info message when uploads exist: "Backup will include database and all uploaded photos"
    - Show warning message when uploads missing: "Backup will include database only (no photos uploaded yet)"
    - Use existing alert component styles
    - _Requirements: 3.3_

  - [ ]* 5.2 Write unit test for template rendering
    - Test that correct message is shown when `uploads_exist?` is true
    - Test that correct message is shown when `uploads_exist?` is false
    - Use `Phoenix.LiveViewTest` helpers

- [ ] 6. Checkpoint - Verify all backup functionality
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 7. Add StreamData dependency if not present
  - [-] 7.1 Check if StreamData is in `mix.exs` dependencies
    - If not present, add `{:stream_data, "~> 1.0", only: [:test, :dev]}` to deps
    - Run `mix deps.get` to fetch the dependency
    - _Requirements: Testing Strategy_

- [ ] 8. Write integration tests for complete backup flow
  - [ ]* 8.1 Write integration test for successful backup with uploads
    - Mount LiveView as admin user
    - Ensure uploads directory exists with files
    - Trigger backup event
    - Verify download event is pushed
    - Verify backup file exists and is valid
    - _Requirements: 3.1, 4.1, 5.1, 5.2_

  - [ ]* 8.2 Write integration test for successful backup without uploads
    - Mount LiveView as admin user
    - Ensure uploads directory does not exist
    - Trigger backup event
    - Verify download event is pushed
    - Verify backup file exists and contains only database
    - _Requirements: 1.1, 3.1_

  - [ ]* 8.3 Write integration test for backup failure handling
    - Mount LiveView as admin user
    - Force tar command to fail (invalid database path)
    - Trigger backup event
    - Verify error flash message is displayed
    - Verify LiveView remains functional
    - _Requirements: 2.3, 2.4_

- [ ] 9. Final checkpoint - Complete verification
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties with minimum 100 iterations
- Unit tests validate specific examples and edge cases
- StreamData library is used for property-based testing in Elixir
- All tests should use temporary directories and clean up after themselves
- The implementation maintains backward compatibility with existing functionality
