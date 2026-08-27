# Harvesting the Corpus

How to pull Nic's corrections out of the opencode transcripts.

## The Database

opencode stores sessions in SQLite at
`~/.local/share/opencode/opencode-stable.db`. The file runs to gigabytes, and
opencode holds it open, so always pass `-readonly`.

The tables you need:

- `session` has `id`, `directory`, `title`, `parent_id`, and `time_created`.
  `directory` is the working directory, which is how you scope by repository.
  `parent_id` marks subagent sessions.
- `message` has `session_id` and a `data` JSON column holding `role`.
- `part` has `message_id`, `session_id`, and a `data` JSON column. Text lives at
  `$.text` where `$.type` is `text`. Tool calls live at `$.tool`, with arguments
  under `$.state.input`.

Message text sits in `part` rather than `message`, which is the detail that trips
up a first attempt.

## Orienting

Start by seeing which directories hold sessions, so the scope discussion has
numbers behind it:

```sql
SELECT directory, COUNT(*) FROM session GROUP BY directory ORDER BY COUNT(*) DESC;
```

## Scoping by Artifact

The sharpest scoping. Find sessions where a tool edited a file matching the
domain, then take the user messages from those sessions.

```sql
WITH ds AS (
  SELECT DISTINCT s.id
  FROM session s JOIN part p ON p.session_id = s.id
  WHERE s.directory IN ('/path/to/repo')
    AND json_extract(p.data, '$.tool') IN ('edit','write','patch','multiedit')
    AND json_extract(p.data, '$.state.input.filePath') LIKE '%/design/%.md'
)
SELECT s.id, datetime(s.time_created/1000,'unixepoch') AS sdate, s.title AS stitle,
       datetime(p.time_created/1000,'unixepoch') AS mtime,
       json_extract(p.data,'$.text') AS text
FROM part p
JOIN message m ON m.id = p.message_id
JOIN session s ON s.id = p.session_id
WHERE p.session_id IN (SELECT id FROM ds)
  AND json_extract(m.data,'$.role') = 'user'
  AND json_extract(p.data,'$.type') = 'text'
ORDER BY s.time_created DESC, p.time_created ASC, p.id ASC;
```

Change the `LIKE` to suit the domain. Go review feedback wants `%.go`, and
Python wants `%.py`.

To find what file types a repo's sessions actually touch, which helps pick the
filter:

```sql
SELECT json_extract(p.data,'$.state.input.filePath') AS f, COUNT(*) c
FROM part p JOIN session s ON s.id = p.session_id
WHERE s.directory = '/path/to/repo'
  AND json_extract(p.data,'$.tool') IN ('edit','write','patch','multiedit')
GROUP BY f ORDER BY c DESC;
```

## Scoping by Repository

Drop the artifact filter and keep the directory filter. Use this where the domain
is a project rather than a file type.

## Scoping by Signal

For domains with no artifact, such as how a conversation goes wrong, filter on
correction markers instead. Pull all user text for a directory and grep it:

```bash
rg -i "^(no|nope|don't|stop)\b|i asked you|you keep|too verbose|that's not what" corpus.txt
```

Treat the result as a lead rather than a corpus. Signal scoping has a low
precision, so read a sample and refine the pattern before committing to it.

## Getting the Text Out

Use `.mode json` and write to a file, then reshape with `jq`. Piping raw text
through a shell mangles anything containing quotes or backticks.

```bash
sqlite3 -readonly opencode-stable.db < query.sql > raw.json
jq -r 'group_by(.sid) | sort_by(.[0].sdate) | reverse | .[] |
  "@@@SESSION \(.[0].sdate) | \(.[0].stitle) | \(.[0].sid)\n" +
  ([.[] | "\n--- USER MSG \(.mtime) ---\n\(.text)"] | join("\n"))
' raw.json > all.txt
```

The `@@@SESSION` marker gives a split point that survives arbitrary message
content.

## Chunking for Parallel Reading

Split at session boundaries so no subagent reads half a conversation. Balance by
size rather than by count, since session lengths vary by two orders of magnitude.

```python
import re
txt = open('all.txt').read()
parts = [p for p in re.split(r'(?m)^(?=@@@SESSION )', txt) if p.strip()]
parts.sort(key=len, reverse=True)
N = 6
chunks, sizes = [[] for _ in range(N)], [0]*N
for p in parts:                      # longest first into the emptiest bin
    i = sizes.index(min(sizes))
    chunks[i].append(p); sizes[i] += len(p)
for i, c in enumerate(chunks):
    open(f'chunk{i+1}.txt','w').write('\n'.join(c))
```

Aim for roughly 300KB per chunk, which handled a 1.9MB corpus across half a
dozen subagents.

## Getting an Agent's Own Prose

Swap `role = 'user'` for `role = 'assistant'` to pull the other side. Useful for
comparing an agent's habits against Nic's, though see the warning below before
computing any rate.

## Attribution Traps

**Pasted content pollutes any frequency measurement.** Nic's messages quote
files, diffs, and error output. In one measurement, 40 of 50 unique matches for a
word came from him pasting the same document repeatedly, so the apparent rate was
an order of magnitude too high. Deduplicate matches, then separate his prose from
what he quoted, before counting.

```bash
rg -o -i '.{0,60}\bWORD\b.{0,40}' corpus.txt | sort -u > uniq.txt
rg -v '^\s*[-`#|*]|`[^`]+`|^\s*\w+:' uniq.txt    # rough filter for his prose
```

**Documents in a repo are rarely purely his.** Most started as an agent's draft
that he copy edited. That inverts what a surviving defect means: it survived his
attention rather than expressing his preference. Check `git log` for who wrote
the first version, and ask him if the history doesn't say.
