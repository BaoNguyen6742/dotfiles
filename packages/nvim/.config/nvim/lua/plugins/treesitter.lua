return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
        local treesitter = require("nvim-treesitter")
        treesitter.setup({ install_dir = vim.fn.stdpath("data") .. "/site" })

        local function enable_folds(buf, lang)
            if not lang or #vim.treesitter.query.get_files(lang, "folds") == 0 then
                return
            end

            for _, win in ipairs(vim.fn.win_findbuf(buf)) do
                local options = vim.wo[win][0]
                if options.foldmethod == "manual" then
                    options.foldexpr = "v:lua.vim.treesitter.foldexpr()"
                    options.foldlevel = 99 -- Create folds, but start with them open.
                    options.foldmethod = "expr"
                end
            end
        end

        local function enable(buf, lang)
            if not pcall(vim.treesitter.start, buf, lang) then
                return false
            end

            if lang == "ruby" then
                -- Ruby's built-in indentation still needs Vim syntax highlighting.
                vim.bo[buf].syntax = "ON"
            elseif #vim.treesitter.query.get_files(lang, "indents") > 0 then
                -- Vim's v:lua bridge requires this exact require syntax.
                vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end
            enable_folds(buf, lang)
            return true
        end

        local pending = {}
        local function install(languages)
            local requested = {}
            for _, lang in ipairs(languages) do
                pending[lang] = true
                requested[lang] = true
            end

            treesitter.install(languages):await(vim.schedule_wrap(function(err)
                for _, lang in ipairs(languages) do
                    pending[lang] = nil
                end
                if err then
                    vim.notify("Treesitter install failed: " .. tostring(err), vim.log.levels.ERROR)
                end

                -- Enable Treesitter features without reopening buffers.
                for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                    if vim.api.nvim_buf_is_loaded(buf) then
                        local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
                        if lang and requested[lang] then
                            enable(buf, lang)
                        end
                    end
                end
            end))
        end

        local group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true })
        vim.api.nvim_create_autocmd("BufWinEnter", {
            group = group,
            callback = function(ev)
                enable_folds(ev.buf, vim.treesitter.language.get_lang(vim.bo[ev.buf].filetype))
            end,
        })

        vim.api.nvim_create_autocmd("FileType", {
            group = group,
            callback = function(ev)
                local lang = vim.treesitter.language.get_lang(ev.match)
                if not lang or enable(ev.buf, lang) or pending[lang] then
                    return
                end

                local parser = require("nvim-treesitter.parsers")[lang]
                if parser and parser.tier ~= 4 then
                    install({ lang })
                end
            end,
        })

        install({
            "lua",
            "python",
            "vimdoc",
            "vim",
            "regex",
            "dockerfile",
            "toml",
            "json",
            "gitignore",
            "yaml",
            "make",
            "cmake",
            "markdown",
            "markdown_inline",
            "bash",
        })
    end,
}
