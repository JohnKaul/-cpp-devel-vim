" I found this vim script file on the KDE Tech Base website. The link
" is below this comment but I will also include the descrition given in
" case the website goes down later.
"
" -- Begin Quote --"{{{
"Vim
"
" You can find a vim script in kde-devel-vim.vim that helps you to keep
" the coding style correct. In addition to defaulting to the kdelibs
" coding style it will automatically use the correct style for Solid and
" kdepim code. If you want to add rules for other projects feel free to
" add them in the SetCppCodingStyle function.
"
" To use the script, include it in your ~/.vimrc like this:
"
" source /path/to/kde/sources/kdesdk/scripts/kde-devel-vim.vim
"
" Document started by Urs Wolfer. Some parts of this document have been
" adopted from the Qt Coding Style document posted by Zack Rusin on
" kde-core-devel.
" -- End Quote --"}}}
"
" LINK:  http://techbase.kde.org/Policies/Kdelibs_Coding_Style#Vim
"
" John Kaul
"
" BRIEF:"{{{
" This vim plugin will preform many "necessary"/"useful" things when
" programming in the C++ lanugage.
""}}}
" DESCRIPTION:"{{{
""}}}
" FEATURES:"{{{
" o  Automatic brace and parenthesis addition.
"       ~ Intelligence added to place braces on same line as if,while,do,etc.
" o  Automatic space between keyword and paren addition.
" o  Quick switching between header and impl file.
" o  Intelligent includes additions.
"       ~ EG: Automatic "#include <string.h>" statement when cursor is on
"             "std::string" statement.
" o  Ability to add "standard" (ment to be overridden for personal,project
"    stds) comment headers.
" o  Change and TODO log entry helpers.
" o  (un)comment line toggle
"       ~ works with visual selection as well.
" o  Intelligent directory searching to enable "out-of-source-building", like
"    in the use of CMAKE.
" o  Generic tab completion for braces, parenthesis and quotes.
"       ~ This feature is only meant for convinces, please use a mechanism
"         like "SnipMate" for better tab completion.
" o  Ability to align assignments in surrounding statements.
" o  Automatic tagfile write for better project source code navigation.
" o  Automatic 'path' setting for 'gf' command navigation.
""}}}
" EXAMPLES:"{{{
" When adding a WHILE--or IF, FOR, etc--statement, braces at the end of the line will be
" added automatically. A key-press will be denoted with a bracket.
"
"       while(1)[enter]
"  will become:
"       while ( 1 ) {
"
"       }
"
"       for(;;;)[enter]
"  will become:
"       for ( ;;; ) {
"
"       }
""}}}
" NOTES:"{{{
" To use this file, place it in your plugin directory or load on demand:
"       source /path/to/vimscripts/cpp-devel-vim.vim
"
" For CreateChangeLogEntry() : If you don't want to re-enter your
" Name/Email in each vim session then make sure to have the viminfo
" option enabled in your ~/.vimrc, with the '!' flag, enabling
" persistent storage of global variables. Something along the line of
" set   viminfo=%,!,'50,\"100,:100,n~/.viminfo should do the trick.
"
" To make use of the ,ll and ,lg shortcuts you need to have the files
" GPLHEADER and LGPLHEADER in your home directory. Their content will
" be copied as license header then.

" " If TagList is Loaded then get a funny statusline
" " Only works if kde-devel-vim.vim is loaded after taglist.
" " Droping this script in ~/.vim/plugin works fine
" if exists('loaded_taglist')
"     let Tlist_Process_File_Always=1
"     set statusline=%<%f:[\ %{Tlist_Get_Tag_Prototype_By_Line()}\ ]\ %h%m%r%=%-14.(%l,%c%V%)\ %P
" endif
"}}}
"------------------------------------------------------------------------------
" The following tgries to determine what OS the end-user is using.
" NOTE: Macs have a problem in that this (has(...)) doesn't work so I
"       added the `` OR 1'' which should be true if the host OS isn't
"       a Windows OS.
let s:MSWIN = has("win16") || has("win32")   || has("win64")    || has("win95")
let s:UNIX  = has("unix")  || has("macunix") || has("win32unix") || 1


"------------------------------------------------------------------------------
" Some `public' overrides for an enduser to change if they want.
let s:MakeProgram             = 'make'
let s:MakeCmdLineArgs         = ''
let s:MakefileName            = 'Makefile'

" `common' build directory names to search for; this will determine
" `projectRoot'. Much of this script uses `projectRoot' so this is
" these directories are essential to this scripts functionality.
"
" I imagine a drirectory structure like the following:
"       ProjectName
"             |
"             +-- bin
"             |
"             +-- doc
"             |
"             +-- src
"             |    |
"              ...
let s:BuildDirectoriesToSearch = [ 'bin',
                                 \ 'build',
                                 \ 'binary',
                                 \ 'Development',
                                 \ 'Debug',
                                 \ 'Release'
                                 \ ]

" --------------------------------------------------------------------
" SetCppCodingStyle()
" Sets the current style based functions, like textwidth, path, brace
" and paren settings. 
" --------------------------------------------------------------------
function! SetCppCodingStyle()                           "{{{
    " Don't include these in filename completions
    set suffixes+=.lo,.o,.moc,.la,.closure,.loT

    "--------------------------------------------------------------
    " Path Stuff
    exe "cd %:p:h"
    "the path for the file
    let g:FileLocation=fnamemodify(expand(getcwd()), ':p')

    let g:BinDirectory = s:Directory_Matcher(s:BuildDirectoriesToSearch, ['.;'])
    if g:BinDirectory != '.'
        if s:MSWIN
            let g:AssumedProjectRoot = g:BinDirectory . '..\'
        else
            let g:AssumedProjectRoot = g:BinDirectory . '../'
        endif
        " Search for the binary directory and assume it is at the project root.
        " This is to set the `path' variable so `gf' works.
        "
        autocmd BufWritePost *.c,*.cc,*.cpp,*.h,*.hpp call s:CtagsWrite([g:AssumedProjectRoot])

        let &tags = fnamemodify(findfile(g:AssumedProjectRoot . 'tags', ".;"), ':p')

        if !s:MSWIN
            " Do not include extra (Unix) paths when on windows.
            let s:TypicalUnixIncludeDirectories = '/usr/include,/usr/local/include,'
            let &path = s:TypicalUnixIncludeDirectories . g:AssumedProjectRoot . '**4/'
            " Allow `path' to search 4 levels deep.
        else
            let &path = g:AssumedProjectRoot . '**4\'
            " Allow `path' to search 4 levels deep.
        endif
    endif
    " End Path Stuff
    "--------------------------------------------------------------

    call s:CreateCommands()

    call s:INOREMappings()
    call s:NormalVisualMappings()
    call s:NormalMappings()
    call s:InsertMappings()
    call s:InsertAbbreviations()

    " call SmartParensOff()
    call SmartParensOn()
    " inoremap ( <C-R>=SpaceBetweenKeywordAndParens()<CR>

    let g:need_brace_on_next_line = '\<\(class\|namespace\|struct\)\>'
    let g:need_brace_on_same_line = '\<\(if\|else\|while\|switch\|do\|foreach\|forever\|enum\|for\|try\|catch\)\>'

    set sw=4
    set sts=4
    set et
    set tw=100
    set listchars=tab:?\ ,trail:?
    " mark 'misplaced' tab characters
    set list
    iab i i
    set incsearch
    " call AddQtSyntax()
    " call UpdateMocFiles()

    set efm=%f:%l:\ %m,In\ file\ included\ from\ %f:%l:,\^I\^Ifrom\ %f:%l%m
    " Set the error format for the Mingw compiler

    if &syntax == 'cmake'
        call SmartParensOff()
        set sw=3
        set ts=3
        set et
        set tw=0
        return
    endif
    if ( !exists("g:noautobrace") )
        call EnableSmartLineBreak()
    endif
endfunction "}}}

" --------------------------------------------------------------------
" s:INOREMappings()
" Insert mode mappings.
" --------------------------------------------------------------------
function! s:INOREMappings()                             "{{{
    " Insert tab character in whitespace-only lines, complete otherwise
    inoremap <Tab> <C-R>=SmartTab()<CR>

    " Remap <TAB> for smart completion on various characters...
    inoremap <silent> <TAB>   <C-R>=SmartComplete()<CR>

    "if !exists("DisableSmartParens")
        " Insert a space after ( or [ and before ] or ) unless preceded by a matching
        " paren/bracket or space or inside a string or comment. Comments are only
        " recognized as such if they start on the current line :-(
        inoremap ( <C-R>=SmartParens( '(' )<CR>
        inoremap [ <C-R>=SmartParens( '[' )<CR>
        inoremap ] <C-R>=SmartParens( ']', '[' )<CR>
        inoremap ) <C-R>=SmartParens( ')', '(' )<CR>
    "endif

    " Insert an #include statement for the current/last symbol
    inoremap <F5> <C-O>:call AddHeader()<CR>

    " Insert a forward declaration for the current/last symbol
    inoremap <S-F5> <C-O>:call AddForward()<CR>
endfunction "}}}

" --------------------------------------------------------------------
" s:NormalVisualMappings()
" Normal and visual mode mappings
" --------------------------------------------------------------------
function! s:NormalVisualMappings()                      "{{{
    " Toggle line comments on Ctrl+\
    map <C-Bslash> :call CommentLine()<LF>
endfunction     "}}}

" --------------------------------------------------------------------
" s:NormalMappings()
" Normal mode mappings
" --------------------------------------------------------------------
function! s:NormalMappings()                            "{{{
    " Switch between header and implementation files on ,h
    nmap <silent> ,h :call SwitchHeaderImpl()<CR>
    nmap <silent> ,p :call SwitchPrivateHeaderImpl()<CR>

    " Insert an include guard based on the file name on ,#
    nmap ,# :call IncludeGuard()<CR>

    " Insert license headers at the top of the file
    nmap ,lg :call LicenseHeader( "GPL" )<CR>
    nmap ,ll :call LicenseHeader( "LGPL" )<CR>
    nmap ,lm :call LicenseHeader( "MIT" )<CR>
    nmap ,lb :call LicenseHeader( "BSD" )<CR>

    " Call AlignAssignments() for the current block of code.
    nmap <silent>  ,=  :call AlignAssignments()<CR>
    nmap make :call Make()<CR>
endfunction     "}}}

" --------------------------------------------------------------------
"  s:InsertMappings()
"  Insert mode mappings
" --------------------------------------------------------------------
function! s:InsertMappings()                            "{{{
    " Project or standard C++/Java/PHP comment block
    imap <silent>  ///  <C-R>=CommentBlock(input("Enter comment: "), {'box':'-', 'width':73})<CR>
endfunction         "}}}

" --------------------------------------------------------------------
" s:InsertAbbreviations()
" Insert mode abbreviations
" --------------------------------------------------------------------
function! s:InsertAbbreviations()                       "{{{
    " Expand #i to #include <.h> or #include ".h". The latter is chosen
    " if the character typed after #i is a dquote
    " If the character is > #include <> is inserted (standard C++ headers w/o .h)
    iab #i <C-R>=SmartInclude()<CR>

    "" " Insert a stripped down CVS diff
    "" iab DIFF <Esc>:call RunDiff()<CR>
endfunction     "}}}

" --------------------------------------------------------------------
" s:CreateCommands()
" Creates the following commands:
"
"           :make       :       Overides built in make command
"           :MakeCtags  :       Attempts to create tags file in the
"                               project root folder.
" --------------------------------------------------------------------
function! s:CreateCommands()                            "{{{
    " ===========================================================================
    " Custom Commands
    " ===========================================================================

    "=============================================================================
    "~ W A R N I N G ~
    "=============================================================================
    "The following section is a command override for the make
    "command
    "-----------------------------------------------------------------------------
    :command! -nargs=0 Make :call Make()
    " Create a command for the Make() function.
    :cabbrev make <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'Make' : 'make')<CR>
    " Overirde the `make' command to use ours instead.  echohl
    " WarningMsg | echo "WARNING: 'make' command overridden to custom
    " 'Make()' function." | echohl None
    "-----------------------------------------------------------------------------

    if g:BinDirectory != '.'
        " Create a command for creating a tags file at the project root.
        :command! -nargs=0 MakeCtags :call s:CtagsWrite([g:AssumedProjectRoot])
    endif

endfunction     "}}}

" --------------------------------------------------------------------
" DisableSmartLineBreak()
" Disables insert mode mapping.
" --------------------------------------------------------------------
function! DisableSmartLineBreak()                       "{{{
    iunmap <CR>
    iuna else
endfunction "}}}

" --------------------------------------------------------------------
" EnableSmartLineBreak()
" Sets an insert mode mapping to call the function SmartLineBreak() 
" --------------------------------------------------------------------
function! EnableSmartLineBreak()                        "{{{
    if exists("*pumvisible")
        inoremap <CR> <C-R>=pumvisible() ? "\<lt>CR>" : "\<lt>ESC>:call SmartLineBreak()\<lt>CR>a\<lt>CR>"<CR>
    else
        inoremap <CR> <ESC>:call SmartLineBreak()<CR>a<CR>
    endif
    iab else <C-R>=SmartElse()<CR>
endfunction "}}}

" --------------------------------------------------------------------
" SmartElse()
" Adds an else on the same line as a bracket.
" --------------------------------------------------------------------
function! SmartElse()                                   "{{{
    let prefix = ''
    if strlen(g:need_brace_on_same_line) > 0 && 'else' =~ g:need_brace_on_same_line
        if getline('.') =~ '^\s*$'
            if getline(line('.') - 1) =~ '}$'
                let prefix = prefix . "\<ESC>kmMjdd`MA "
            elseif getline(line('.') - 1) =~ '}\s*$'
                let prefix = prefix . "\<ESC>kmMjdd`MA"
            endif
        endif
    endif
    return prefix . "else\<Right>"
endfunction "}}}

" --------------------------------------------------------------------
" s:CreateMatchLine()
" Finds the line in wich to place the matching brace/paren/bracket.
" --------------------------------------------------------------------
function! s:CreateMatchLine()                           "{{{
    let linenum = line( '.' )
    let current_line = getline( linenum )
    " don't do magic if the cursor isn't at the end of the line or if it's
    " inside a // comment
    if col( '.' ) != strlen( current_line ) || match( current_line, '//' ) >= 0
        return ''
    endif
    " remove whitespace at the end
    if match( current_line, '\s\+$' ) >= 0
        :execute ':s/\s*$//'
        " the following is needed if return '' is called
        :execute "normal $"
    endif
    let current_line = getline( linenum )
    " remove all /* */ comments
    let current_line = substitute( current_line, '/\*.\{-}\*/', '', 'g' )
    " remove all strings
    let current_line = substitute( current_line, "'[^']*'", '', 'g' )
    let current_line = substitute( current_line, '"\(\\"\|[^"]\)*"', '', 'g' )
    " remove all ( )
    while current_line =~ '(.*)'
        let current_line = substitute( current_line, '([^()]*)', '', 'g' )
    endwhile
    " prepend earlier lines until we find a ; or {
    while linenum > 1 && current_line !~ ';' && current_line !~ '{.\+$'
        let linenum = linenum - 1
        let prev_line = getline(linenum)
        if synIDattr(synID(linenum, 1, 1), "name") == 'cComment' "inside a /* */ comment at the beginning of the line
            if stridx(prev_line, '*/') == -1
                " next line please
                let prev_line = ''
            else
                " remove everything before */
                let prev_line = substitute(prev_line, '^.*\*/', '*/', '')
            endif
        endif
        " remove // comment
        let prev_line = substitute(prev_line, '//.*$', '', '' )
        " concatenate the lines with a space in between
        let current_line = prev_line.' '.current_line
        " remove all /* */ comments
        let current_line = substitute( current_line, '/\*.\{-}\*/', '', 'g' )
        " remove all strings
        let current_line = substitute( current_line, "'[^']*'", '', 'g' )
        let current_line = substitute( current_line, '"\(\\"\|[^"]\)*"', '', 'g' )
        " remove all ( )
        while current_line =~ '(.*)'
            let current_line = substitute( current_line, '([^()]*)', '', 'g' )
        endwhile
    endwhile
    " remove everything until the last ;
    let current_line = substitute( current_line, '^.*;', '', '' )
    " remove everything until the last { which is not at the end of the line
    let current_line = substitute( current_line, '^.*{\(.\+\)$', '\1', '' )
    " remove all [ ]
    while current_line =~ '\[.*\]'
        let current_line = substitute( current_line, '\[[^\[\]]*\]', '', 'g' )
    endwhile
    "" " if <CR> was pressed inside ( ), [ ] or /* */ don't add braces
    "" if current_line =~ '[(\[]' || current_line =~ '/\*'
    ""     return ''
    "" endif
    return current_line
endfunction "}}}

" --------------------------------------------------------------------
" AddClosingChar(curent_line, ch)
" Adds a closing char on the current line or the next depending on
" basic rules. 
"
"       current_line    :   The current line.
"       ch              :   A character to add.
" --------------------------------------------------------------------
function! AddClosingChar(current_line, ch)              "{{{
    if a:current_line =~ '\<enum\|class\|struct\>'
        :execute "normal o};\<ESC>k"
    elseif a:current_line =~ '\<while\|if\|else\|for\|switch\|do\>'
        :execute "normal o}\<ESC>k"
    elseif a:current_line =~ '\<namespace\>'
        let namespace = substitute( a:current_line, '^.*namespace\s\+', '', '' )
        let namespace = substitute( namespace, '\s.*$', '', '' )
        :execute "normal o} // namespace " . namespace . "\<ESC>k"
    else
        :execute "normal o" . a:ch ."\<ESC>k"
    endif
endfunction "}}}

" --------------------------------------------------------------------
" SmartLinebreak()
" Add the closing brace/parent/bracket.
" --------------------------------------------------------------------
function! SmartLineBreak()                              "{{{
    if synIDattr(synID(line("."), col("."), 1), "name") == 'cComment' "inside a /* */ comment at the point where the line break occurs
        return
    endif
    let match_line = s:CreateMatchLine()
    if match_line == ''
        return
    endif

    let match_position1 = -1
    let match_position2 = -1
    if strlen(g:need_brace_on_same_line) > 0
        let match_position1 = match(match_line, g:need_brace_on_same_line)
        if match_position1 > 0
            while strpart(match_line, match_position1 - 1, 1) == '#'
                let old_position = match_position1
                let match_position1 = match(match_line, g:need_brace_on_same_line, match_position1 + 1)
                if match_position1 == -1
                    if strpart(match_line, old_position, 2) == 'if'
                        :execute "normal o#endif\<ESC>k$"
                    endif
                    return
                endif
            endwhile
        endif
    endif
    if strlen(g:need_brace_on_next_line) > 0 && match_position1 == -1
        let match_position2 = match(match_line, g:need_brace_on_next_line)
        if match_position2 > 0
            while strpart(match_line, match_position2 - 1, 1) == '#'
                let old_position = match_position2
                let match_position2 = match(match_line, g:need_brace_on_same_line, match_position2 + 1)
                if match_position2 == -1
                    if strpart(match_line, old_position, 2) == 'if'
                        :execute "normal o#endif\<ESC>k$"
                    endif
                    return
                endif
            endwhile
        endif
    endif

    if match_position1 > -1
        if match_line =~ '}\s*else\>'
            " make sure else is on the same line as the closing brace
            if getline('.') =~ '^\s*else'
                if getline(line('.') - 1) =~ '}$'
                    :execute "normal kA \<ESC>J"
                elseif getline(line('.') - 1) =~ '}\s*$'
                    :execute "normal kJ"
                endif
            endif
        endif
        while getline('.') =~ '^\s*{$'
            " opening brace is on its own line: move it up
            :execute "normal kJ"
        endwhile
        if match_line =~ '{$'
            if getline('.') =~ '[^ ]{$'
                :execute ':s/{$/ {/'
            endif
        else
            :execute ':s/$/ {/'
        endif
        call AddClosingChar(match_line, '}')
    elseif getline('.') =~ '^\s*{$'
        call AddClosingChar('', '}')

    elseif getline('.') =~ '^\s*($'
        call AddClosingChar('', ')')

    elseif getline('.') =~ '^\s*[$'
        call AddClosingChar('', ']')

    elseif match_position2 > -1
        if match_line =~ '{$'
            :execute ':s/\s*{$//'
        endif
        :execute "normal o{"
        call AddClosingChar(match_line, '}')
    endif
    :execute "normal $"
endfunction "}}}

" --------------------------------------------------------------------
" SmartParensOn()
" Add some insert mode mappings upon command. These mappings are to
" create a mathcing Paren, and  Bracket
" --------------------------------------------------------------------
function! SmartParensOn()                               "{{{
    inoremap ( <C-R>=SmartParens( '(' )<CR>
    inoremap [ <C-R>=SmartParens( '[' )<CR>
    inoremap ] <C-R>=SmartParens( ']', '[' )<CR>
    inoremap ) <C-R>=SmartParens( ')', '(' )<CR>
endfunction "}}}

" --------------------------------------------------------------------
" SmartParensOff()
" Unmap some insert mode mappings upon command.
" --------------------------------------------------------------------
function! SmartParensOff()                              "{{{
    if strlen(mapcheck('[','i')) > 0
        iunmap (
        iunmap [
        iunmap ]
        iunmap )
    endif
endfunction "}}}

" --------------------------------------------------------------------
" SmartTab()
" --------------------------------------------------------------------
function! SmartTab()                                    "{{{
    let col = col('.') - 1
    if !col || getline('.')[col-1] !~ '\k'
        return "\<Tab>"
    else
        return "\<C-P>"
    endif
endfunction "}}}

" --------------------------------------------------------------------
" SmartParens(char, ...)
" Adds the space before the '(' after the keywords if/for/while/switch.
"
"       char            :   A Character
"       ...             :   
" --------------------------------------------------------------------
function! SmartParens( char, ... )                      "{{{
    if ! ( &syntax =~ '^\(c\|cpp\)$' )
        return a:char
    endif
    let s = strpart( getline( '.' ), 0, col( '.' ) - 1 )
    if s =~ '//'
        return a:char
    endif
    let s = substitute( s, '/\*\([^*]\|\*\@!/\)*\*/', '', 'g' )
    let s = substitute( s, "'[^']*'", '', 'g' )
    let s = substitute( s, '"\(\\"\|[^"]\)*"', '', 'g' )
    if s =~ "\\([\"']\\|/\\*\\)"
        return a:char
    endif
    " if a:0 > 0
    "     if strpart( getline( '.' ), col( '.' ) - 3, 2 ) == a:1 . ' '
    "         return "\<BS>" . a:char
    "     endif
    "     if strpart( getline( '.' ), col( '.' ) - 2, 1 ) == ' '
    "         return a:char
    "     endif
    "     return ' ' . a:char
    " endif
    if !exists("g:DisableSpaceBeforeParen")
        if a:char == '('
            if strpart( getline( '.' ), col( '.' ) - 3, 2 ) == 'if' ||
              \strpart( getline( '.' ), col( '.' ) - 3, 2 ) == 'do' ||
              \strpart( getline( '.' ), col( '.' ) - 4, 3 ) == 'for' ||
              \strpart( getline( '.' ), col( '.' ) - 5, 4 ) == 'case' ||
              \strpart( getline( '.' ), col( '.' ) - 6, 5 ) == 'while' ||
              \strpart( getline( '.' ), col( '.' ) - 7, 6 ) == 'switch'
                return ' ('
            endif
        endif
    endif
    return a:char 
    " . ' '
endfunction "}}}

" --------------------------------------------------------------------
" SpaceBetweenKeywordAndParens()
" --------------------------------------------------------------------
function! SpaceBetweenKeywordAndParens()                "{{{
    if ! ( &syntax =~ '^\(c\|cpp\)$' )
        return '('
    endif
    let s = strpart( getline( '.' ), 0, col( '.' ) - 1 )
    if s =~ '//'
        " text inside a comment
        return '('
    endif
    let s = substitute( s, '/\*\([^*]\|\*\@!/\)*\*/', ' ', 'g' )
    let s = substitute( s, "'[^']*'", ' ', 'g' )
    let s = substitute( s, '"\(\\"\|[^"]\)*"', ' ', 'g' )
    if s =~ "\\([\"']\\|/\\*\\)"
        " text inside a string
        return '('
    endif
    if a:0 > 0
        if strpart( getline( '.' ), col( '.' ) - 3, 2 ) == a:1 . ' '
            return "\<BS>" . a:char
        endif
        if strpart( getline( '.' ), col( '.' ) - 2, 1 ) == ' '
            return a:char
        endif
        return ' ' . a:char
    endif
    if strpart( getline( '.' ), col( '.' ) - 3, 2 ) == 'if' ||
        \strpart( getline( '.' ), col( '.' ) - 4, 3 ) == 'for' ||
        \strpart( getline( '.' ), col( '.' ) - 6, 5 ) == 'while' ||
        \strpart( getline( '.' ), col( '.' ) - 7, 6 ) == 'switch' ||
        \strpart( getline( '.' ), col( '.' ) - 8, 7 ) == 'foreach' ||
        \strpart( getline( '.' ), col( '.' ) - 8, 7 ) == 'forever'
        return ' ('
    endif
    return '('
endfunction "}}}

" --------------------------------------------------------------------
" SwitchHeaderInpl()
" --------------------------------------------------------------------
function! SwitchHeaderImpl()                            "{{{
    let privateheaders = '_p\.\([hH]\|hpp\|hxx\)$'
    let headers = '\.\([hH]\|hpp\|hxx\)$'
    let impl = '\.\([cC]\|cpp\|cc\|cxx\)$'
    let fn = expand( '%' )
    if fn =~ privateheaders
        let list = glob( substitute( fn, privateheaders, '.*', '' ) )
    elseif fn =~ headers
        let list = glob( substitute( fn, headers, '.*', '' ) )
    elseif fn =~ impl
        let list = glob( substitute( fn, impl, '.*', '' ) )
    endif
    while strlen( list ) > 0
        let file = substitute( list, "\n.*", '', '' )
        let list = substitute( list, "[^\n]*", '', '' )
        let list = substitute( list, "^\n", '', '' )
        if ( ( fn =~ headers || fn =~ privateheaders ) && file =~ impl ) || ( fn =~ impl && file =~ headers )
            call s:AskToSave()
            execute( "edit " . file )
            return
        endif
    endwhile
    if ( fn =~ headers )
        call s:AskToSave()
        if exists( "$implextension" )
            let file = substitute( fn, headers, '.' . $implextension, '' )
        else
            let file = substitute( fn, headers, '.cpp', '' )
        endif
        " check for modified state of current buffer and if modified ask:
        " save, discard, cancel
        execute( 'edit '.file )
        call append( 0, "#include \"".fn."\"" )
        call append( 2, "// vim: sw=4 sts=4 et tw=100" )
        execute( "set sw=4" )
        execute( "set sts=4" )
        execute( "set et" )
        execute( "set tw=100" )
    elseif fn =~ impl
        call s:AskToSave()
        let file = substitute( fn, impl, '.h', '' )
        execute( "edit ".file )
    endif
endfunction "}}}

" --------------------------------------------------------------------
" SwitchPrivateHeaderImpl()
" --------------------------------------------------------------------
function! SwitchPrivateHeaderImpl()                     "{{{
    let privateheaders = '_p\.\([hH]\|hpp\|hxx\)$'
    let headers = '\.\([hH]\|hpp\|hxx\)$'
    let impl = '\.\([cC]\|cpp\|cc\|cxx\)$'
    let fn = expand( '%' )
    " I added a beginning definition of LIST to see if I can get this function
    " working.
    let list = glob( substitute( fn, privateheaders, '.*', '') )
    if fn =~ privateheaders
        let list = glob( substitute( fn, privateheaders, '.*', '' ) )
    elseif fn =~ headers
        let list = glob( substitute( fn, headers, '_p.*', '' ) )
    elseif fn =~ impl
        let list = glob( substitute( fn, impl, '_p.*', '' ) )
    endif
    while strlen( list ) > 0
        let file = substitute( list, "\n.*", '', '' )
        let list = substitute( list, "[^\n]*", '', '' )
        let list = substitute( list, "^\n", '', '' )
        if ( fn =~ privateheaders && file =~ impl ) || ( fn =~ impl && file =~ privateheaders ) || ( fn =~ headers && file =~ privateheaders )
            call s:AskToSave()
            execute( "edit " . file )
            return
        endif
    endwhile
    if ( fn =~ privateheaders )
        call s:AskToSave()
        if exists( "$implextension" )
            let file = substitute( fn, privateheaders, '.' . $implextension, '' )
        else
            let file = substitute( fn, privateheaders, '.cpp', '' )
        endif
        " check for modified state of current buffer and if modified ask:
        " save, discard, cancel
        execute( 'edit '.file )
        call append( 0, "#include \"".fn."\"" )
        call append( 2, "// vim: sw=4 ts=4 noet" )
        execute( "set sw=4" )
        execute( "set ts=4" )
    elseif fn =~ impl
        let file = substitute( fn, impl, '_p.h', '' )
        call s:CreatePrivateHeader( file )
    elseif fn =~ headers
        let file = substitute( fn, headers, '_p.h', '' )
        call s:CreatePrivateHeader( file )
    endif
endfunction "}}}

" --------------------------------------------------------------------
" AskToSave()
" Prompts a user to save a file.
" --------------------------------------------------------------------
function! s:AskToSave()                                 "{{{
    if &modified
        let yesorno = input("Save changes before switching file? [Y/n]")
        if yesorno == 'y' || yesorno == '' || yesorno == 'Y'
            :execute 'w'
            return 1
        else
            return 0
        endif
    endif
    return 1
endfunction "}}}

" --------------------------------------------------------------------
" s:CreatePrivateHeader(privateHeader)
" Creates a private header file.
" --------------------------------------------------------------------
function! s:CreatePrivateHeader( privateHeader )          "{{{
    let privateheaders = '_p\.\([hH]\|hpp\|hxx\)$'
    let headers = '\.\([hH]\|hpp\|hxx\)$'
    let impl = '\.\([cC]\|cpp\|cc\|cxx\)$'
    let fn = expand( '%' )
    if fn =~ headers
        let className = s:ClassNameFromHeader()
    elseif fn =~ impl
        let className = s:ClassNameFromImpl()
    endif

    if s:AskToSave() && fn =~ headers
        :normal gg
        " check whether a Q_DECLARE_PRIVATE is needed
        let dp = search( '\(^\|\s\+\)Q_DECLARE_PRIVATE\s*(\s*'.className.'\s*)' )
        if dp == 0 "nothing found
            call search( '^\s*class\s\+\([A-Za-z0-9]\+_EXPORT\s\+\)\?[A-Za-z_]\+\s*\(:\s*[,\t A-Za-z_]\+\)\?\s*\n\?\s*{' )
            call search( '{' )
            let @c = className
            if getline(line('.')+1) =~ 'Q_OBJECT'
                :normal joQ_DECLARE_PRIVATE(c)
            "" else
            ""     :normal oQ_DECLARE_PRIVATE(c)
            endif
            :execute 'w'
        endif
    endif
    execute( "edit ".g:FileLocation.a:privateHeader )
    let privateClassName = className . 'Private'
    let header = substitute( a:privateHeader, privateheaders, '.h', '' )

    call IncludeGuard()
    " FIXME: find out what license to use
    " call LicenseHeader( "BSD" )
    let @h = header
    let @p = privateClassName
    let @c = className
    " :normal Gkko#include "h"class pQ_DECLARE_PUBLIC(c)protected:c *q_ptr;
    :normal Gkko#include "h"class p
endfunction "}}}

" --------------------------------------------------------------------
" s:ClassNameFromHeader()
" --------------------------------------------------------------------
function! s:ClassNameFromHeader()                       "{{{
    :normal gg
    call search( '^\s*class\s\+\([A-Za-z0-9]\+_EXPORT\s\+\)\?[A-Za-z_]\+\s*\(:\s*[,\t A-Za-z_]\+\)\?\s*\n\?\s*{' )
    "\zs and \ze mark start and end of the matching
    return matchstr( getline('.'), '\s\+\zs\w\+\ze\s*\(:\|{\|$\)' )
endfunction "}}}

" --------------------------------------------------------------------
" s:ClassNameFromImpl()
" --------------------------------------------------------------------
function! s:ClassNameFromImpl()                         "{{{
    :normal gg
    call search( '\s*\([A-Za-z_]\+\)::\1\s*(' )
    :normal "cye
    return @c
endfunction "}}}

" --------------------------------------------------------------------
" IncludeGuard()
" --------------------------------------------------------------------
function! IncludeGuard()                                "{{{
    let guard = toupper( substitute( expand( '%' ), '[\./]', '_', 'g' ) )
    call append( '^', '#define ' . guard )
    +
    call append( '^', '#ifndef ' . guard )
    call append( '$', '#endif // ' . guard )
    +
endfunction "}}}

" --------------------------------------------------------------------
" LicenseHeader(license)
" --------------------------------------------------------------------
function! LicenseHeader( license )                      "{{{
    " let filename = $HOME . "/" . a:license . "HEADER"
    " execute ":0r " . filename
"   call append( 0, system( "cat " . filename ) )
"
    let license = s:BSDLicense()
    call append( 0, license)
endfunction "}}}

" --------------------------------------------------------------------
" SmartInclude()
" --------------------------------------------------------------------
function! SmartInclude()                                "{{{
    let next = nr2char( getchar( 0 ) )
    if next == '"'
        return "#include \".h\"\<Left>\<Left>\<Left>"
    endif
    if next == '>'
        return "#include <>\<Left>"
    endif
    return "#include <.h>\<Left>\<Left>\<Left>"
endfunction "}}}

" --------------------------------------------------------------------
" s:MakeIdentHeader(ident)
"
" TODO: Rewite this fuction using dictionaries.
" --------------------------------------------------------------------
function! s:MapIdentHeader( ident )                     "{{{
    let header = tolower(substitute(a:ident, '::', '/', 'g')).'.h'
    if a:ident =~ 'Private$'
        let header = substitute(header, 'private', '_p', '')
    endif
    " always prefer the headers in the same directory
    let check = header
    let slash = 1
    while slash != -1
        if filereadable( check )
            return '"' . check . '"'
        endif
        let slash = match( check, '/' )
        let check = strpart( check, slash + 1 )
    endwhile
    let check = tolower(substitute(a:ident, '::', '/', 'g')).'_p.h'
    let slash = 1
    while slash != -1
        if filereadable(check)
            return '"' . check . '"'
        endif
        let slash = match(check, '/')
        let check = strpart(check, slash + 1)
    endwhile

    " Qt stuff
    if a:ident =~ '^Q[A-Z]'
""         " let's try to find the module
""         let module = ''
""         if $QTDIR != ''
""             if filereadable($QTDIR.'/include/QtCore/'.a:ident)
""                 let module = 'QtCore/'
""             elseif filereadable($QTDIR.'/include/QtGui/'.a:ident)
""                 let module = 'QtGui/'
""             elseif filereadable($QTDIR.'/include/Qt3Support/'.a:ident)
""                 let module = 'Qt3Support/'
""             elseif filereadable($QTDIR.'/include/QtAssistant/'.a:ident)
""                 let module = 'QtAssistant/'
""             elseif filereadable($QTDIR.'/include/QtDBus/'.a:ident)
""                 let module = 'QtDBus/'
""             elseif filereadable($QTDIR.'/include/QtDesigner/'.a:ident)
""                 let module = 'QtDesigner/'
""             elseif filereadable($QTDIR.'/include/QtNetwork/'.a:ident)
""                 let module = 'QtNetwork/'
""             elseif filereadable($QTDIR.'/include/QtOpenGL/'.a:ident)
""                 let module = 'QtOpenGL/'
""             elseif filereadable($QTDIR.'/include/QtSql/'.a:ident)
""                 let module = 'QtSql/'
""             elseif filereadable($QTDIR.'/include/QtSvg/'.a:ident)
""                 let module = 'QtSvg/'
""             elseif filereadable($QTDIR.'/include/QtTest/'.a:ident)
""                 let module = 'QtTest/'
""             elseif filereadable($QTDIR.'/include/QtUiTools/'.a:ident)
""                 let module = 'QtUiTools/'
""             elseif filereadable($QTDIR.'/include/QtXml/'.a:ident)
""                 let module = 'QtXml/'
""             endif
""         endif
""         return '<'.module.a:ident.'>'
""     elseif a:ident == 'qDebug' ||
""           \a:ident == 'qWarning' ||
""           \a:ident == 'qCritical' ||
""           \a:ident == 'qFatal'
""         return '<QtCore/QtDebug>'
""     elseif a:ident == 'Q_EXPORT_PLUGIN2'
""         return '<QtCore/QtPlugin>'
""     elseif a:ident =~ 'Q_DECLARE_INTERFACE'
""         return '<QtCore/QObject>'
""     elseif a:ident =~ '^QT_VERSION' ||
""           \a:ident =~ '^Q_\(W\|O\)S_' ||
""           \a:ident =~ '^Q_CC_' ||
""           \a:ident =~ '^Q_.*STRUCTOR_FUNCTION$' ||
""           \a:ident =~ '^qu\?int' ||
""           \a:ident =~ '^Q_.*_RESOURCE$' ||
""           \a:ident == 'qreal' ||
""           \a:ident == 'qAbs' ||
""           \a:ident == 'qRound' ||
""           \a:ident == 'qRound64' ||
""           \a:ident == 'qMin' ||
""           \a:ident == 'qMax' ||
""           \a:ident == 'qBound' ||
""           \a:ident == 'qVersion' ||
""           \a:ident == 'qSharedBuild' ||
""           \a:ident == 'Q_UNUSED' ||
""           \a:ident == 'Q_ASSERT' ||
""           \a:ident == 'qInstallMsgHandler' ||
""           \a:ident == 'Q_GLOBAL_STATIC' ||
""           \a:ident == 'Q_GLOBAL_STATIC_WITH_ARGS' ||
""           \a:ident == 'qFuzzyCompare' ||
""           \a:ident == 'qIsNull' ||
""           \a:ident == 'qSwap' ||
""           \a:ident =~ 'Q_DECLARE_\(FLAGS\|OPERATORS_FOR_FLAGS\|PRIVATE\|PUBLIC\)' ||
""           \a:ident == 'Q_D' ||
""           \a:ident == 'Q_Q' ||
""           \a:ident == 'Q_DISABLE_COPY' ||
""           \a:ident == 'qsrand' ||
""           \a:ident == 'qrand'
""         return '<QtCore/QtGlobal>'
""
""     " Phonon stuff
""     elseif a:ident =~ '^Phonon::[A-Z]'
""         if a:ident =~ '^Phonon::\(NoDisc\|Cd\|Dvd\|Vcd\|.\+MetaData\|.*State\|.*Category\|.\+Error\)'
""             return '<Phonon/Global>'
""         endif
""         return '<'.substitute(a:ident, '::', '/', 'g').'>'
""     endif
""
""     " KDE stuff
""     let kdeincdir = substitute(system('kde4-config --prefix'), '[\n\r]*', '', 'g').'/include/KDE/'
""     let classname = substitute(a:ident, '^.*:', '', '')
""     let pathfn = expand('%:p:h')
""     if filereadable(kdeincdir.classname) && !pathfn =~ 'kdelibs'
""         return '<'.classname.'>'
""     elseif filereadable(kdeincdir.'Phonon/'.classname)
""         return '<Phonon/'.classname.'>'
""     elseif filereadable(kdeincdir.'Solid/'.classname)
""         return '<Solid/'.classname.'>'
""     elseif filereadable(kdeincdir.'KIO/'.classname)
""         return '<KIO/'.classname.'>'
""     elseif filereadable(kdeincdir.'KParts/'.classname)
""         return '<KParts/'.classname.'>'
""     elseif a:ident == 'K_GLOBAL_STATIC'
""         return '<KGlobal>'
""     elseif a:ident == 'K_EXPORT_PLUGIN'
""         return '<KPluginLoader>'
""     elseif a:ident =~ 'K_PLUGIN_FACTORY'
""         return '<KPluginFactory>'
""     elseif a:ident == 'K\(Double\|Int\)\(NumInput\|SpinBox\)'
""         return '<knuminput.h>'
""     elseif a:ident == 'KSharedConfig'
""         return '<kconfig.h>'
""     elseif a:ident == 'KConfigGroup'
""         return '<kconfiggroup.h>'
""     elseif a:ident == 'KListViewItem'
""         return '<klistview.h>'
""     elseif a:ident =~ 'kd\(Debug\|Warning\|Error\|Fatal\|Backtrace\)'
""         return '<kdebug.h>'
""     elseif a:ident == 'kapp'
""         return '<kapplication.h>'
""     elseif a:ident == 'i18n' ||
""           \a:ident == 'I18N_NOOP'
""         return '<klocale.h>'
""     elseif a:ident == 'locate' ||
""           \a:ident == 'locateLocal'
""         return '<kstandarddirs.h>'
""     elseif a:ident =~ '\(Small\|Desktop\|Bar\|MainBar\|User\)Icon\(Set\)\?' ||
""           \a:ident == 'IconSize'
""         return '<kiconloader.h>'

    " aRts stuff
    elseif a:ident =~ '\arts_\(debug\|info\|warning\|fatal\)'
        return '<debug.h>'

    " Standard Library stuff
    elseif a:ident =~ '\(std::\)\?\(cout\|cerr\|endl\|iostream\|fstream\)'
        return '<iostream>'
    elseif a:ident =~ '\(std::\)\?\(string\)'
        return '<string.h>'
    elseif a:ident =~ '\(std::\)\?is\(alnum\|alpha\|ascii\|blank\|graph\|lower\|print\|punct\|space\|upper\|xdigit\)'
        return '<cctype>'
    elseif a:ident == 'printf'
        return '<cstdio>'
    endif

    " let standardLibrary = {
    "             \ 'std::cout'       :   'iostream',
    "             \ 'std::cerr'       :   'iostream',
    "             \ 'std::endl'       :   'iostream',
    "             \ 'std::fstream'    :   'iostream',
    "             \ 'std::string'     :   'string.h',
    "             \ 'isalnum'         :   'cctype',
    "             \ 'isalpha'         :   'cctype',
    "             \ 'isascii'         :   'cctype',
    "             \ 'isgraph'         :   'cctype',
    "             \ 'islower'         :   'cctype',
    "             \ 'isprint'         :   'cctype',
    "             \ 'ispunct'         :   'cctype',
    "             \ 'isspace'         :   'cctype',
    "             \ 'isupper'         :   'cctype',
    "             \ 'isxdigit'        :   'cctype',
    "             \ 'printf'          :   'cstdio',
    " }

    let check = header
    while 1
        if filereadable( check )
            return '"' . check . '"'
        endif
        let slash = match( check, '/' )
        if slash == -1
            return '<' . header . '>'
        endif
        let check = strpart( check, slash + 1 )
    endwhile
endfunction "}}}

" --------------------------------------------------------------------
" AddHeader()
" --------------------------------------------------------------------
" This is a rather dirty hack, but seems to work somehow :-) (malte)
function! AddHeader()                                   "{{{
    let s = getline( '.' )
    let i = col( '.' ) - 1
    while i > 0 && strpart( s, i, 1 ) !~ '[A-Za-z0-9_:]'
        let i = i - 1
    endwhile
    while i > 0 && strpart( s, i, 1 ) =~ '[A-Za-z0-9_:]'
        let i = i - 1
    endwhile
    let start = match( s, '[A-Za-z0-9_]\+\(::[A-Z][A-Za-z0-9_]*\)*', i )
    let end = matchend( s, '[A-Za-z0-9_]\+\(::[A-Z][A-Za-z0-9_]*\)*', i )
"    if end > col( '.' )
"        let end = matchend( s, '[A-Za-z0-9_]\+', i )
"    endif
    let ident = strpart( s, start, end - start )
    let header = s:MapIdentHeader(ident)
    let include = '#include '.header

    let line = 1
    let incomment = 0
    let appendpos = 0
    let codestart = 0
    let similarpos = 0
    let similarity = 0
    while line <= line( '$' )
        let s = getline( line )
        if incomment == 1
            let end = matchend( s, '\*/' )
            if end == -1
                let line = line + 1
                continue
            else
                let s = strpart( s, end )
                let incomment = 0
            endif
        endif
        let s = substitute( s, '//.*', '', '' )
        let s = substitute( s, '/\*\([^*]\|\*\@!/\)*\*/', '', 'g' )
        if s =~ '/\*'
            let incomment = 1
        elseif s =~ '^' . include
            break
        elseif s =~ '^#include' && s !~ '\.moc"'
            let appendpos = line
            if s =~ '^#include '.header[0:similarity+1]
                let similarpos = line
                let similarity = similarity + 1
                while s =~ '^#include '.header[0:similarity+1]
                    let similarity = similarity + 1
                endwhile
                if s[9:strlen(s)-2] > header[0:strlen(header)-2]
                    let similarpos = similarpos - 1
                    let similarity = 100 "this include belongs one line higher (assuming the order of includes already is alphabetically)
                endif
            endif
        elseif codestart == 0 && s !~ '^$'
            let codestart = line
        endif
        let line = line + 1
    endwhile
    if similarpos > 0
        let appendpos = similarpos
    endif
    if line == line( '$' ) + 1
        if appendpos == 0
            call append( codestart - 1, include )
            call append( codestart, '' )
        else
            call append( appendpos, include )
        endif
    endif
endfunction "}}}

" --------------------------------------------------------------------
" AddForward()
" --------------------------------------------------------------------
function! AddForward()                                  "{{{
    let s = getline( '.' )
    let i = col( '.' ) - 1
    while i > 0 && strpart( s, i, 1 ) !~ '[A-Za-z0-9_:]'
        let i = i - 1
    endwhile
    while i > 0 && strpart( s, i, 1 ) =~ '[A-Za-z0-9_:]'
        let i = i - 1
    endwhile
    let start = match( s, '[A-Za-z0-9_]\+\(::[A-Za-z0-9_]\+\)*', i )
    let end = matchend( s, '[A-Za-z0-9_]\+\(::[A-Za-z0-9_]\+\)*', i )
    if end > col( '.' )
        let end = matchend( s, '[A-Za-z0-9_]\+', i )
    endif
    let ident = strpart( s, start, end - start )
    let forward = 'class ' . ident . ';'

    let line = 1
    let incomment = 0
    let appendpos = 0
    let codestart = 0
    while line <= line( '$' )
        let s = getline( line )
        if incomment == 1
            let end = matchend( s, '\*/' )
            if end == -1
                let line = line + 1
                continue
            else
                let s = strpart( s, end )
                let incomment = 0
            endif
        endif
        let s = substitute( s, '//.*', '', '' )
        let s = substitute( s, '/\*\([^*]\|\*\@!/\)*\*/', '', 'g' )
        if s =~ '/\*'
            let incomment = 1
        elseif s =~ '^' . forward
            break
        elseif s =~ '^\s*class [A-za-z0-9_]\+;' || (s =~ '^#include' && s !~ '\.moc"')
            let appendpos = line
        elseif codestart == 0 && s !~ '^$'
            let codestart = line
        endif
        let line = line + 1
    endwhile
    if line == line( '$' ) + 1
        if appendpos == 0
            call append( codestart - 1, forward )
            call append( codestart, '' )
        else
            call append( appendpos, forward )
        endif
    endif
endfunction  "  }}}

" --------------------------------------------------------------------
" CreateChangeLogEntry()
" --------------------------------------------------------------------
function! CreateChangeLogEntry()                        "{{{
    let currentBuffer = expand( "%" )

    if exists( "g:EMAIL" )
        let mail = g:EMAIL
    elseif exists( "$EMAIL" )
        let mail = $EMAIL
    else
        let mail = inputdialog( "Enter Name/Email for Changelog entry: " )
    if mail == ""
        echo "Aborted ChangeLog edit..."
        return
    endif
    let g:EMAIL = mail
    endif

    if bufname( "ChangeLog" ) != "" && bufwinnr( bufname( "ChangeLog" ) ) != -1
    execute bufwinnr( bufname( "ChangeLog" ) ) . " wincmd w"
    else
        execute "split ChangeLog"
    endif

    let lastEntry = getline( nextnonblank( 1 ) )
    let newEntry = strftime("%Y-%m-%d") . "  " . mail

    if lastEntry != newEntry
        call append( 0, "" )
        call append( 0, "" )
        call append( 0, newEntry )
    endif

    " like emacs, prepend the current buffer name to the entry. but unlike
    " emacs I have no idea how to figure out the current function name :(
    " (Simon)
    if currentBuffer != ""
        let newLine = "\t* " . currentBuffer . ": "
    else
        let newLine = "\t* "
    endif

    call append( 2, newLine )

    execute "normal 3G$"
endfunction "}}}

" --------------------------------------------------------------------
" CreateTDODOEntry()
" --------------------------------------------------------------------
function! CreateTODOEntry()                             "{{{
    let currentBuffer = expand( "%" )

    if bufname( "TODO" ) != "" && bufwinnr( bufname( "TODO" ) ) != -1
    execute bufwinnr( bufname( "TODO" ) ) . " wincmd w"
    else
        execute "split TODO"
    endif

    let newLine = "* [ ] ( " . currentBuffer . " ): "
    call append( line('$'), newLine )
    execute "normal 3G$"
endfunction "}}}

" --------------------------------------------------------------------
" AddQtSyntax()
" --------------------------------------------------------------------
"" function! AddQtSyntax()                              "{{{
""     if expand( "<amatch>" ) == "cpp"
""         syn keyword qtKeywords     signals slots emit Q_SLOTS Q_SIGNALS
""         syn keyword qtMacros       Q_OBJECT Q_WIDGET Q_PROPERTY Q_ENUMS Q_OVERRIDE Q_CLASSINFO Q_SETS SIGNAL SLOT Q_DECLARE_PUBLIC Q_DECLARE_PRIVATE Q_D Q_Q Q_DISABLE_COPY Q_DECLARE_METATYPE Q_PRIVATE_SLOT Q_FLAGS Q_INTERFACES Q_DECLARE_INTERFACE Q_EXPORT_PLUGIN2 Q_GADGET Q_SCRIPTABLE Q_INVOKABLE METHOD Q_ARG Q_RETURN_ARG Q_GLOBAL_STATIC Q_GLOBAL_STATIC_WITH_ARGS
""         syn keyword qtCast         qt_cast qobject_cast qvariant_cast qstyleoption_cast qgraphicsitem_cast
""         syn keyword qtTypedef      uchar uint ushort ulong Q_INT8 Q_UINT8 Q_INT16 Q_UINT16 Q_INT32 Q_UINT32 Q_LONG Q_ULONG Q_INT64 Q_UINT64 Q_LLONG Q_ULLONG pchar puchar pcchar qint8 quint8 qint16 quint16 qint32 quint32 qint64 quint64 qlonglong qulonglong qreal
""         syn keyword kdeKeywords    k_dcop k_dcop_signals
""         syn keyword kdeMacros      K_DCOP ASYNC PHONON_ABSTRACTBASE PHONON_OBJECT PHONON_HEIR PHONON_ABSTRACTBASE_IMPL PHONON_OBJECT_IMPL PHONON_HEIR_IMPL PHONON_PRIVATECLASS PHONON_PRIVATEABSTRACTCLASS K_DECLARE_PRIVATE K_D K_EXPORT_PLUGIN K_PLUGIN_FACTORY K_PLUGIN_FACTORY_DEFINITION K_PLUGIN_FACTORY_DECLARATION K_GLOBAL_STATIC K_GLOBAL_STATIC_WITH_ARGS
""         syn keyword cRepeat        foreach
""         syn keyword cRepeat        forever
""
""         hi def link qtKeywords          Statement
""         hi def link qtMacros            Type
""         hi def link qtCast              Statement
""         hi def link qtTypedef           Type
""         hi def link kdeKeywords         Statement
""         hi def link kdeMacros           Type
""     endif
"" endfunction
""
"" function! UpdateMocFiles()
""     if &syntax == "cpp"
""         let i = 1
""         while i < 80
""             let s = getline( i )
""             if s =~ '^#include ".*\.moc"'
""                 let s = substitute( s, '.*"\(.*\)\.moc"', '\1.h', '' )
""                 if stridx( &complete, s ) == -1
""                     let &complete = &complete . ',k' . s
""                 endif
""                 break
""             endif
""             let i = i + 1
""         endwhile
""     endif
"" endfunction "}}}

" --------------------------------------------------------------------
" s:Directory_Marcher(directories, path)
"
"           directories     :       The directories to search for.
"           path            :       The path to sart looking from and
"                                   direction to search (up/down/both)
" --------------------------------------------------------------------
function! s:Directory_Matcher(directories, path)        "{{{
    let s:path = get(a:path, 'path', ['.;'])
    for $dir in a:directories
        if finddir($dir, s:path) != ""
            " return expand(finddir($dir, ".;"))
            return fnamemodify(expand(finddir($dir, ".;")), ':p')
        endif
    endfor
    return "."
endfunction "}}}

" --------------------------------------------------------------------
" AlignAssignments()
" This function will align the assignments for the statements in a code
" block.
"
" Example:
"     applicants_name = 'Luke'
"     mothers_maiden_name = 'Amidala'
"     closest_relative = 'sister'
"     fathers_occupation = 'Sith'
"
"     applicants_name     = 'Luke'
"     mothers_maiden_name = 'Amidala'
"     closest_relative    = 'sister'
"     fathers_occupation  = 'Sith'
"
" Code for this function found here:
" http://www.ibm.com/developerworks/linux/library/l-vim-script-2/index.html
"
" --------------------------------------------------------------------
function! AlignAssignments ()                           "{{{
    "   Align Assignments:

    " Patterns needed to locate assignment operators...
    let ASSIGN_OP   = '[-+*/%|&]\?=\@<!=[=~]\@!'
    let ASSIGN_LINE = '^\(.\{-}\)\s*\(' . ASSIGN_OP . '\)\(.*\)$'

    " Locate block of code to be considered (same indentation, no blanks)...
    let indent_pat = '^' . matchstr(getline('.'), '^\s*') . '\S'
    let firstline  = search('^\%('. indent_pat . '\)\@!','bnW') + 1
    let lastline   = search('^\%('. indent_pat . '\)\@!', 'nW') - 1
    if lastline < 0
        let lastline = line('$')
    endif

    " Decompose lines at assignment operators...
    let lines = []
    for linetext in getline(firstline, lastline)
        let fields = matchlist(linetext, ASSIGN_LINE)
        if len(fields)
            call add(lines, {'lval':fields[1], 'op':fields[2], 'rval':fields[3]})
        else
            call add(lines, {'text':linetext,  'op':''                         })
        endif
    endfor

    " Determine maximal lengths of lvalue and operator...
    let op_lines = filter(copy(lines),'!empty(v:val.op)')
    let max_lval = max( map(copy(op_lines), 'strlen(v:val.lval)') ) + 1
    let max_op   = max( map(copy(op_lines), 'strlen(v:val.op)'  ) )

    " Recompose lines with operators at the maximum length...
    let linenum = firstline
    for line in lines
        let newline = empty(line.op)
        \ ? line.text
        \ : printf("%-*s%*s%s", max_lval, line.lval, max_op, line.op, line.rval)
        call setline(linenum, newline)
        let linenum += 1
    endfor
endfunction     "}}}

" --------------------------------------------------------------------
" CommentLine()
" Adds a comment marker to the beginning of the line(s). this function
" works in visual mode as well -i.e. one can select several lines to
" comment out.
"
" Code for this function found here:
" http://www.ibm.com/developerworks/linux/library/l-vim-script-2/index.html
" --------------------------------------------------------------------
function! CommentLine()                                 "{{{
  if getline(".") =~ '//-x-   '
    let hls=@/
    s,^//-x-   ,,
    let @/=hls
  else
    let hls=@/
    s,^,//-x-   ,
    let @/=hls
  endif
endfunction "}}}

" --------------------------------------------------------------------
" CommentBlock(comment, opt)
"
"           comment     :
"           opt         :
" --------------------------------------------------------------------
function! CommentBlock(comment, opt)                    "{{{
    " Unpack optional arguments...
    let introducer = get(a:opt, 'intro', '//'                 )
    let box_char   = get(a:opt, 'box',   '*'                  )
    let width      = get(a:opt, 'width', strlen(a:comment) + 2) " Build the comment box and put the comment inside it...

    " get the current line
    let s:LineNumber = line('.')

    " Create the top ruler
    let s:TempString = introducer . repeat(box_char,width)
    call setline(s:LineNumber,s:TempString)

    " Fill in the comment block with text
    let s:LineNumber = s:LineNumber + 1
    let s:TempString = introducer . " " . a:comment
    call setline(s:LineNumber,s:TempString)

    " Blank line
    let s:LineNumber = s:LineNumber + 1
    let s:TempString = introducer
    call setline(s:LineNumber,s:TempString)

    "" let s:LineNumber = s:LineNumber + 1
    "" let s:TempString = introducer . " DESCRIPTION:"
    "" call setline(s:LineNumber,s:TempString)

    "" " Blank line
    "" let s:LineNumber = s:LineNumber + 1
    "" let s:TempString = introducer
    "" call setline(s:LineNumber,s:TempString)

    let s:LineNumber = s:LineNumber + 1
    let s:TempString = introducer . " ARGS:"
    call setline(s:LineNumber,s:TempString)

    " Create the bottom ruler
    let s:LineNumber = s:LineNumber + 1
    let s:TempString = introducer . repeat(box_char,width)
    call setline(s:LineNumber,s:TempString)
    return ""

    " execute "normal"
    " <HOME>x<Down><Down><Down><Down><Down><Insert><End>"

endfunction     "}}}

" --------------------------------------------------------------------
" SmartComplete()
" Implement simple smart completion magic. This function is not ment
" to be a replacement for a more robust tool like `SnipMate'; this
" tool is only ment to offer some help with braces.
"
" Code for this function found here:
" http://www.ibm.com/developerworks/linux/library/l-vim-script-2/index.html
" --------------------------------------------------------------------
function! SmartComplete()                               "{{{
    " Remember where we parked...
    let cursorpos = getpos('.')
    let cursorcol = cursorpos[2]
    let curr_line = getline('.')

    " Special subpattern to match only at cursor position...
    let curr_pos_pat = '\%' . cursorcol . 'c'

    " Tab as usual at the left margin...
    if curr_line =~ '^\s*' . curr_pos_pat
        return "\<TAB>"
    endif

    " How to restore the cursor position...
    let cursor_back = "\<C-O>:call setpos('.'," . string(cursorpos) . ")\<CR>"

    " If a matching smart completion has been specified, use that...
    for [left, right, completion, restore] in s:completions
        let pattern = left . curr_pos_pat . right
        if curr_line =~ pattern
            " Code around bug in setpos() when used at EOL...
            if cursorcol == strlen(curr_line)+1 && strlen(completion)==1
                let cursor_back = "\<LEFT>"
            endif

            " Return the completion...
            return completion . (restore ? cursor_back : "")
        endif
    endfor

    " If no contextual match and after an identifier, do keyword completion...
    if curr_line =~ '\k' . curr_pos_pat
        return "\<C-N>"

    " Otherwise, just be a <TAB>...
    else
        return "\<TAB>"
    endif
endfunction     "}}}

" Table of completion specifications (a list of lists)...
let s:completions = []
function! s:AddCompletion (left, right, completion, restore)
    " Function to add user-defined completions...
    call insert(s:completions, [a:left, a:right, a:completion, a:restore])
endfunction
let s:NONE = ""
" Table of completions...
"                    Left           Right       Complete with...            Restore
"                    =====          =======     ====================        =======
call s:AddCompletion(  '{',           s:NONE,     "}",                        1   )
call s:AddCompletion(  '{',           '}',        "\<CR>\<C-D>\<ESC>O",       0   )
call s:AddCompletion(  '\[ ',         s:NONE,     " ]",                       1   )
call s:AddCompletion(  '\[ ',         ' \]',       "\<CR>\<ESC>O\<TAB>",      0   )
call s:AddCompletion(  '( ',          s:NONE,     " )",                       1   )
call s:AddCompletion(  '( ',          ')',        "\<CR>\<ESC>O\<TAB>",       0   )
call s:AddCompletion(  '<',           s:NONE,     ">",                        1   )
call s:AddCompletion(  '<',           '>',        "\<CR>\<ESC>O\<TAB>",       0   )
call s:AddCompletion(  '"',           s:NONE,     '"',                        1   )
call s:AddCompletion(  '"',           '"',        "\\n",                      1   )
call s:AddCompletion(  "'",           s:NONE,     "'",                        1   )
call s:AddCompletion(  "'",           "'",        s:NONE,                     0   )
call s:AddCompletion(  "std::cout",   s:NONE,     " << std::endl;",           1   )

" --------------------------------------------------------------------
" MakeSetup()
" Locate the makefile and set the makeprog string.
" --------------------------------------------------------------------
function! MakeSetup()                                   "{{{
    if s:MSWIN
        let s:MakefileLocation = findfile(g:BinDirectory . s:MakefileName, ".;")
    else
        let s:MakefileLocation = findfile(g:BinDirectory . '/' . s:MakefileName, ".;")
    endif

    let s:MakeProgString = s:MakeProgram . ' -f "' . s:MakefileLocation . '" ' .s:MakeCmdLineArgs
    let &makeprg=s:MakeProgString
endfunction     "}}}

" --------------------------------------------------------------------
" Make()
" Curstom Make() command in which the following happen:
"   1. A CD to binary/makefile directory.
"   2. Issue the make command.
"   3. A CD back to end-users previous CD location.
" --------------------------------------------------------------------
function! Make()                                        "{{{
    call MakeSetup()

    " close the issues window
    exe	":cclose"
    " update : write source file if necessary
    exe	":update"
    if s:MakefileLocation == ''
        exe	":make " . s:MakeCmdLineArgs
    else
        exe "cd " . g:BinDirectory
        exe ":make"
        exe "cd " . g:FileLocation
    endif
    " open the issues window
    exe	":botright cwindow"
endfunction     "}}}

" --------------------------------------------------------------------
" s:CtagsWrite(path)
"           path        :   Path to start ctags from.
" --------------------------------------------------------------------
function! s:CtagsWrite( path )                          "{{{
    if g:AssumedProjectRoot
        let s:PathToRunCtagsFrom = get(a:path, 'path', ['.'])
        exe "cd " . s:PathToRunCtagsFrom
        let g:FileLocation=fnamemodify(expand(getcwd()), ':p')
        exe "!ctags -R --exclude=bin --exclude=build --exclude=binary --exclude=Release --exclude=Debug --exclude=CMakeFiles " . g:AssumedProjectRoot . '*'
        exe "cd " . g:FileLocation
    endif
endfunction "}}}


" ================================
" Autogroup settings.
" ================================
augroup CPPProgramming
    autocmd!
    autocmd BufNewFile,BufRead,BufEnter *.c,*.cc,*.cpp,*.h,*.hpp filetype indent on
    " automatic indenting is required for SmartLineBreak to work correctly
    autocmd BufNewFile,BufRead,BufEnter *.c,*.cc,*.cpp,*.h,*.hpp call SetCppCodingStyle()
    autocmd BufNewFile,BufRead,BufEnter *.c,*.cc,*.cpp call MakeSetup()
augroup END

" vim: sw=4 sts=4 et
"
