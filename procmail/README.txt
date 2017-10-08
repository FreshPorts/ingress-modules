See maildrop instead of this directory. procmail was used from the
beginning, but a change to maildrop was made in October 2017.

In the old days, before running, you'd need to run create_dirs.sh then copy
these files. 

Today, with the port, you don't need to that.

cp dot.procmailrc ~/.procmailrc
cp dot.forward    ~/.forward

cd /usr/ports/mail/procmail
make install distclean