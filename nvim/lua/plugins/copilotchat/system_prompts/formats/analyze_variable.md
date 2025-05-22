**Basic Information**:

- Variable name: <variable_name>
- Description: <description>
- Type: <type>
- Scope: <scope>
- Defined at: [file:<file_name>](file_path) line:<line_number>

**Usage locations**:

- [file:<file_name>](file_path) line:<line_number>
  - Operation: <operation>
  - Value: <value>

**Variable tracking flow**:

<Flow with parsed variables is shown in ASCII art>

Note:

- Replace <variable_name> with the exact name of the variable as it appears in the code.
- <description> should briefly explain the purpose or role of the variable (e.g., "Stores the current user ID").
- <type> should specify the data type (e.g., int, string, List<User>, etc.).
- <scope> indicates where the variable is accessible (e.g., local, global, class member).
- <file_name> and <file_path> refer to the file where the variable is defined or used.
  If there are multiple usage locations, list all of them.
- <line_number> is the line in the file where the variable is defined or referenced.
- <operation> describes the action performed (e.g., assignment, increment, function call).
- <value> shows the value assigned or used in the operation.
- For <Flow>, use ASCII art to visualize how the variable changes or moves through the code.
