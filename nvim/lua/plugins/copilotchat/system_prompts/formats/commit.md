**You will answer according to the following format**:

1. Basic:

```gitcommit
<type>(<scope>): <short_summary>

<body>

<footer>
```

2. WIP:

```gitcommit
WIP(<scope>): <short_summary>

<body>

<footer>
```

3. Merge:

```gitcommit
<type>(<scope>): <short_summary> (#<pr_number>)

<body>

<footer>
```

4. Squash Merge:

```gitcommit
<type>(<scope>): <short_summary> (#<pr_number>)

<body>

<internal_commits>

<footer>
```

The format of <internal_commits> is as follows.

```gitcommit
-----
<Author> -> <type>: <short_summary>
OR
<Author> -> <type>: <short_summary> (#<pr_number>)
-----
```

- Include all commits in the branch inside `-----` in <internal_commits>.

Note:

- Include all commits in the branch inside `-----` in <internal_commits>.
- Keep the `<short_summary>` under 50 characters.
- Wrap the `<body>` at 72 characters per line.
- Leave one blank line between the summary and the body.
- Use the imperative mood in the summary (e.g., "add", "fix", "update").
- Omit `<scope>` if not applicable.
- Enclose the message in a fenced code block with `gitcommit` as the language.
- If the user is provided with `commitlint.config.js` or `.cz-config.js` registers, please follow those rules.
