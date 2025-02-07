# notes.nvim

A simple Neovim plugin for managing and synchronizing notes.

## Features

- **Create Notes:** Easily create new notes with a specified filename or generate a default filename.
- **List Notes:** Quickly list notes within your notes directory using `fzf-lua`.
- **Search Notes:** Search the content of your notes using `fzf-lua`.
- **Git Synchronization:** Pull and push notes to a remote Git repository.

## Prerequisites

- Neovim (version 0.10 or higher)
- [fzf-lua](https://github.com/ibhagwan/fzf-lua) (required for listing and searching notes)
- Git (required for pulling and pushing notes)

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "aniaan/notes.nvim",
  opts = {
    notes_dir = "~/notes", -- Required:  Your notes directory
  },
  keys = {
    { "<leader>ns", ":NotesSearch<CR>", desc = "Search Notes" },
    { "<leader>nc", ":NotesCreate<CR>", desc = "Create Note" },
    { "<leader>nl", ":NotesList<CR>", desc = "List Notes" },
    { "<leader>npl", ":NotesPull<CR>", desc = "Pull Notes" },
    { "<leader>nph", ":NotesPush<CR>", desc = "Push Notes" },
  },
  dependencies = {
    "ibhagwan/fzf-lua", -- Required for listing and searching
  }
}
```

## Configuration

The plugin can be configured using the `opts` table in your `lazy.nvim` configuration.

```lua
opts = {
  notes_dir = "~/notes", -- Required: The directory where your notes are stored.
  default_extension = "md", -- Optional: The default file extension for new notes (default: "md").
}
```

- **`notes_dir` (required):** The absolute path to the directory where your notes are stored. This directory _must_ exist. The plugin will _not_ create it for you. Use `~` to refer to your home directory.
- **`default_extension` (optional):** The default file extension to use when creating new notes without a specified extension. Defaults to `"md"`.

## Usage

The plugin provides the following commands and keymaps (as defined in the example `lazy.nvim` configuration):

- **`<leader>ns` or `:NotesSearch`**: Search for notes within your `notes_dir` using `fzf-lua`.
- **`<leader>nc` or `:NotesCreate`**: Create a new note. You will be prompted for a filename. If you enter a filename without an extension, the `default_extension` will be appended. If you leave the filename blank, a default filename will be generated (e.g., `Untitled-1.md`).
- **`<leader>nl` or `:NotesList`**: List notes within your `notes_dir` using `fzf-lua`.
- **`<leader>npl` or `:NotesPull`**: Pull changes from the remote Git repository associated with your `notes_dir`. This performs a `git pull --rebase`.
- **`<leader>nph` or `:NotesPush`**: Push changes to the remote Git repository associated with your `notes_dir`. This performs a `git add .`, `git commit -m "sync notes"`, and `git push`.

**Creating Notes with Specific Modes:**

The `:NotesCreate` command accepts an optional argument to specify the window mode for opening the new note:

- `:NotesCreate edit`: Opens the note in the current window (default).
- `:NotesCreate split`: Opens the note in a horizontal split.
- `:NotesCreate vsplit`: Opens the note in a vertical split.
- `:NotesCreate tabedit`: Opens the note in a new tab.

Example: `:NotesCreate vsplit`

## Important Considerations

- **Git Repository:** The `NotesPull` and `NotesPush` commands assume that your `notes_dir` is a Git repository. You must initialize a Git repository in your `notes_dir` and configure a remote before using these commands.
- **fzf-lua:** The plugin relies heavily on `fzf-lua` for listing and searching notes. Ensure that `fzf-lua` is properly installed and configured.
- **Git Commit Message:** The `NotesPush` command uses a fixed commit message ("sync notes"). You may want to customize this by modifying the plugin code directly if needed.
- **Git Rebase:** The `NotesPull` command uses `git pull --rebase`. If a rebase fails, you will need to resolve the conflicts manually.

