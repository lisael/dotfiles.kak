decl str pony_lintcmd "ponyc -p . --pass=expr"
decl str pony_package ""

def pony-lint -allow-override -docstring 'Parse the current buffer with a linter' %{
    %sh{
        dir=$(mktemp -d -t kak-lint.XXXXXXXX)
        mkfifo "$dir"/fifo
        # printf '%s\n' "eval -no-hooks write $dir/buf"

        printf '%s\n' "eval -draft %{
                  edit! -fifo $dir/fifo *lint-output*
                  set buffer filetype make
                  set buffer make_current_error_line 0
                  hook -group fifo buffer BufCloseFifo .* %{
                      nop %sh{ rm -r '$dir' }
                      rmhooks buffer fifo
                  }
              }"

        { # do the parsing in the background and when ready send to the session

        package="$kak_opt_pony_package"
        echo "echo -debug 'package = ${package}'" | kak -p "$kak_session"

        if [ "$kak_opt_pony_package" = "" ]; then
            grep -R "^actor Main" $( dirname $kak_buffile ) > /dev/null
            if [ $? -eq 0 ]; then
                package=$( dirname $kak_buffile )
            else
                package=$(echo "$kak_bufname" | cut -d/ -f1)
            fi
            echo "echo -debug 'found package = ${package}'" | kak -p "$kak_session"
        fi

        eval "$kak_opt_pony_lintcmd ${package}" 2>&1 > /dev/null | sort -t: -k2,2 -n | uniq | grep "$kak_buffile:[0-9]\+:[0-9]\+:" > "$dir"/stderr
        printf '%s\n' "eval -client $kak_client echo 'pony linting done'" | kak -p "$kak_session"

        # Flags for the gutter:
        #   line3|{red}:line11|{yellow}
        # Contextual error messages:
        #   l1,c1,err1
        #   ln,cn,err2
        awk -F: -v file="$kak_buffile" -v stamp="$kak_timestamp" '
            /^\S+:[0-9]+:[0-9]+:/ {
                flags = flags $2 "|{red}█:"
            }
            /\s+\S+:[0-9]+:[0-9]+:/ {
                flags = flags $2 "|{yellow}█:"
            }
            /:[0-9]+:[0-9]+:/ {
                errors = errors $2 "," $3 "," substr($4,2) ":"
                # fix case where $5 is not the last field because of extra :s in the message
                for (i=5; i<=NF; i++) errors = errors $i ":"
                errors = substr(errors, 1, length(errors)-1) "\n"
            }
            END {
                print "set \"buffer=" file "\" lint_flags  %{" stamp ":" substr(flags,  1, length(flags)-1)  "}"
                errors = substr(errors, 1, length(errors)-1)
                gsub("~", "\\~", errors)
                print "set \"buffer=" file "\" lint_errors %~" errors "~"
            }
        ' "$dir"/stderr | kak -p "$kak_session"

        #cat "$dir"/stderr > "$dir"/fifo
        eval "$kak_opt_pony_lintcmd ${package}" 2>&1 > /dev/null | sort -t: -k2,2 -n | uniq | grep "$kak_buffile:[0-9]\+:[0-9]\+:" > /tmp/kak_log
        cut -d: -f2- "$dir"/stderr | sed "s@^@$kak_bufname:@" > "$dir"/fifo

        } >/dev/null 2>&1 </dev/null &
    }
}

hook -group pony-lint global WinSetOption filetype=pony %{
    lint-enable
    pony-lint
}

hook -group pony-lint global WinSetOption filetype=(?!pony).* %{
    lint-disable
}

hook global WinSetOption filetype=(?!pony).* %{
    rmhooks window pony-lint
}

hook -group pony-lint global  BufWritePost .*\.pony %{
    pony-lint
}
