# highlighters
hook global WinCreate .* %{
    addhl number_lines
    addhl show_matching
    # volatile-highlighters-enable
}

# colorscheme
colorscheme gruvbox

# key bindings
map global user b '<esc>:buffer ' -docstring "Select a buffer"
map global user p '!xsel -o<ret>' -docstring "Paste X selection"
map global user c '<esc><a-s>:comment-line<ret><a-h><a-m>' -docstring "Comment the current or selected lines"
map global user y '<a-|>xsel -i<ret>;' -docstring "Copy selection to X clipboard"
map global normal <backspace> 'i<backspace>'
map global insert <backspace> '<a-;>:insert-bs<ret>'
map global user g ":grep-selection<ret>"-docstring "Grep the selection or the word under the cursor"
map global user f '<a-i>w*n' -docstring "Search current word in buffer"
map global user e ":edit-from-file<ret>" -docstring "Edit a file, searching from buffer directory"
map global user n ":x11-new buffer-menu<ret>" -docstring %{Open a file in a new window, starting from buffer dir}
map global user E ":x11-fzf-edit<ret>"
map global user N ":x11-fzf-open-new<ret>"
map global user k ":buffer-menu<ret>" -docstring %{Buffers menu}
map global user 1 ":to-buffer<space>1<ret>"
map global user 2 ":to-buffer<space>2<ret>"
map global user 3 ":to-buffer<space>3<ret>"
map global user 4 ":to-buffer<space>4<ret>"
map global user 5 ":to-buffer<space>5<ret>"
map global user 6 ":to-buffer<space>6<ret>"
map global user 7 ":to-buffer<space>7<ret>"
map global user 8 ":to-buffer<space>8<ret>"
map global user 9 ":to-buffer<space>9<ret>"
map global user 0 ":to-buffer<space>0<ret>"




hook global InsertChar \t %{
    %sh{
        if [ "${kak_opt_filetype}" = "makefile" ]; then
            true
        else
            echo "exec -draft h@"
        fi
    }
}

def -params 1..1 to-buffer %{
    %sh{
        buffname=$(echo ${kak_buflist} | cut -d':' -f $1 )
        echo "exec :buffer<space>${buffname}<ret>"
    }
}

def -hidden buffer-menu %{
    %sh{
        selected=$(~/bin/kakfiles.sh ${kak_buflist} ${kak_client_env_PWD})
        if [ "${selected}" != "" ]; then
            echo "exec :edit<space>${selected}<ret>"
        fi
    }
}

def -hidden grep-selection %{
    %sh{
        if [ $(echo $kak_selection_desc | sed 's/,/\n/' | sort -u | wc -l ) == "1" ]; then
            echo "exec <a-i>w:grep<space><c-r>.<ret>"
        else
            echo "exec :grep<space>\"<c-r>.\"<ret>"
        fi
    }
}

def -hidden edit-from-file %{
    %sh{
        dn=$(dirname $kak_buffile)
        echo "exec :edit<space>$dn/"
    }
}

def -hidden new-from-file %{
    %sh{
        dn=$(dirname $kak_buffile)
        echo "exec :x11-new<space>edit<space>$dn/"
    }
}

def -hidden insert-bs %{
    try %{
        exec -draft <a-h><a-k>\A<space>+\Z<ret>
        %sh{
            width=$( expr $kak_opt_indentwidth - 1 )
	        echo "exec -draft h ${width} H <a-k>\A<space>+\Z<ret> d"
    	}
    } catch %{
        exec <backspace>
    }
}

# avoid <esc>
hook global InsertChar j %{ try %{
  exec -draft hH <a-k>jj<ret> d
  exec <esc>
}}

# indent lone closing parenthesis
hook global InsertChar "\)|\]|}" %{
    try %{
        exec -draft x <a-k>\A\s*\S\Z
        # exec -draft "hy<a-a>)<a-s><a-k>\A\(|\)\Z<ret>'<a-&>"
        exec -draft hy:indent-closing<space>%reg(")<ret>
    }
}

def -params 1..1 indent-closing %~
    %sh!
        case "$1" in
            ")")
                open='\('
                closing='\)'
                ;;
            "]")
                open='\['
                closing='\]'
                ;;
            "}")
                open='{'
                closing='}'
                ;;
        esac
        echo "exec -draft \"h<a-a>${1}<a-s><a-k>\A${open}|${closing}\Z<ret>'<a-&>\""
    !
~

# Option
# set global termcmd "xfce4-terminal -x sh -c"
# set global termcmd "xfce4-terminal -e "
set global tabstop     4
set global indentwidth 4
set global scrolloff 1,5
set global makecmd 'make --jobs=4'
set global grepcmd 'ag --nopager --follow --smart-case -R'

# use tab im completion menu
hook global InsertCompletionShow .* %{
    map window insert <tab> '<c-n>'
    map window insert <backtab> '<c-p>'
}

hook global InsertCompletionHide .* %{
    unmap window insert <tab> '<c-n>'
    unmap window insert <backtab> '<c-p>'
}

hook global BufSetOption filetype=(pony) %{
    #set buffer comment_line_chars '// '
    #set buffer comment_selection_chars '/*:*/'
    set buffer tabstop     2
    set buffer indentwidth 2
}

hook global BufSetOption filetype=(yaml) %{
    set buffer tabstop     2
    set buffer indentwidth 2
}

hook global BufSetOption filetype=(python) %{
    set buffer lintcmd     flake8
    lint-enable
}

hook -group python-lint global WinSetOption filetype=python %{
    lint-enable
    lint
}

hook -group python-lint global WinSetOption filetype=(?!python).* %{
    lint-disable
}

hook global WinSetOption filetype=(?!python).* %{
    rmhooks window python-lint
}

hook -group python-lint global  BufWritePost .*\.py %{
    lint
}

hook -group python-lint global NormalIdle .*\.py %{
    lint
}


hook global BufOpenFile (PKGBUILD|.*\.install) %{
    set buffer filetype sh
}

# audomatic creation of the directories
hook global BufWritePre .* %{ nop %sh{
    dir=$(dirname $kak_buffile)
    [ -d $dir ] || mkdir --parents $dir
}}


hook global BufOpenFile .* %{
    nop %sh{
        [ -f ${kak_buffile} ] || fasd -A "${kak_buffile}"
    }
}

hook global BufWritePost .* %{
    nop %sh{
        [ ! "$(readlink -e .)" = "$PWD" ] && [ -f .fasd ] && _FASD_DATA=.fasd fasd -A "${kak_buffile}"
        fasd -A "${kak_buffile}"
    }
}


def -docstring %{xsplit [<command>]: create a new kak client for the current session
The optional arguments will be passed as arguments to the new client} \
    -params .. \
    -command-completion \
    xsplit %{ %sh{
        if [ -z "${kak_opt_termcmd}" ]; then
           echo "echo -color Error 'termcmd option is not set'"
           exit
        fi
        if [ $# -ne 0 ]; then kakoune_params="-e '$@'"; fi
        xmonadctl incMaster
        setsid ${kak_opt_termcmd} "kak -c ${kak_session} ${kakoune_params}" < /dev/null > /dev/null 2>&1 &
        sleep 0.5
        echo "x11-focus"
}}

echo -debug %val(client)

%sh{
    if [ -f "./.local.kak" ]; then
        echo "source ./.local.kak"
    else
        echo "echo -debug no .local.kak found. To create:"
        echo "echo -debug edit .local.kak"
    fi
}
