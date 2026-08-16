# Digital System Design Lab Assignment Workflow

@/home/kshyst/.codex/RTK.md

## Scope

Use these instructions for every assignment under this directory.

## Required workflow

1. Read  `template.tex`, and the complete target-assignment PDF before writing anything.
2. Extract every requested question, deliverable, filename rule, experiment step, and evidence requirement from the PDF. Do not infer requirements from another assignment.
4. Write the complete Persian answers first in `<assignment-folder>/answers.txt`.
5. Create `<assignment-folder>/report.tex` from the structure and Persian commands demonstrated in the root `template.tex`. Leave the root template unchanged.
6. Write only the report's main content: abstract, keywords, sections, tables or figures, conclusion, and references. Do not add a document class, packages, title pages, or other preamble material.
7. Keep the report in formal, coherent Persian. Use Persian letters and digits, correct half-spaces and punctuation, and `\لر{...}` or the template's equivalent for left-to-right technical terms.
8. Cite research claims in the body and provide complete, clickable references. Every table and figure must have a caption, label, and preceding textual reference.
9. Use native TeX tables when they communicate the result clearly. If an experiment requires a student-produced screenshot, photograph, plot, add a clearly named figure placeholder and tell the user the exact expected filename and content.
10. Never invent measurements, screenshots or personal implementation evidence. Mark missing evidence clearly for the user to supply.
11. Do not compile TeX unless the user explicitly requests compilation. Perform text-only checks for structure, balanced environments, citations, missing image files, spelling, and consistency with `answers.txt`.
12. For writing codes in the report, use latex listing and also the line numbers should be the exact line numbers of the main code.

## Change boundaries

- Preserve `template.tex` as the authoritative example.
- Modify only the target assignment folder and files explicitly requested by the user.
- Do not create speculative scripts, dependencies, build systems, or extra documentation.
