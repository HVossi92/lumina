# Design Document: Backup Error Handling

## Overview

This design addresses the backup system crash that occurs when the uploads directory doesn't exist. The solution involves two main components:

1. **Robust Backup Creation**: Modify the backup LiveView to handle missing directories gracefully by checking for directory existence before including them in the tar command, and properly handling tar command failures without pattern matching on exit code 0.

2. **Directory Initialization**: Add an application startup module that ensures the uploads directory structure exists before the web server starts accepting requests, preventing 404 errors when serving uploaded files.

The design maintains backward compatibility with existing backup functionality while adding defensive programming practices to handle edge cases in production environments.

## Architecture

### Current Architecture Issues

The current backup implementation has a critical flaw at line 40 of `backup.ex`:

```elixir
{_output, 0} = System.cmd("tar", tar_args, stderr_to_stdout: true)
```

This pattern match assumes the tar command will always succeed (exit code 0). When the uploads directory doesn't exist, tar exits with code 2, causing a `MatchError` that crashes the LiveView process.

### Proposed Architecture

The solution involves three layers:

1. **Application Layer**: A new `Lumina.Application.EnsureDirectories` module that runs during application startup to create required directory structures.

2. **LiveView Layer**: Modified `LuminaWeb.AdminLive.Backup` that:
   - Checks for directory existence before building tar arguments
   - Captures tar command results without pattern matching
   - Handles errors gracefully with user feedback
   - Logs failures for debugging

3. **Controller Layer**: The existing `LuminaWeb.AdminController` remains unchanged as it already handles missing files correctly.

### Data Flow

```
Application Start
    ↓
EnsureDirectories.init()
    ↓
Create priv/static/uploads/{originals,thumbnails}
    ↓
Phoenix Endpoint starts
    ↓
[User triggers backup]
    ↓
Backup LiveView checks directory existence
    ↓
Build tar args (conditionally include uploads)
    ↓
Execute tar command (capture exit code)
    ↓
If success: trigger download
If failure: show error message
```

## Components and Interfaces

### Component 1: EnsureDirectories Module

**Location**: `lib/lumina/application/ensure_directories.ex`

**Purpose**: Create required directory structures during application startup.

**Interface**:

```elixir
defmodule Lumina.Application.EnsureDirectories do
  require Logger

  @doc """
  Ensures all required directories exist.
  Called during application startup.
  Returns :ok regardless of success to allow app to start.
  """
  def init() :: :ok

  @doc """
  Creates a directory and logs the result.
  Returns :ok on success, {:error, reason} on failure.
  """
  defp ensure_directory(path :: String.t()) :: :ok | {:error, File.posix()}
end
```

**Behavior**:
- Creates `priv/static/uploads` directory
- Creates `priv/static/uploads/originals` subdirectory
- Creates `priv/static/uploads/thumbnails` subdirectory
- Logs success or failure for each directory
- Always returns `:ok` to prevent application startup failure
- Uses `File.mkdir_p/1` which succeeds if directory already exists

**Integration Point**: Called from `Lumina.Application.start/2` before the Phoenix endpoint starts.

### Component 2: Modified Backup LiveView

**Location**: `lib/lumina_web/live/admin_live/backup.ex`

**Modified Function**: `handle_event("download_backup", _params, socket)`

**Changes**:

1. **Directory Existence Check**:
```elixir
uploads_path = Path.join(File.cwd!(), "priv/static/uploads")
uploads_exist? = File.dir?(uploads_path)
```

2. **Conditional Tar Arguments**:
```elixir
tar_args =
  if uploads_exist? do
    ["-czf", backup_path, "-C", db_dir | db_files] ++
      ["-C", File.cwd!(), "priv/static/uploads"]
  else
    ["-czf", backup_path, "-C", db_dir | db_files]
  end
```

3. **Robust Command Execution**:
```elixir
case System.cmd("tar", tar_args, stderr_to_stdout: true) do
  {_output, 0} ->
    # Success: trigger download
    {:noreply, push_event(socket, "trigger_download", %{...})}
  
  {output, exit_code} ->
    # Failure: log and show error
    Logger.error("Backup creation failed: exit_code=#{exit_code}, output=#{output}")
    {:noreply, put_flash(socket, :error, "Failed to create backup. Please try again or contact support.")}
end
```

