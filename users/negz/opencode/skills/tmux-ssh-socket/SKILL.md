---
name: tmux-ssh-socket
description: Fix SSH authentication failures in tmux sessions. Use when git push, git pull, git fetch, ssh, or scp fails with authentication, permission denied, or socket errors inside tmux. Also use when the user mentions SSH agent forwarding, SSH_AUTH_SOCK, or stale SSH sockets.
---

# Tmux SSH Socket Fix

## The Problem

When you reconnect to a tmux session, the `SSH_AUTH_SOCK` environment variable
inside tmux still points to the old socket path from the previous connection.
The old socket is dead, so any SSH operation (git push, git pull, ssh, scp) fails
with authentication errors.

## The Fix

```bash
eval $(tmux showenv -s SSH_AUTH_SOCK)
```

This reads the current `SSH_AUTH_SOCK` value from the tmux server environment
(which gets updated on each new SSH connection) and exports it into the current
shell.

## When to Apply

Run this fix when an SSH-dependent command fails inside tmux. Common symptoms:

- `git push` or `git pull` fails with "Permission denied (publickey)"
- `ssh` fails with "Could not open a connection to your authentication agent"
- Any "broken pipe" or "No such file or directory" error referencing an SSH socket

After running the fix, retry the failed command.
