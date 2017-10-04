echo -debug %val(client)
decl -hidden int last_master

set global last_master 0

def -docstring %{ide-new-master [<command>]: create a new kak client for the current session
The optional arguments will be passed as arguments to the new client} \
    -params .. \
    -command-completion \
    ide-new-master %{ %sh{
        if [ -z "${kak_opt_termcmd}" ]; then
           echo "echo -markup '{Error}termcmd option is not set'"
           exit
        fi
        kakoune_params="ide-init"
        if [ $# -ne 0 ]; then
            kakoune_params="-e '${kakoune_params};$@'"
        else
            kakoune_params="-e '${kakoune_params}'"
        fi
        setsid ${kak_opt_termcmd} "kak -c ${kak_session} ${kakoune_params}" < /dev/null > /dev/null 2>&1 &
}}

def ide-init %{ %sh{
    next=$(calc ${kak_opt_last_master} + 1)
    new_name=$(printf "master_${next}" | sed 's/\s//g')
    echo "set global last_master ${next}"
    echo "rename-client ${new_name}"
}}

