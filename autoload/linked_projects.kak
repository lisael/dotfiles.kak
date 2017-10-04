decl str-list linked_projects

def -allow-override -params 1 grep-linked %{
    %sh{
        echo "echo -debug $kak_opt_linked_projects"
        if [[ $kak_opt_linked_projects ]]; then
            projects=$(sed 's/:/\n/g' <<< $kak_opt_linked_projects)
            if [ "$(wc -l <<< $projects)" = "1" ]; then
                base=${projects}
            else
                projects=$(printf ".\n%s" $projects)
                base=$(rofi -dmenu -sync -i -font "mono 6" -p 'grep into:' <<< $projects)
            fi
            if [[ ${base} ]]; then
                echo "echo -debug base is ${base}"
                base=$(sed "s|^~|${HOME}|" <<< $base )
                echo "echo -debug base is ${base}"
                echo "grep \"$1\" $base"
            fi
        else
            echo "No linked project"
        fi
    }
}
