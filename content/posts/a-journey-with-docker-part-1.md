---
title: "A journey with Docker (Part 1)"
date: 2023-09-01
tags: ["docker", "linux", "dev"]
author: "François ALLAIS"
draft: true
---

# How it was before Docker

## The chroot jails

Back in the days, when trying to "isolate" a process, we used `chroot`, which is a Unix operation that *changes* the apparent *root* directory of a running process and its children (change root).

Let's try a simple exercice to illustrate the way it works.

Start by creating a folder anywhere on your environment and add a simple test file into it :

```
mkdir /folder-chroot
echo test > /folder-chroot/test.txt
```

And then run `chroot` on this folder : `chroot /folder-chroot`. You should see this error : `chroot: failed to run command ‘/bin/bash’: No such file or directory`. This is because the new environment you created with chroot is missing bash interpreter.

Let's add it and try again : `mkdir /folder-chroot/bin && cp /bin/bash /folder-chroot/bin/ && chroot /folder-chroot`. Same error... This is because **bash** does not have its dependencies to run correctly.

Let's find the dependencies of bash with the `ldd` tool (list dynamix dependencies) :

```
ldd /bin/bash
	linux-vdso.so.1 (0x00007ffc56ea2000)
	libtinfo.so.6 => /lib/x86_64-linux-gnu/libtinfo.so.6 (0x00007fe3867ab000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fe386400000)
	/lib64/ld-linux-x86-64.so.2 (0x00007fe386955000)
```

Let's copy all these dependecies into the according directories !

```
mkdir -p /folder-chroot/lib/x86_64-linux-gnu
mkdir -p /folder-chroot/lib64
cp /lib/x86_64-linux-gnu/libtinfo.so.6 /folder-chroot/lib/x86_64-linux-gnu/
cp /lib/x86_64-linux-gnu/libc.so.6 /folder-chroot/lib/x86_64-linux-gnu/
cp /lib64/ld-linux-x86-64.so.2 /folder-chroot/lib64/
```

Now try to run chroot again, you should this, wouah !

```
bash-5.1#
```

But wait, try to run `ls`, you should again have an error.

```
bash-5.1# ls
bash: ls: command not found
```

We need to perform the same operation for `ls` by adding its dependencies. Don't forget to leave the chrooted environment with `exit`.

```
ldd /bin/ls

linux-vdso.so.1 (0x00007fffb7be3000)
libselinux.so.1 => /lib/x86_64-linux-gnu/libselinux.so.1 (0x00007f2a67e18000)
libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f2a67a00000)
libpcre2-8.so.0 => /lib/x86_64-linux-gnu/libpcre2-8.so.0 (0x00007f2a67d81000)
/lib64/ld-linux-x86-64.so.2 (0x00007f2a67e7f000)
```

In fact we only miss `libpcre2-8.so.0` and `libselinux.so.1`, so let's add them. And the `ls` binary of course.

```
cp /bin/ls /folder-chroot/bin/
cp /lib/x86_64-linux-gnu/libpcre2-8.so.0 /folder-chroot/lib/x86_64-linux-gnu/
cp /lib/x86_64-linux-gnu/libselinux.so.1 /folder-chroot/lib/x86_64-linux-gnu/
```

Now go back to the chrooted environement and try to run `ls`. It should work and you should also see your test file. Run `pwd` as well to see where you are.

```
bash-5.1# ls
bin  lib  lib64  test.txt
bash-5.1# pwd
/
```

You just created your first chroot environment which is called a `chroot jail` ! :)

## Namespaces

https://devops.stackexchange.com/questions/2826/difference-between-chroot-and-docker
https://btholt.github.io/complete-intro-to-containers/chroot
https://en.wikipedia.org/wiki/Linux_namespaces
https://en.wikipedia.org/wiki/Chroot
https://web.archive.org/web/20160127150916/http://www.bpfh.net/simes/computing/chroot-break.html
https://en.wikipedia.org/wiki/LXC