**Error Handling Strategy**:
- Log detailed error information (exit code, tar output) for debugging
- Show user-friendly error message without technical details
- Maintain LiveView process (no crash)
- Keep loading state management intact

### Component 3: User Feedback Enhancement

**Template Changes**: Add informational message when uploads directory is missing.

**Approach**: Use a conditional alert in the template to inform users about backup contents:

```elixir
<%= if @uploads_exist? do %>
  <div class="alert alert-info">
    Backup will include database and all uploaded photos.
  </div>
<% else %>
  <div class="alert alert-warning">
    Backup will include database only (no photos uploaded yet).
  </div>
<% end %>
```

**Socket Assignment**: Add `uploads_exist?` to socket assigns in `mount/3`:

```elixir
uploads_path = Path.join(File.cwd!(), "priv/static/uploads")
uploads_exist? = File.dir?(uploads_path)

assign(socket,
  page_title: "Admin Backup",
  uploads_exist?: uploads_exist?
)
```

## Data Models

No new data models are required. The existing data structures remain unchanged:

### Backup Metadata (Implicit)

```elixir
%{
  filename: String.t(),        # "lumina_backup_YYYYMMDD_HHMMSS.tar.gz"
  path: String.t(),            # Full path in system temp directory
  timestamp: DateTime.t(),     # UTC timestamp for filename
  includes_uploads: boolean()  # Whether uploads directory was included
}
```

### Tar Command Arguments

```elixir
# Type: list(String.t())
# Example with uploads:
["-czf", "/tmp/lumina_backup_20250128_143022.tar.gz",
 "-C", "/app/data", "lumina.db", "lumina.db-wal", "lumina.db-shm",
 "-C", "/app", "priv/static/uploads"]

# Example without uploads:
["-czf", "/tmp/lumina_backup_20250128_143022.tar.gz",
 "-C", "/app/data", "lumina.db", "lumina.db-wal", "lumina.db-shm"]
```

### System Command Result

```elixir
# Type: {String.t(), non_neg_integer()}
# Success: {output, 0}
# Failure: {error_output, exit_code}
```


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Backup Contents Without Uploads Directory

*For any* backup operation when the uploads directory does not exist, the created backup archive should contain only database files (database file, WAL file if exists, SHM file if exists) and should not contain any uploads directory.

**Validates: Requirements 1.1**

### Property 2: Backup Contents With Uploads Directory

*For any* backup operation when the uploads directory exists, the created backup archive should contain both database files and the uploads directory with all its contents.

**Validates: Requirements 1.2**

### Property 3: No Crash on Backup Failures

*For any* backup operation that encounters an error (missing uploads directory, tar command failure, invalid arguments), the LiveView process should remain alive and responsive after the operation completes.

**Validates: Requirements 1.4, 2.4**

### Property 4: Error Logging on Tar Failure

*For any* tar command execution that exits with a non-zero code, the system should log an error message containing both the exit code and the tar command output.

**Validates: Requirements 2.2**

### Property 5: Error Message Display on Failure

*For any* backup operation that fails, the system should set a flash error message that is visible to the user.

**Validates: Requirements 2.3**

### Property 6: Download Trigger on Success

*For any* successful backup operation, the system should push a "trigger_download" event to the client with the correct backup filename and URL.

**Validates: Requirements 3.1**

### Property 7: Backward Compatibility

*For any* backup operation when all directories exist and contain files, the created backup archive should contain the same files as the original implementation (database files + uploads directory).

**Validates: Requirements 4.1**

### Property 8: Filename Format Preservation

*For any* backup operation, the generated backup filename should match the pattern `lumina_backup_YYYYMMDD_HHMMSS.tar.gz` where YYYYMMDD_HHMMSS represents a valid UTC timestamp.

**Validates: Requirements 4.2**

### Property 9: File Existence Check Before Download

*For any* backup operation that completes successfully, the system should verify the backup archive file exists in the filesystem before triggering the download event.

**Validates: Requirements 5.1**

### Property 10: Archive Validity

*For any* created backup archive, the file should be a valid tar.gz archive that can be successfully extracted using standard tar utilities without errors.

