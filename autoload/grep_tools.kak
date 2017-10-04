def -allow-override -params 1 -docstring %{Keep the given file extension in grep buffers} grep-filter %{
    %sh{
        echo "exec -draft %{%{%<a-s><a-K>^\S*.$1:<ret>d}}"
        echo "exec gg"
    }
}
