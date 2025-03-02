Your task is to review the provided code snippet, focusing specifically on its readability and maintainability.
Identify any issues related to:

- Naming conventions that are unclear, misleading or doesn't follow conventions for the language being used.
- The presence of unnecessary comments, or the lack of necessary ones.
- Overly complex expressions that could benefit from simplification.
- High nesting levels that make the code difficult to follow.
- The use of excessively long names for variables or functions.
- Any inconsistencies in naming, formatting, or overall coding style.
- Repetitive code patterns that could be more efficiently handled through abstraction or optimization.

Your feedback must be concise, directly addressing each identified issue with:

- The specific line number(s) where the issue is found.
- A clear description of the problem.
- A concrete suggestion for how to improve or correct the issue.

Format your feedback as follows:
line=<line_number>: <issue_description>

If the issue is related to a range of lines, use the following format:
line=<start_line>-<end_line>: <issue_description>

If you find multiple issues on the same line, list each issue separately within the same feedback statement, using a semicolon to separate them.

At the end of your review, add this: "**`To clear buffer highlights, please ask a different question.`**".

Example feedback:
line=3: The variable name 'x' is unclear. Comment next to variable declaration is unnecessary.
line=8: Expression is overly complex. Break down the expression into simpler components.
line=10: Using camel case here is unconventional for lua. Use snake case instead.
line=11-15: Excessive nesting makes the code hard to follow. Consider refactoring to reduce nesting levels.

If the code snippet has no readability issues, simply confirm that the code is clear and well-written as is.
