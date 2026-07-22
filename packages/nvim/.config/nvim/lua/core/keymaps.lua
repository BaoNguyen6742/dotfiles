-- Set leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Disable the spacebar key's default behavior in Normal and Visual modes
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- For conciseness
local opts = { noremap = true, silent = true }

local function full_opts(extra)
    return vim.tbl_extend("force", opts, extra or {})
end

-- save file
vim.keymap.set("n", "<C-s>", "<cmd> w <CR>", full_opts { desc = "Save file" })

-- save file without auto-formatting
vim.keymap.set("n", "<leader>sn", "<cmd>noautocmd w <CR>", full_opts { desc = "Save without format" })

-- quit file
vim.keymap.set("n", "<C-q>", "<cmd> q <CR>", full_opts { desc = "Close a file" })

-- delete single character without copying into register
vim.keymap.set("n", "x", '"_x', full_opts { desc = "Delete single char no register" })

-- Vertical scroll and center
vim.keymap.set("n", "<C-d>", "<C-d>zz", full_opts { desc = "Scroll down" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", full_opts { desc = "Scroll up" })

-- Find and center
vim.keymap.set("n", "n", "nzzzv", full_opts { desc = "Find next" })
vim.keymap.set("n", "N", "Nzzzv", full_opts { desc = "Find previous" })

-- Resize with arrows
vim.keymap.set("n", "<Up>", ":resize -2<CR>", full_opts { desc = "Resize up" })
vim.keymap.set("n", "<Down>", ":resize +2<CR>", full_opts { desc = "Resize down" })
vim.keymap.set("n", "<Left>", ":vertical resize -2<CR>", full_opts { desc = "Resize left" })
vim.keymap.set("n", "<Right>", ":vertical resize +2<CR>", full_opts { desc = "Resize right" })

-- Buffers/Tabs
vim.keymap.set("n", "<Tab>", ":bnext<CR>", full_opts { desc = "Next tab" }) -- go to next tab
vim.keymap.set("n", "<S-Tab>", ":bprevious<CR>", full_opts { desc = "Previous tab" }) -- go to previous tab
vim.keymap.set("n", "<leader>tx", ":bnext | bdelete #<CR>", full_opts { desc = "CLose this tab" }) -- close tab
vim.keymap.set("n", "<leader>tn", "<cmd> enew <CR>", full_opts { desc = "New tab" }) -- new tab

-- Window management/Split
vim.keymap.set("n", "<leader>sv", "<C-w>v", full_opts { desc = "Splity vertically" }) -- split window vertically
vim.keymap.set("n", "<leader>sh", "<C-w>s", full_opts { desc = "Split horizontally" }) -- split window horizontally
vim.keymap.set("n", "<leader>se", "<C-w>=", full_opts { desc = "Split window with same size" }) -- make split windows equal width & height
vim.keymap.set("n", "<leader>sx", ":close<CR>", full_opts { desc = "Close split" }) -- close current split window

-- Navigate between splits
vim.keymap.set("n", "<C-k>", ":wincmd k<CR>", full_opts { desc = "Go split up" })
vim.keymap.set("n", "<C-j>", ":wincmd j<CR>", full_opts { desc = "Go split down" })
vim.keymap.set("n", "<C-h>", ":wincmd h<CR>", full_opts { desc = "Go split left" })
vim.keymap.set("n", "<C-l>", ":wincmd l<CR>", full_opts { desc = "Go split right" })

-- Unused, buffer kinda better than tab
-- -- Tabs
-- vim.keymap.set("n", "<leader>to", ":tabnew<CR>", opts) -- open new tab
-- vim.keymap.set("n", "<leader>tx", ":tabclose<CR>", opts) -- close current tab
-- vim.keymap.set("n", "<leader>tn", ":tabn<CR>", opts) --  go to next tab
-- vim.keymap.set("n", "<leader>tp", ":tabp<CR>", opts) --  go to previous tab

-- Toggle line wrapping
vim.keymap.set("n", "<A-z>", "<cmd>set wrap!<CR>", opts)

-- Stay in indent mode
vim.keymap.set("v", "<", "<gv", full_opts { desc = "Indent in" })
vim.keymap.set("v", ">", ">gv", full_opts { desc = "Indent out" })

-- Keep last yanked when pasting
vim.keymap.set("v", "p", '"_dP', opts)

-- Diagnostic keymaps
vim.keymap.set("n", "[d", function()
    vim.diagnostic.jump { count = -1, float = true }
end, { desc = "Go to previous diagnostic message" })

vim.keymap.set("n", "]d", function()
    vim.diagnostic.jump { count = 1, float = true }
end, { desc = "Go to next diagnostic message" })

vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })
