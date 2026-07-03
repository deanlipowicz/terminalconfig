" Obsidian VimRC configuration
" Compatible with obsidian-vimrc-support plugin

" Navigation
nmap <C-j> 5j
nmap <C-k> 5k
nmap <C-h> b
nmap <C-l> w
nmap <leader>w :w

" Window navigation
nmap <C-Left> <C-w>h
nmap <C-Right> <C-w>l
nmap <C-Up> <C-w>k
nmap <C-Down> <C-w>j

" Editor
nmap <leader>v <C-v>
imap jj <Esc>
nmap U <C-r>
nmap <leader><leader> <C-^>

" Obsidian-specific
nmap <leader>t :TogglePreview
nmap <leader>b :Backlinks
nmap <leader>g :GraphView
nmap <leader>s :Search
nmap <leader>q :QuickSwitcher
