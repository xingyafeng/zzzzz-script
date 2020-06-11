########################################
#
#		alias
#
########################################
#!/bin/bash

# grep add color
alias grep='grep --color=auto'

# Trash
#alias rm='cp $@ ~/backup && rm $@'

# install
alias install='sudo apt-get install'

# repo
alias rdiff='repo manifest -r -o default.xml'

# exit conda
alias qconda='conda deactivate'
