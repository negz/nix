# Harvesting the Corpus

How to pull Nic's corrections out of the opencode transcripts.

## The Database

opencode stores sessions in SQLite at `~/.local/share/opencode/opencode.db`. The
file runs to gigabytes, and opencode holds it open, so always pass `-readonly`.

The tables you need:

- `session_v2` has `id`, `directory`, `title`, `parent_id`, and `time_created`.
  `directory` is the working directory, which is how you scope by repository.
  `parent_id` marks subagent sessions.
- `session_message` has `session_id`, `type`, `seq`, `time_created`, and a
  `data` JSON column. `type` is `user` or `assistant`, among others. A user
  message keeps its text at `$.text`. An assistant message's text and tool
  calls are elements of the `$.content` array. A tool call has `$.type` of `tool`,
  its name at `$.name`, and its arguments under `$.state.input`.

The edit and write tools take the file as `path`, except in sessions opencode 1
recorded, which call it `filePath`. Those sessions also sit, unconverted, in
opencode 1's `session`, `message` and `part` tables. Ignore those tables.
opencode 2 converted their contents once, and they miss everything since.

## Orienting

Start by seeing which directories hold sessions, so the scope discussion has
numbers behind it:

```sql
SELECT directory, COUNT(*) FROM session_v2 GROUP BY directory ORDER BY COUNT(*) DESC;
```

## Scoping by Artifact

The sharpest scoping. Find sessions where a tool edited a file matching the
domain, then take the user messages from those sessions.

```sql
WITH edits AS (
  SELECT m.session_id,
         COALESCE(json_extract(c.value, '$.state.input.path'),
                  json_extract(c.value, '$.state.input.filePath')) AS file
  FROM session_message m, json_each(m.data, '$.content') c
  WHERE m.type = 'assistant'
    AND json_extract(c.value, '$.type') = 'tool'
    AND json_extract(c.value, '$.name') IN ('edit', 'write')
),
ds AS (
  SELECT DISTINCT e.session_id AS id
  FROM edits e JOIN session_v2 s ON s.id = e.session_id
  WHERE s.directory IN ('/path/to/repo')
    AND e.file LIKE '%/design/%.md'
)
SELECT s.id AS sid, datetime(s.time_created/1000,'unixepoch') AS sdate,
       s.title AS stitle, datetime(m.time_created/1000,'unixepoch') AS mtime,
       json_extract(m.data, '$.text') AS text
FROM session_message m
JOIN session_v2 s ON s.id = m.session_id
WHERE m.session_id IN (SELECT id FROM ds)
  AND m.type = 'user'
ORDER BY s.time_created DESC, m.seq ASC;
```

Change the `LIKE` to suit the domain. Go review feedback wants `%.go`, and
Python wants `%.py`.

To find what file types a repo's sessions actually touch, which helps pick the
filter:

```sql
WITH edits AS (
  SELECT m.session_id,
         COALESCE(json_extract(c.value, '$.state.input.path'),
                  json_extract(c.value, '$.state.input.filePath')) AS file
  FROM session_message m, json_each(m.data, '$.content') c
  WHERE m.type = 'assistant'
    AND json_extract(c.value, '$.type') = 'tool'
    AND json_extract(c.value, '$.name') IN ('edit', 'write')
)
SELECT e.file AS f, COUNT(*) c
FROM edits e JOIN session_v2 s ON s.id = e.session_id
WHERE s.directory = '/path/to/repo'
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
sqlite3 -readonly opencode.db < query.sql > raw.json
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

To pull the other side, take the `text` elements of an assistant message's
`$.content` rather than a user message's `$.text`. Useful for comparing an
agent's habits against Nic's, though see the warning below before computing any
rate.

```sql
SELECT m.session_id AS sid, datetime(m.time_created/1000,'unixepoch') AS mtime,
       json_extract(c.value, '$.text') AS text
FROM session_message m, json_each(m.data, '$.content') c
WHERE m.type = 'assistant'
  AND json_extract(c.value, '$.type') = 'text';
```

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
