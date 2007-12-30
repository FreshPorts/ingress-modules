<p>
I moved to PCBSD a few weeks ago.  One of the first things I did to customize my
X.org environment concerned ssh-agent.  Until now, I used ~/.bash_profile to 
prompt me for my passphrase.  After I logged in at the console, I was prompted for
my ssh passphrase.  Now I use
<a href="http://www.freshports.org/security/openssh-askpass/">security/openssh-askpass</a>.
When combined with KDE and X.org , this is a good solution to this old problem.

<p>
To start, ssh-agent, I created ~/.kde/Autostart/ssh-add.sh, which contains:

<code class="screen">
#!/bin/sh
logger ~/.kde/Autostart/ssh-add.sh has been called
SSH_ASKPASS=/usr/local/bin/ssh-askpass
/usr/bin/ssh-add < /dev/null
</code>

<p>
<ul>
<li>The first line adds an entry to /var/log/messages, just to record the fact that
the script has been invoked.
<li>The second line sets an environment variable which ssh-add uses.  See man 1 ssh-add
for more information.
<li>The third line invokes ssh-add.  The redirection of input from /dev/null may be required
for your machine.  See the man page for more information.
</ul>

<p>
What is ~/.kde/env/ssh-agent.sh for ?

<p>
I also creates ~/.kde/shutdown/shutdown-ssh.sh, which contains:

<code class="screen">
#!/bin/sh
logger ~/.kde/shutdown/shutdown-ssh.sh has been called
/usr/bin/ssh-agent -k
</code>


Other customizations, done in previous installations of FreeBSD:

/boot/device.hints:
#
# ADDED BY Dan
#
# Mouse needs a device hint to work properly after resume.
hint.psm.0.flags="0x2000"

/boot/loader.conf:
acpi_ibm_load="YES"
