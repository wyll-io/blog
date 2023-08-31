---
title: "The origins of Docker (a deep dive into containers)"
date: 2023-08-01
tags: ["docker", "linux", "dev"]
author: "François ALLAIS"
draft: false
---

# How it was before Docker

## The chroot jails

Back in the days, when trying to "isolate" a process, we used `chroot`, which is a Unix operation that *changes* the apparent *root* directory of a running process and its children (chroot means *change root*).

Let's try a simple exercice to illustrate the way it works.

Start by creating a folder anywhere on your environment and add a simple test file into it :

```bash
mkdir /folder-chroot
echo "Hello World!" > /folder-chroot/hello-world
```

And then run `chroot` on this folder : `chroot /folder-chroot`

You should see this error : `chroot: failed to run command ‘/bin/bash’: No such file or directory`. This is because the new environment you created with chroot is missing bash interpreter.

Let's add it and try again : `mkdir /folder-chroot/bin && cp /bin/bash /folder-chroot/bin/ && chroot /folder-chroot`. Same error... This is because **bash** does not have its dependencies to run correctly.

Let's find the dependencies of bash with the `ldd` tool (ldd stands for *list dynamic dependencies*) :

```bash
ldd /bin/bash
	
linux-vdso.so.1 (0x00007ffc56ea2000)
libtinfo.so.6 => /lib/x86_64-linux-gnu/libtinfo.so.6 (0x00007fe3867ab000)
libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fe386400000)
/lib64/ld-linux-x86-64.so.2 (0x00007fe386955000)
```

Let's copy all these dependecies into the according directories !

```bash
mkdir -p /folder-chroot/lib/x86_64-linux-gnu
mkdir -p /folder-chroot/lib64
cp /lib/x86_64-linux-gnu/libtinfo.so.6 /folder-chroot/lib/x86_64-linux-gnu/
cp /lib/x86_64-linux-gnu/libc.so.6 /folder-chroot/lib/x86_64-linux-gnu/
cp /lib64/ld-linux-x86-64.so.2 /folder-chroot/lib64/
```

Now try to run chroot again, you should this, wouah !

```bash
bash-5.1#
```

But wait, try to run `ls`, you should again have an error.

```bash
bash-5.1# ls
bash: ls: command not found
```

We need to perform the same operation for `ls` by adding its dependencies. Don't forget to leave the chrooted environment with `exit`.

```bash
ldd /bin/ls

linux-vdso.so.1 (0x00007fffb7be3000)
libselinux.so.1 => /lib/x86_64-linux-gnu/libselinux.so.1 (0x00007f2a67e18000)
libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f2a67a00000)
libpcre2-8.so.0 => /lib/x86_64-linux-gnu/libpcre2-8.so.0 (0x00007f2a67d81000)
/lib64/ld-linux-x86-64.so.2 (0x00007f2a67e7f000)
```

In fact we only miss `libpcre2-8.so.0` and `libselinux.so.1`, so let's add them. And the `ls` binary of course.

```bash
cp /bin/ls /folder-chroot/bin/
cp /lib/x86_64-linux-gnu/libpcre2-8.so.0 /folder-chroot/lib/x86_64-linux-gnu/
cp /lib/x86_64-linux-gnu/libselinux.so.1 /folder-chroot/lib/x86_64-linux-gnu/
```

Now go back to the chrooted environement and try to run `ls`. It should work and you will also see your *hello-world* file. Run `pwd` as well to see where you are.

```bash
bash-5.1# ls
bin  lib  lib64  hello-world
bash-5.1# pwd
/
```

You just created your first chroot environment which is called a `chroot jail` ! :)

### What about security ?

We saw that we can create an environment that is called a jail where a process knows only the root directory that we create for it, but sadly this is not enough in terms of security. There is a way to escape from a chroot jail. This is why the official documentation of chroot says that it is not designed for security. If we take a look at the **section 2** of the chroot manual page with this command : `man 2 chroot`

> This call changes an ingredient in the pathname resolution process and does nothing else.  In particular, it is not intended to be used for any kind of security purpose, neither to fully  sandbox  a process  nor  to  restrict  filesystem system calls.  In the past, chroot() has been used by daemons to restrict themselves prior to passing paths supplied by untrusted users to system calls such as open(2).  However, if a folder is moved out of the chroot directory, an attacker can exploit that to get out of the chroot directory as well.  The easiest way to do that is to chdir(2) to the to-be-moved directory, wait for it to be moved out, then open a path like ../../../etc/passwd.


## A step forward with namespaces

We walked through the chroot and discovered that it can be useful for creating simple jails, but it is not suitable for security measures. This is why `namespaces` where created in 2008.


Let's try to create a namespace for `bash` with this command : `unshare --pid /bin/bash`.

You will get this error :

```bash
unshare --pid /bin/bash
bash: fork: Cannot allocate memory
```

It is because the [PID 1 exits](https://stackoverflow.com/questions/44666700/unshare-pid-bin-bash-fork-cannot-allocate-memory).

We need to add the `--fork` option in order to tell unshare to fork bash as a child process of `unshare` and give it the `PID 1` (aka the parent process). Let's try it :

```bash
unshare --pid --fork /bin/bash

ps
    PID TTY          TIME CMD
  10657 pts/1    00:00:00 sudo
  10658 pts/1    00:00:00 bash
  88930 pts/1    00:00:00 dbus-launch
 102254 pts/1    00:00:00 unshare
 102255 pts/1    00:00:00 bash
 102262 pts/1    00:00:00 ps
```

Ok it is better, but `bash` does not have the `PID 1`.. And we see some weird processes, that seems to come from the root environment. It is because the `/proc` mount point comes from the root namespace, we need to create a new one, and there is an option for that : `--mount-proc`. Let's try.

```bash
unshare --pid --fork --mount-proc /bin/bash
ps
    PID TTY          TIME CMD
      1 pts/1    00:00:00 bash
      8 pts/1    00:00:00 ps
```

Lovely ! :)  
We are now in an isolated `PID namespace`.

## Cherry on the cake with cgroups

```
NEXT:

Docker -> Docker Engine -> Containerd -> Runc
pivot_root()

```