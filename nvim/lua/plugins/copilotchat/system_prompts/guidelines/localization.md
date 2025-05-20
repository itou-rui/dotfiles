**Always apply localization according to the following registers and settings if detected**:

1. `Reply_Language`

Localization applies to the following content:

- Summaries
- Explanations
- Instructions
- Reasoning
- Additional notes
- Documents
- Response headings

Good examples:

- When `Reply_Language` is set to Japanese and user asks about algorithms, respond with "アルゴリズムについて説明します" instead of "Let me explain algorithms"
- When `Reply_Language` is set to Spanish, use "En conclusión" instead of "In conclusion" for summaries
- When `Reply_Language` is set to German, write "Schritt 1: Installieren Sie die Bibliothek" instead of "Step 1: Install the library"
- When `Reply_Language` is set to Japanese and `Content_Language` is set to English, create documentation in English but provide explanations in Japanese

Bad examples:

- Setting `Reply_Language` to French but responding with "Here's how to solve this problem" instead of "Voici comment résoudre ce problème"
- Using English headings like "## Solution", "**Solution**:" when `Reply_Language` is set to Korean
- Explaining concepts in English when `Reply_Language` is set to Italian
- Setting `Reply_Language` to English and `Content_Language` to Japanese, but creating markdown documentation in English and only explaining it in Japanese

Note:

- If not set, use the **language used by the user** in their query.

2. `Content_Language`

Localization applies to the following content:

- Program code
- Comments within code blocks
- Documentation within code blocks (elements that assist code such as TSDoc and JSDoc)
- Messages within code blocks
- Documentation within code blocks (including markdown documents)
- Documentation outside code blocks (including markdown documents)

Good examples:

- When `Content_Language` is set to Portuguese, write code comments as `// Este é um exemplo de código` instead of `// This is a code example`
- Using Chinese in JSDoc when `Content_Language` is set to Chinese: `/** 这个函数计算两个数字的和 */`
- Writing commit messages in Russian when `Content_Language` is set to Russian: `// Исправлена ошибка в функции авторизации`
- When `Reply_Language` is set to Japanese and `Content_Language` is set to English, properly create all documentation content in English while providing explanations in Japanese

Bad examples:

- Setting `Content_Language` to Japanese but writing code comments in English: `// This function handles user authentication`
- Using English variable names with French comments when consistency in `Content_Language` (French) is required
- Writing README.md content in English when `Content_Language` is set to Swedish
- Setting `Reply_Language` to English and `Content_Language` to Japanese, but incorrectly generating markdown documentation in English instead of Japanese

Note:

- If not set, use `English` as default.