**Validates: Requirements 5.2**

### Property 11: Directory Initialization Completeness

*For any* call to the directory initialization function, all three required directories should exist after the function completes: `priv/static/uploads`, `priv/static/uploads/originals`, and `priv/static/uploads/thumbnails`.

**Validates: Requirements 6.1, 6.2, 6.3**

### Property 12: Startup Error Handling Resilience

*For any* directory creation failure during application startup (due to permissions or other filesystem errors), the initialization function should log a warning and return `:ok` to allow the application to continue starting.

**Validates: Requirements 6.4**

## Error Handling

### Error Categories

1. **Missing Directory Errors**
   - **Cause**: Uploads directory doesn't exist
   - **Handling**: Check directory existence before including in tar args
   - **User Impact**: Backup created with database only, user informed via UI message
   - **Recovery**: Automatic - system adapts to missing directory

2. **Tar Command Failures**
   - **Cause**: Invalid arguments, filesystem errors, insufficient disk space
   - **Handling**: Capture exit code and output, log details, show user error
   - **User Impact**: Backup fails, error message displayed
   - **Recovery**: Manual - user retries or contacts support

3. **Directory Creation Failures**
   - **Cause**: Insufficient permissions, read-only filesystem
   - **Handling**: Log warning, return :ok to allow app startup
   - **User Impact**: Uploads may fail later, but app remains functional
   - **Recovery**: Manual - fix filesystem permissions

### Error Logging Strategy

All errors should be logged with appropriate severity:

```elixir
# Tar command failure (ERROR level)
Logger.error("Backup creation failed: exit_code=#{exit_code}, output=#{output}")

# Directory creation failure (WARNING level)
Logger.warning("Failed to create directory #{path}: #{inspect(reason)}")

# Directory creation success (INFO level)
Logger.info("Created directory: #{path}")
```

### User-Facing Error Messages

Error messages should be:
- **User-friendly**: No technical jargon or stack traces
- **Actionable**: Suggest next steps when possible
- **Consistent**: Use flash messages for all errors

Examples:
- Success: "Backup created successfully" (implicit via download)
- Failure: "Failed to create backup. Please try again or contact support."
- Info: "Backup will include database only (no photos uploaded yet)."

## Testing Strategy

### Dual Testing Approach

This feature requires both unit tests and property-based tests to ensure comprehensive coverage:

- **Unit tests**: Verify specific examples, edge cases, and error conditions
- **Property tests**: Verify universal properties across all inputs

### Property-Based Testing

We will use the **StreamData** library for Elixir property-based testing. Each property test should:
- Run a minimum of 100 iterations
- Reference its design document property in a comment
- Use the tag format: `@tag feature: "backup-error-handling", property: N`

Example property test structure:

```elixir
@tag feature: "backup-error-handling", property: 1
property "backup contains only database files when uploads directory missing" do
  check all(
    # Generate test data
    iterations: 100
  ) do
    # Test implementation
  end
end
```

### Unit Testing Focus

Unit tests should cover:

1. **Specific Examples**:
   - Backup with no uploads directory
   - Backup with empty uploads directory
   - Backup with uploads containing files

2. **Edge Cases**:
   - Database files without WAL/SHM files
   - Uploads directory exists but is empty
   - Tar command with invalid arguments

3. **Integration Points**:
   - LiveView event handling
   - Flash message setting
   - Push event triggering
   - Directory initialization during app startup

4. **Error Conditions**:
   - Tar command failures
   - Missing database files
   - Insufficient disk space
   - Permission errors

### Test Organization

Tests should be organized into separate files:

- `test/lumina_web/live/admin_live/backup_test.exs` - LiveView unit tests
- `test/lumina_web/live/admin_live/backup_property_test.exs` - Property-based tests
- `test/lumina/application/ensure_directories_test.exs` - Directory initialization tests

### Mocking Strategy

For testing tar command failures without actually breaking the system:
- Use `System.cmd/3` with invalid arguments to trigger failures
- Mock filesystem operations for permission error testing
- Use temporary directories for all file operations in tests

### Test Data Management

- Create temporary directories for each test
- Clean up all temporary files after tests
- Use ExUnit's `on_exit` callback for cleanup
- Never rely on global state or shared directories
