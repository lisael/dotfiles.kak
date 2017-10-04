decl str fzf_result ""

def x11-fzf -docstring %{x11-fzf [<command>]: } -params .. %{
    set global fzf_result ""
    %sh{
        if [ -z "${kak_opt_termcmd}" ]; then
            echo "echo -color Error 'termcmd option is not set'"
            exit
        fi
        file=$(mktemp)
        echo echo -debug $file
        candidates=$(echo -e "${kak_buflist}" | tr ":" "\n" | sed 's|\:|:|g' )
        # echo -e "echo -debug ${candidates}"
        # [ -f .fasd ] && candidates="${candidates}\n$(_FASD_DATA=.fasd fasd -f -l -R)"
        candidates="${candidates}\n$(ag -g '')"
        # candidates="${candidates}\n$(fasd -f -l -R)"
        # candidates="${candidates}"
        echo -e "$candidates" | awk '!seen[$0]++' > $file
        # echo echo -debug setsid ${kak_opt_termcmd} "/bin/sh -c \"echo eval -client ${kak_client} edit \$(ag -g '' | fzf --no-sort -e -q '$@') | kak -p ${kak_session}\""
        setsid ${kak_opt_termcmd} "/bin/sh -c \"echo eval -client ${kak_client} $@ \$(cat '$file' | fzf --no-sort -e; rm $file) | kak -p ${kak_session}\""
    }
}

def x11-fzf-open %{
    x11-fzf x11-fzf-do-open
}

def -hidden x11-fzf-do-open -params 1 %{
    %sh{
        buffers=$(echo -e "${kak_buflist}" | tr ":" "\n" | sed 's|\:|:|g' )
        echo -e buffers | grep -e "^$1\$" && echo "buffer $1" || echo "edit $1"
    }
}

def x11-fzf-open-new %{
    x11-fzf x11-fzf-do-open-new
}

def -hidden x11-fzf-do-open-new -params 1 %{
    %sh{
        buffers=$(echo -e "${kak_buflist}" | tr ":" "\n" | sed 's|\:|:|g' )
        echo -e buffers | grep -e "^$1\$" && echo "x11-new buffer $1" || echo "x11-new edit $1"
    }
}

map global user o :x11-fzf-open<ret>
map global user n :x11-fzf-open-new<ret>

def x11-fzf-edit -docstring %{x11-fzf [<command>]: } -params .. %{
    %sh{
        if [ -z "${kak_opt_termcmd}" ]; then
            echo "echo -color Error 'termcmd option is not set'"
            exit
        fi
        # echo echo -debug setsid ${kak_opt_termcmd} "/bin/sh -c \"echo eval -client ${kak_client} edit \$(ag -g '' | fzf --no-sort -e -q '$@') | kak -p ${kak_session}\""
        setsid ${kak_opt_termcmd} "/bin/sh -c \"echo eval -client ${kak_client} edit \$(ag -g '' | fzf --no-sort -e -q '$@') | kak -p ${kak_session}\""
    }
}
